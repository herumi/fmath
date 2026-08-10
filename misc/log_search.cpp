/*
	constant search tool for the AVX-512 logf kernel
	usage:
	  log_search.exe validate         ; check that the scalar model is bit-exact vs fmath_logf_v_avx512
	  log_search.exe report           ; error statistics of the current constants
	  log_search.exe search [--unpin] ; coordinate-descent search for better constants

	objective (lexicographic): max |ulp| (integer, vs correctly rounded logf),
	then #{|ulp|>=3}, #{|ulp|==2}, #{|ulp|==1}, then real-valued max |ulp|
	(fractional part recovered from a 1/256-ulp residual table).

	Requires ~11GB of RAM (reference tables over all positive normal floats)
	and an AVX-512 CPU (for validate). Build with -ffp-contract=off.
*/
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <cfenv>
#include <cinttypes>
#include <vector>
#include <array>
#include <algorithm>
#include <unistd.h>
#include <omp.h>
#include <fmath.h>
#include "log_kernel_model.hpp"

using namespace log_model;

const int EB_N = 254; // biased exponents 1..254 = all positive normals
const uint32_t MANT_N = 1u << 23;
const size_t TOTAL = (size_t)EB_N * MANT_N;

// monotone map from float bits to a signed integer; +0 and -0 both map to 0,
// so key differences count ulp steps uniformly across the zero crossing
inline int32_t ordKey(uint32_t u)
{
	int32_t m = (int32_t)(u & 0x7fffffff);
	return (u >> 31) ? -m : m;
}

inline float ulpAdd(float v, int k)
{
	return u2f(f2u(v) + (uint32_t)k);
}

inline bool sameBits(float a, float b) { return f2u(a) == f2u(b); }

/*
	mantissa space splits into segments of constant (table index, halved) :
	d = 0..7 unhalved, then 8..15 and finally 0 again with mant halved
*/
struct Seg {
	uint32_t mBegin, mEnd;
	uint8_t d, halved;
};

static std::vector<Seg> buildSegs(const Params& p)
{
	std::vector<Seg> segs;
	uint32_t start = 0;
	uint32_t curD = 99, curH = 99;
	for (uint32_t m = 0; m < MANT_N; m++) {
		float mant = u2f(0x3f800000 | m);
		uint32_t d = tblIdx(p, mant);
		uint32_t h = mant >= p.A2 ? 1 : 0;
		if (d != curD || h != curH) {
			if (m > 0) segs.push_back({start, m, (uint8_t)curD, (uint8_t)curH});
			start = m;
			curD = d;
			curH = h;
		}
	}
	segs.push_back({start, MANT_N, (uint8_t)curD, (uint8_t)curH});
	return segs;
}

// A0/A2 consistency: the halving threshold must coincide with the 7->8 index
// transition, giving exactly the segment pattern 0..7 unhalved, 8..15,0 halved
static void checkSegs(const std::vector<Seg>& segs)
{
	bool ok = segs.size() == 17;
	if (ok) {
		for (size_t i = 0; i < 17; i++) {
			ok &= segs[i].d == (i & 15);
			ok &= segs[i].halved == (i >= 8 ? 1 : 0);
		}
	}
	if (!ok) {
		fprintf(stderr, "A0/A2 inconsistency: unexpected segment structure (%zu segs)\n", segs.size());
		for (const Seg& s : segs) fprintf(stderr, "  m=[%u,%u) d=%d halved=%d\n", s.mBegin, s.mEnd, s.d, s.halved);
		exit(1);
	}
}

struct ErrStats {
	int32_t maxPos = 0, maxNeg = 0; // extreme signed integer ulp diffs
	uint64_t cnt1 = 0, cnt2 = 0, cntBig = 0; // |diff| == 1, == 2, >= 3
	float realMaxPos = 0, realMaxNeg = 0; // extremes of diff - resid/256
	void add(int32_t d, int8_t r)
	{
		uint32_t a = (uint32_t)(d < 0 ? -d : d);
		cnt1 += a == 1;
		cnt2 += a == 2;
		cntBig += a >= 3;
		if (d > maxPos) maxPos = d;
		if (d < maxNeg) maxNeg = d;
		float real = (float)d - (float)r * (1.0f/256);
		if (real > realMaxPos) realMaxPos = real;
		if (real < realMaxNeg) realMaxNeg = real;
	}
	void merge(const ErrStats& x)
	{
		if (x.maxPos > maxPos) maxPos = x.maxPos;
		if (x.maxNeg < maxNeg) maxNeg = x.maxNeg;
		cnt1 += x.cnt1;
		cnt2 += x.cnt2;
		cntBig += x.cntBig;
		if (x.realMaxPos > realMaxPos) realMaxPos = x.realMaxPos;
		if (x.realMaxNeg < realMaxNeg) realMaxNeg = x.realMaxNeg;
	}
	int32_t maxAbs() const { return maxPos > -maxNeg ? maxPos : -maxNeg; }
	float realMaxAbs() const { return realMaxPos > -realMaxNeg ? realMaxPos : -realMaxNeg; }
};

// lexicographic objective; < 0 means a is better
static int cmpStats(const ErrStats& a, const ErrStats& b)
{
	if (a.maxAbs() != b.maxAbs()) return a.maxAbs() < b.maxAbs() ? -1 : 1;
	if (a.cntBig != b.cntBig) return a.cntBig < b.cntBig ? -1 : 1;
	if (a.cnt2 != b.cnt2) return a.cnt2 < b.cnt2 ? -1 : 1;
	// the goal is minimal max error, so the real-valued max comes before the
	// 1-ulp count
	float ra = a.realMaxAbs(), rb = b.realMaxAbs();
	if (f2u(ra) != f2u(rb)) return ra < rb ? -1 : 1;
	if (a.cnt1 != b.cnt1) return a.cnt1 < b.cnt1 ? -1 : 1;
	return 0;
}

static void printStats(const char *tag, const ErrStats& s)
{
	uint64_t cnt0 = TOTAL - s.cnt1 - s.cnt2 - s.cntBig;
	printf("%s: ulp in [%d, +%d], real ulp in [-%.5f, +%.5f]\n"
		"  eq=%" PRIu64 " |1|=%" PRIu64 " |2|=%" PRIu64 " |>=3|=%" PRIu64 "\n",
		tag, s.maxNeg, s.maxPos, (double)-s.realMaxNeg, (double)s.realMaxPos,
		cnt0, s.cnt1, s.cnt2, s.cntBig);
}

// reference tables over all positive normal floats, indexed by (ei << 23) | m
// where ei = biasedExponent - 1
static std::vector<int32_t> g_refKey; // ordKey of correctly rounded logf(x)
static std::vector<int8_t> g_resid; // round(256 * (log(x) - ref) / ulp(ref))

static void buildRef()
{
	long pages = sysconf(_SC_PHYS_PAGES);
	long pageSize = sysconf(_SC_PAGE_SIZE);
	double gib = (double)pages * (double)pageSize / (1024.0*1024*1024);
	if (gib < 16) {
		fprintf(stderr, "not enough RAM (%.1f GiB): the reference tables need ~11 GiB\n", gib);
		exit(1);
	}
	double t0 = omp_get_wtime();
	g_refKey.resize(TOTAL);
	g_resid.resize(TOTAL);
	uint64_t nRecheck = 0;
	#pragma omp parallel for schedule(dynamic) reduction(+:nRecheck)
	for (int ei = 0; ei < EB_N; ei++) {
		for (uint32_t m = 0; m < MANT_N; m++) {
			float x = u2f(((uint32_t)(ei + 1) << 23) | m);
			double r = std::log((double)x);
			float f = (float)r;
			double fd = (double)f;
			double ulpUp = (double)std::nextafterf(f, INFINITY) - fd;
			double ulpDn = fd - (double)std::nextafterf(f, -INFINITY);
			// if r is close to a rounding boundary, redo in long double (80-bit)
			double dUp = std::fabs(0.5 * ulpUp - (r - fd));
			double dDn = std::fabs(0.5 * ulpDn + (r - fd));
			double bound = (r >= fd ? ulpUp : ulpDn) * 0x1p-20;
			if (dUp < bound || dDn < bound) {
				long double lr = logl((long double)x);
				f = (float)lr;
				fd = (double)f;
				ulpUp = (double)std::nextafterf(f, INFINITY) - fd;
				ulpDn = fd - (double)std::nextafterf(f, -INFINITY);
				r = (double)lr;
				nRecheck++;
			}
			size_t idx = ((size_t)ei << 23) | m;
			g_refKey[idx] = ordKey(f2u(f));
			double ulp = r >= fd ? ulpUp : ulpDn;
			long ri = std::lround((r - fd) * 256.0 / ulp);
			if (ri > 127) ri = 127;
			if (ri < -127) ri = -127;
			g_resid[idx] = (int8_t)ri;
		}
	}
	printf("buildRef: %.2f sec (%" PRIu64 " near-tie inputs recomputed with logl)\n", omp_get_wtime() - t0, nRecheck);
}

// per-mantissa precomputation: result = fma(t[m], poly[m], z(e, d(m)))
struct Precomp {
	std::vector<float> t, poly;
};

static void rebuildPrecomp(const Params& p, const std::vector<Seg>& segs, Precomp& pc)
{
	pc.t.resize(MANT_N);
	pc.poly.resize(MANT_N);
	#pragma omp parallel for schedule(dynamic)
	for (int si = 0; si < (int)segs.size(); si++) {
		const Seg& s = segs[si];
		float invs = p.tbl1[s.d];
		for (uint32_t m = s.mBegin; m < s.mEnd; m++) {
			float mant = u2f(0x3f800000 | m);
			if (s.halved) mant *= 0.5f;
			float t = std::fma(mant, invs, -1.0f);
			float poly = std::fma(std::fma(p.c4, t, p.c3), t, p.c2);
			pc.t[m] = t;
			pc.poly[m] = std::fma(poly, t, 1.0f);
		}
	}
}

static ErrStats evalAll(const Params& p, const std::vector<Seg>& segs, const Precomp& pc)
{
	ErrStats total;
	#pragma omp parallel
	{
		ErrStats local;
		#pragma omp for schedule(dynamic) nowait
		for (int ei = 0; ei < EB_N; ei++) {
			size_t base = (size_t)ei << 23;
			const int32_t *rk = g_refKey.data() + base;
			const int8_t *rs = g_resid.data() + base;
			for (const Seg& s : segs) {
				float expo = (float)(ei + 1 - 127 + s.halved);
				float z = std::fma(expo, p.log2f, p.tbl2[s.d]);
				for (uint32_t m = s.mBegin; m < s.mEnd; m++) {
					float res = std::fma(pc.t[m], pc.poly[m], z);
					local.add(ordKey(f2u(res)) - rk[m], rs[m]);
				}
			}
		}
		#pragma omp critical(mergeStats)
		total.merge(local);
	}
	return total;
}

// evaluate only the inputs whose table index is d, with tbl1[d]/tbl2[d]
// replaced by t1/t2; set par=false when already inside a parallel region
static ErrStats evalBin(const Params& p, const std::vector<Seg>& segs, int d, float t1, float t2, bool par)
{
	ErrStats total;
	for (const Seg& s : segs) {
		if (s.d != d) continue;
		uint32_t len = s.mEnd - s.mBegin;
		std::vector<float> tt(len), pp(len);
		for (uint32_t i = 0; i < len; i++) {
			float mant = u2f(0x3f800000 | (s.mBegin + i));
			if (s.halved) mant *= 0.5f;
			float t = std::fma(mant, t1, -1.0f);
			float poly = std::fma(std::fma(p.c4, t, p.c3), t, p.c2);
			tt[i] = t;
			pp[i] = std::fma(poly, t, 1.0f);
		}
		#pragma omp parallel if(par)
		{
			ErrStats local;
			#pragma omp for schedule(dynamic) nowait
			for (int ei = 0; ei < EB_N; ei++) {
				float expo = (float)(ei + 1 - 127 + s.halved);
				float z = std::fma(expo, p.log2f, t2);
				size_t base = ((size_t)ei << 23) + s.mBegin;
				const int32_t *rk = g_refKey.data() + base;
				const int8_t *rs = g_resid.data() + base;
				for (uint32_t i = 0; i < len; i++) {
					float res = std::fma(tt[i], pp[i], z);
					local.add(ordKey(f2u(res)) - rk[i], rs[i]);
				}
			}
			#pragma omp critical(mergeStats)
			total.merge(local);
		}
	}
	return total;
}

static std::array<ErrStats, 16> evalBins(const Params& p, const std::vector<Seg>& segs)
{
	std::array<ErrStats, 16> r;
	for (int d = 0; d < 16; d++) {
		r[d] = evalBin(p, segs, d, p.tbl1[d], p.tbl2[d], true);
	}
	return r;
}

static ErrStats mergeAll(const std::array<ErrStats, 16>& bins)
{
	ErrStats t;
	for (const ErrStats& b : bins) t.merge(b);
	return t;
}

/*
	one pass of per-bin table search: for each bin, try tbl1[d] +- K1 ulps,
	and for each candidate tbl1, tbl2 in round(-log(tbl1)) +- K2 ulps
*/
static bool tablePass(Params& p, const std::vector<Seg>& segs, std::array<ErrStats, 16>& binStats, int K1, int K2, bool unpin)
{
	bool improved = false;
	for (int d = unpin ? 0 : 1; d < 16; d++) {
		ErrStats others;
		for (int i = 0; i < 16; i++) {
			if (i != d) others.merge(binStats[i]);
		}
		struct Cand { float t1, t2; };
		std::vector<Cand> cands;
		for (int k1 = -K1; k1 <= K1; k1++) {
			float t1 = ulpAdd(p.tbl1[d], k1);
			float t2c = (float)-std::log((double)t1);
			for (int k2 = -K2; k2 <= K2; k2++) {
				Cand c = {t1, ulpAdd(t2c, k2)};
				if (sameBits(c.t1, p.tbl1[d]) && sameBits(c.t2, p.tbl2[d])) continue; // incumbent
				cands.push_back(c);
			}
		}
		ErrStats bestBin = binStats[d];
		ErrStats bestTotal = others;
		bestTotal.merge(bestBin);
		float bestT1 = p.tbl1[d], bestT2 = p.tbl2[d];
		long bestIdx = -1; // -1 = incumbent
		#pragma omp parallel for schedule(dynamic)
		for (long ci = 0; ci < (long)cands.size(); ci++) {
			ErrStats bs = evalBin(p, segs, d, cands[ci].t1, cands[ci].t2, false);
			ErrStats tot = others;
			tot.merge(bs);
			#pragma omp critical(pickBest)
			{
				int c = cmpStats(tot, bestTotal);
				// strictly better, or deterministic tie-break among candidates
				if (c < 0 || (c == 0 && bestIdx >= 0 && ci < bestIdx)) {
					bestTotal = tot;
					bestBin = bs;
					bestT1 = cands[ci].t1;
					bestT2 = cands[ci].t2;
					bestIdx = ci;
				}
			}
		}
		if (bestIdx >= 0) {
			printf("  bin %2d: tbl1 %+d ulp, tbl2 %a -> %a : ", d,
				(int)(f2u(bestT1) - f2u(p.tbl1[d])), (double)p.tbl2[d], (double)bestT2);
			p.tbl1[d] = bestT1;
			p.tbl2[d] = bestT2;
			binStats[d] = bestBin;
			printStats("new total", bestTotal);
			improved = true;
		}
	}
	return improved;
}

// cyclic coordinate descent on c4, c3, c2, each +- K ulps (full-range sweeps)
static bool polyPass(Params& p, const std::vector<Seg>& segs, Precomp& pc, std::array<ErrStats, 16>& binStats, int K)
{
	bool improved = false;
	float* coefs[3] = {&p.c4, &p.c3, &p.c2};
	const char *names[3] = {"c4", "c3", "c2"};
	for (int j = 0; j < 3; j++) {
		float orig = *coefs[j];
		ErrStats bestTotal = mergeAll(binStats);
		float bestV = orig;
		for (int k = -K; k <= K; k++) {
			if (k == 0) continue;
			*coefs[j] = ulpAdd(orig, k);
			rebuildPrecomp(p, segs, pc);
			ErrStats tot = evalAll(p, segs, pc);
			if (cmpStats(tot, bestTotal) < 0) {
				bestTotal = tot;
				bestV = *coefs[j];
			}
		}
		*coefs[j] = bestV;
		if (!sameBits(bestV, orig)) {
			printf("  %s: %a -> %a (%+d ulp) : ", names[j], (double)orig, (double)bestV, (int)(f2u(bestV) - f2u(orig)));
			printStats("new total", bestTotal);
			rebuildPrecomp(p, segs, pc);
			binStats = evalBins(p, segs);
			improved = true;
		}
	}
	rebuildPrecomp(p, segs, pc);
	return improved;
}

// print inputs achieving (nearly) the extreme real-valued ulp error
static void findWorst(const Params& p, const std::vector<Seg>& segs, const Precomp& pc, const ErrStats& s)
{
	float thr = s.realMaxAbs() * 0.99999f;
	int shown = 0;
	for (int ei = 0; ei < EB_N && shown < 8; ei++) {
		size_t base = (size_t)ei << 23;
		for (const Seg& seg : segs) {
			float expo = (float)(ei + 1 - 127 + seg.halved);
			float z = std::fma(expo, p.log2f, p.tbl2[seg.d]);
			for (uint32_t m = seg.mBegin; m < seg.mEnd && shown < 8; m++) {
				float res = std::fma(pc.t[m], pc.poly[m], z);
				int32_t d = ordKey(f2u(res)) - g_refKey[base + m];
				float real = (float)d - (float)g_resid[base + m] * (1.0f/256);
				if (std::fabs(real) >= thr) {
					float x = u2f(((uint32_t)(ei + 1) << 23) | m);
					printf("  worst: x=%a logf=%a err=%+.5f ulp (bin %d)\n", (double)x, (double)res, (double)real, seg.d);
					shown++;
				}
			}
		}
	}
}

static void printParams(FILE *f, const Params& p)
{
	fprintf(f, "log_coef (c2, c3, c4) for gen_fmath.py:348:\n");
	fprintf(f, "  \"%af, %af, %af\"\n", (double)p.c2, (double)p.c3, (double)p.c4);
	fprintf(f, "invs_table for gen_fmath.py:358:\n");
	for (int i = 0; i < 16; i++) {
		fprintf(f, "      %af,\n", (double)p.tbl1[i]);
	}
	bool tbl2Differs = false;
	fprintf(f, "tbl2 (explicit values):\n");
	for (int i = 0; i < 16; i++) {
		float derived = i == 0 ? 0.0f : (float)-std::log((double)p.tbl1[i]);
		int du = (int)(f2u(p.tbl2[i]) - f2u(derived));
		fprintf(f, "      %af,%s\n", (double)p.tbl2[i], du ? " # DIFFERS from round(-log(tbl1)) !" : "");
		if (du) tbl2Differs = true;
	}
	if (tbl2Differs) {
		fprintf(f, "NOTE: some tbl2 entries differ from round(-log(tbl1[i])).\n"
			"gen_fmath.py:377-379 derives tbl2 from tbl1; it must be changed to use the explicit list above.\n");
	}
}

// histogram vs libm logf (for comparison with the counts recorded in test/log_misc.cpp)
static void libmHist(const Params& p, const std::vector<Seg>& segs, const Precomp& pc)
{
	uint64_t h[7] = {}; // <=-3, -2, -1, 0, +1, +2, >=3
	#pragma omp parallel
	{
		uint64_t lh[7] = {};
		#pragma omp for schedule(dynamic) nowait
		for (int ei = 0; ei < EB_N; ei++) {
			for (const Seg& s : segs) {
				float expo = (float)(ei + 1 - 127 + s.halved);
				float z = std::fma(expo, p.log2f, p.tbl2[s.d]);
				for (uint32_t m = s.mBegin; m < s.mEnd; m++) {
					float x = u2f(((uint32_t)(ei + 1) << 23) | m);
					float res = std::fma(pc.t[m], pc.poly[m], z);
					int32_t d = ordKey(f2u(res)) - ordKey(f2u(std::log(x)));
					if (d < -3) d = -3;
					if (d > 3) d = 3;
					lh[d + 3]++;
				}
			}
		}
		#pragma omp critical(mergeHist)
		for (int j = 0; j < 7; j++) h[j] += lh[j];
	}
	printf("vs libm logf: <=-3:%" PRIu64 " -2:%" PRIu64 " -1:%" PRIu64 " 0:%" PRIu64
		" +1:%" PRIu64 " +2:%" PRIu64 " >=+3:%" PRIu64 "\n",
		h[0], h[1], h[2], h[3], h[4], h[5], h[6]);
}

static void report(const Params& p, const std::vector<Seg>& segs, const Precomp& pc, const char *tag)
{
	ErrStats s = evalAll(p, segs, pc);
	printStats(tag, s);
	findWorst(p, segs, pc, s);
	libmHist(p, segs, pc);
}

static int validate()
{
	if (fmath_logf_v != fmath_logf_v_avx512) {
		fprintf(stderr, "this CPU does not dispatch to the AVX-512 kernel; validate needs AVX-512\n");
		return 1;
	}
	Params p = currentParams();
	auto segs = buildSegs(p);
	checkSegs(segs);
	const uint32_t U0 = 0x00800000; // FLT_MIN
	const uint32_t BLK = 1u << 16;
	const long nBlk = (long)(TOTAL / BLK);
	double t0 = omp_get_wtime();
	uint64_t bad = 0;
	#pragma omp parallel reduction(+:bad)
	{
		std::vector<float> x(BLK), y(BLK);
		#pragma omp for schedule(dynamic)
		for (long b = 0; b < nBlk; b++) {
			uint32_t u0 = U0 + (uint32_t)b * BLK;
			for (uint32_t i = 0; i < BLK; i++) x[i] = u2f(u0 + i);
			fmath_logf_v_avx512(y.data(), x.data(), BLK);
			for (uint32_t i = 0; i < BLK; i++) {
				float m = logModel(p, x[i]);
				if (f2u(m) != f2u(y[i])) {
					if (bad == 0) {
						#pragma omp critical(printMismatch)
						fprintf(stderr, "mismatch: x=%a kernel=%a model=%a\n", (double)x[i], (double)y[i], (double)m);
					}
					bad++;
				}
			}
		}
	}
	if (bad) {
		printf("validate FAILED: %" PRIu64 " mismatches\n", bad);
		return 1;
	}
	printf("validate OK: model is bit-exact over all positive normal floats (%.2f sec)\n", omp_get_wtime() - t0);
	return 0;
}

static int search(bool unpin)
{
	Params p = currentParams();
	auto segs = buildSegs(p);
	checkSegs(segs);
	buildRef();
	Precomp pc;
	rebuildPrecomp(p, segs, pc);
	printf("--- initial constants ---\n");
	report(p, segs, pc, "initial");
	auto binStats = evalBins(p, segs);
	{
		// sanity: per-bin stats must add up to the full sweep
		ErrStats sum = mergeAll(binStats);
		ErrStats all = evalAll(p, segs, pc);
		if (cmpStats(sum, all) != 0 || sum.cnt1 != all.cnt1) {
			fprintf(stderr, "internal error: per-bin stats do not match full sweep\n");
			return 1;
		}
	}
	const int K1base = 16, K2base = 4, KP = 32;
	int K1 = K1base, K2 = K2base;
	double t0 = omp_get_wtime();
	for (int iter = 1; ; iter++) {
		printf("--- iteration %d (K1=%d K2=%d, %.1f sec) ---\n", iter, K1, K2, omp_get_wtime() - t0);
		bool imp = tablePass(p, segs, binStats, K1, K2, unpin);
		rebuildPrecomp(p, segs, pc);
		imp |= polyPass(p, segs, pc, binStats, KP);
		if (imp) {
			K1 = K1base;
			K2 = K2base;
		} else if (K1 < 64) {
			K1 *= 2;
			K2 *= 2;
			printf("no improvement; widening neighborhood\n");
		} else {
			printf("converged\n");
			break;
		}
	}
	printf("--- final constants (%.1f sec) ---\n", omp_get_wtime() - t0);
	report(p, segs, pc, "final");
	printParams(stdout, p);
	const char *outName = "log_search_result.txt";
	FILE *f = fopen(outName, "w");
	if (f) {
		printParams(f, p);
		fclose(f);
		printf("(saved to %s)\n", outName);
	}
	return 0;
}

int main(int argc, char *argv[])
{
	setvbuf(stdout, nullptr, _IOLBF, 0);
	if (fegetround() != FE_TONEAREST) {
		fprintf(stderr, "rounding mode is not round-to-nearest\n");
		return 1;
	}
	fmath_init();
	const char *cmd = argc > 1 ? argv[1] : "";
	bool unpin = false;
	for (int i = 2; i < argc; i++) {
		if (strcmp(argv[i], "--unpin") == 0) unpin = true;
	}
	if (strcmp(cmd, "validate") == 0) {
		return validate();
	}
	if (strcmp(cmd, "report") == 0) {
		Params p = currentParams();
		auto segs = buildSegs(p);
		checkSegs(segs);
		buildRef();
		Precomp pc;
		rebuildPrecomp(p, segs, pc);
		report(p, segs, pc, "current");
		return 0;
	}
	if (strcmp(cmd, "search") == 0) {
		return search(unpin);
	}
	fprintf(stderr, "usage: log_search.exe validate|report|search [--unpin]\n");
	return 1;
}
