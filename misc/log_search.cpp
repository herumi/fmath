/*
	constant search tool for the AVX-512/AVX2 logf kernels
	usage:
	  log_search.exe validate         ; check that the scalar model is bit-exact vs fmath_logf_v_avx512
	  log_search.exe report           ; error statistics of the current constants
	  log_search.exe search [--unpin] ; coordinate-descent search for better constants
	--tq selects the AVX-512 tq form, --avx2 the AVX2 kernel (8 bins, degree-5 poly)

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
	d = 0..tblN/2-1 unhalved, then tblN/2..tblN-1 and finally 0 again with
	mant halved
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

// A0/A2 consistency: the halving threshold must coincide with the index
// transition into the upper half, giving exactly the segment pattern
// 0..tblN/2-1 unhalved, tblN/2..tblN-1,0 halved
static bool checkSegsOk(const std::vector<Seg>& segs, int tblN)
{
	if (segs.size() != (size_t)tblN + 1) return false;
	for (int i = 0; i <= tblN; i++) {
		if (segs[i].d != (i & (tblN - 1))) return false;
		if (segs[i].halved != (i >= tblN/2 ? 1 : 0)) return false;
	}
	return true;
}

static void checkSegs(const std::vector<Seg>& segs, int tblN)
{
	if (!checkSegsOk(segs, tblN)) {
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

static void printStats(const char *tag, const ErrStats& s, uint64_t total = TOTAL)
{
	uint64_t cnt0 = total - s.cnt1 - s.cnt2 - s.cntBig;
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
			tPoly(p, mant, invs, pc.t[m], pc.poly[m]);
		}
	}
}

static ErrStats evalAll(const Params& p, const std::vector<Seg>& segs, const Precomp& pc, int eiLo = 0, int eiHi = EB_N)
{
	ErrStats total;
	#pragma omp parallel
	{
		ErrStats local;
		#pragma omp for schedule(dynamic) nowait
		for (int ei = eiLo; ei < eiHi; ei++) {
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
static ErrStats evalBin(const Params& p, const std::vector<Seg>& segs, int d, float t1, float t2, bool par, int eiLo = 0, int eiHi = EB_N)
{
	ErrStats total;
	for (const Seg& s : segs) {
		if (s.d != d) continue;
		uint32_t len = s.mEnd - s.mBegin;
		std::vector<float> tt(len), pp(len);
		for (uint32_t i = 0; i < len; i++) {
			float mant = u2f(0x3f800000 | (s.mBegin + i));
			if (s.halved) mant *= 0.5f;
			tPoly(p, mant, t1, tt[i], pp[i]);
		}
		#pragma omp parallel if(par)
		{
			ErrStats local;
			#pragma omp for schedule(dynamic) nowait
			for (int ei = eiLo; ei < eiHi; ei++) {
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

static std::array<ErrStats, 16> evalBins(const Params& p, const std::vector<Seg>& segs, int eiLo = 0, int eiHi = EB_N)
{
	std::array<ErrStats, 16> r;
	for (int d = 0; d < p.tblN; d++) {
		r[d] = evalBin(p, segs, d, p.tbl1[d], p.tbl2[d], true, eiLo, eiHi);
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
static bool tablePass(Params& p, const std::vector<Seg>& segs, std::array<ErrStats, 16>& binStats, int K1, int K2, bool unpin, int eiLo = 0, int eiHi = EB_N, bool verbose = true)
{
	bool improved = false;
	for (int d = unpin ? 0 : 1; d < p.tblN; d++) {
		ErrStats others;
		for (int i = 0; i < p.tblN; i++) {
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
			ErrStats bs = evalBin(p, segs, d, cands[ci].t1, cands[ci].t2, false, eiLo, eiHi);
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
			if (verbose) {
				printf("  bin %2d: tbl1 %+d ulp, tbl2 %a -> %a : ", d,
					(int)(f2u(bestT1) - f2u(p.tbl1[d])), (double)p.tbl2[d], (double)bestT2);
			}
			p.tbl1[d] = bestT1;
			p.tbl2[d] = bestT2;
			binStats[d] = bestBin;
			if (verbose) printStats("new total", bestTotal);
			improved = true;
		}
	}
	return improved;
}

// cyclic coordinate descent on the coefficients, each +- K*step ulps
// (step > 1 gives a coarse sweep for far-from-optimal seeds)
static bool polyPass(Params& p, const std::vector<Seg>& segs, Precomp& pc, std::array<ErrStats, 16>& binStats, int K, int eiLo = 0, int eiHi = EB_N, bool verbose = true, int step = 1)
{
	bool improved = false;
	float* coefs[4] = {&p.c5, &p.c4, &p.c3, &p.c2};
	const char *names[4] = {"c5", "c4", "c3", "c2"};
	int j0 = p.coefN == 4 ? 0 : 1;
	for (int j = j0; j < 4; j++) {
		float orig = *coefs[j];
		ErrStats bestTotal = mergeAll(binStats);
		float bestV = orig;
		for (int k = -K; k <= K; k++) {
			if (k == 0) continue;
			*coefs[j] = ulpAdd(orig, k * step);
			rebuildPrecomp(p, segs, pc);
			ErrStats tot = evalAll(p, segs, pc, eiLo, eiHi);
			if (cmpStats(tot, bestTotal) < 0) {
				bestTotal = tot;
				bestV = *coefs[j];
			}
		}
		*coefs[j] = bestV;
		if (!sameBits(bestV, orig)) {
			if (verbose) {
				printf("  %s: %a -> %a (%+d ulp) : ", names[j], (double)orig, (double)bestV, (int)(f2u(bestV) - f2u(orig)));
				printStats("new total", bestTotal);
			}
			rebuildPrecomp(p, segs, pc);
			binStats = evalBins(p, segs, eiLo, eiHi);
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
	fprintf(f, "form = %s\n", p.avx2 ? "avx2" : p.tq ? "tq" : "poly");
	if (p.avx2) {
		fprintf(f, "log2_A..D for gen_fmath.py (LogGenAVX2.data):\n");
		fprintf(f, "  log2_A = %af\n  log2_B = %af\n  log2_C = %af\n  log2_D = %af\n",
			(double)p.c2, (double)p.c3, (double)p.c4, (double)p.c5);
		fprintf(f, "invs_table (invs_tableAVX2_L3) for gen_fmath.py:\n");
	} else {
		fprintf(f, "log_A0 = %af, log_A2 = %af (A2 must be derived from A0)\n", (double)p.A0, (double)p.A2);
		fprintf(f, "log_coef (c2, c3, c4) for gen_fmath.py:\n");
		fprintf(f, "  \"%af, %af, %af\"\n", (double)p.c2, (double)p.c3, (double)p.c4);
		fprintf(f, "invs_table for gen_fmath.py:\n");
	}
	for (int i = 0; i < p.tblN; i++) {
		fprintf(f, "      %af,\n", (double)p.tbl1[i]);
	}
	bool tbl2Differs = false;
	fprintf(f, "tbl2 (explicit values):\n");
	for (int i = 0; i < p.tblN; i++) {
		float derived = i == 0 ? 0.0f : (float)-std::log((double)p.tbl1[i]);
		int du = (int)(f2u(p.tbl2[i]) - f2u(derived));
		fprintf(f, "      %af,%s\n", (double)p.tbl2[i], du ? " # DIFFERS from round(-log(tbl1)) !" : "");
		if (du) tbl2Differs = true;
	}
	if (tbl2Differs) {
		fprintf(f, "NOTE: some tbl2 entries differ from round(-log(tbl1[i])).\n"
			"gen_fmath.py derives tbl2 from tbl1; it must be changed to use the explicit list above.\n");
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

static ErrStats descend(Params& p, const std::vector<Seg>& segs, bool unpin, int maxIter, int eiLo, int eiHi, bool verbose);

// A2 is not free: it must equal the mant value where the index crosses 7->8.
// Returns false if the candidate A0 gives no clean crossing or d(1.0) != 0.
static bool deriveA2(Params& p)
{
	if (tblIdx(p, 1.0f) != 0) return false;
	uint32_t prev = 0;
	for (uint32_t m = 1; m < MANT_N; m++) {
		float mant = u2f(0x3f800000 | m);
		uint32_t d = tblIdx(p, mant);
		if (d == 8 && prev == 7) {
			p.A2 = mant;
			return true;
		}
		prev = d;
	}
	return false;
}

static void binRanges(const std::vector<Seg>& segs, double lo[16], double hi[16])
{
	for (int d = 0; d < 16; d++) {
		lo[d] = 100;
		hi[d] = 0;
	}
	for (const Seg& s : segs) {
		double scale = s.halved ? 0.5 : 1.0;
		lo[s.d] = std::min(lo[s.d], (double)u2f(0x3f800000 | s.mBegin) * scale);
		hi[s.d] = std::max(hi[s.d], (double)u2f(0x3f800000 | (s.mEnd - 1)) * scale);
	}
}

/*
	seed tables for new bin boundaries by transplanting the reference solution's
	relative (log-space) position of 1/tbl1 within its bin onto the candidate's
	bin ranges. The optimal 1/tbl1 is systematically off-center (about 0.5% left
	of the bin center, tens of thousands of float ulps), so a naive 1/geomean
	seed is unreachable for the +-16..64 ulp descent steps.
*/
static void seedTables(Params& p, const std::vector<Seg>& segs, const Params& ref, const std::vector<Seg>& refSegs)
{
	double lo[16], hi[16], rlo[16], rhi[16];
	binRanges(segs, lo, hi);
	binRanges(refSegs, rlo, rhi);
	p.tbl1[0] = 1.0f;
	p.tbl2[0] = 0.0f;
	for (int d = 1; d < 16; d++) {
		double c = 1.0 / (double)ref.tbl1[d];
		double frac = std::log(c / rlo[d]) / std::log(rhi[d] / rlo[d]);
		double v = lo[d] * std::pow(hi[d] / lo[d], frac);
		p.tbl1[d] = (float)(1.0 / v);
		p.tbl2[d] = (float)-std::log((double)p.tbl1[d]);
	}
}

// per-exponent max real ulp error, to find which exponents determine the max
static std::vector<float> perExpMax(const Params& p, const std::vector<Seg>& segs, const Precomp& pc)
{
	std::vector<float> mx(EB_N);
	#pragma omp parallel for schedule(dynamic)
	for (int ei = 0; ei < EB_N; ei++) {
		ErrStats local;
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
		mx[ei] = local.realMaxAbs();
	}
	return mx;
}

// proxy window = hull of exponents whose per-exponent max is within 0.15 ulp
// of the global max, expanded by 1 on each side
static void chooseWindow(const std::vector<float>& mx, int& lo, int& hi)
{
	float g = *std::max_element(mx.begin(), mx.end());
	lo = EB_N;
	hi = 0;
	for (int ei = 0; ei < EB_N; ei++) {
		if (mx[ei] >= g - 0.15f) {
			lo = std::min(lo, ei);
			hi = std::max(hi, ei + 1);
		}
	}
	lo = std::max(0, lo - 1);
	hi = std::min(EB_N, hi + 1);
}

static int perExp(const Params& p)
{
	auto segs = buildSegs(p);
	checkSegs(segs, p.tblN);
	buildRef();
	Precomp pc;
	rebuildPrecomp(p, segs, pc);
	std::vector<float> mx = perExpMax(p, segs, pc);
	for (int ei = 0; ei < EB_N; ei++) {
		printf("e=%+4d %.5f%s", ei + 1 - 127, (double)mx[ei], (ei % 8 == 7 || ei == EB_N - 1) ? "\n" : "  ");
	}
	int wLo, wHi;
	chooseWindow(mx, wLo, wHi);
	printf("proxy window: biased exponent [%d, %d) = e in [%+d, %+d), %d exponents\n",
		wLo + 1, wHi + 1, wLo + 1 - 127, wHi + 1 - 127, wHi - wLo);
	return 0;
}

static int searchA0()
{
	Params cur = currentParams();
	auto curSegs = buildSegs(cur);
	checkSegs(curSegs, cur.tblN);
	buildRef();

	int wLo, wHi;
	{
		Precomp pc;
		rebuildPrecomp(cur, curSegs, pc);
		std::vector<float> mx = perExpMax(cur, curSegs, pc);
		chooseWindow(mx, wLo, wHi);
	}
	printf("proxy window: e in [%+d, %+d)\n", wLo + 1 - 127, wHi + 1 - 127);

	struct CandA {
		Params p;
		std::vector<Seg> segs;
		ErrStats st;
	};
	std::vector<CandA> cands;

	// stage 1: coarse scan of A0 over its whole valid interval;
	// re-seeded tables + current poly + one short table pass on the window
	double t0 = omp_get_wtime();
	const double A0LO = 0.9690, A0HI = 1.0080;
	const int NA = 200;
	for (int i = 0; i <= NA + 1; i++) {
		CandA c;
		c.p = cur;
		if (i <= NA) {
			c.p.A0 = (float)(A0LO + (A0HI - A0LO) * i / NA);
			if (!deriveA2(c.p)) continue;
			c.segs = buildSegs(c.p);
			if (!checkSegsOk(c.segs, c.p.tblN)) continue;
			seedTables(c.p, c.segs, cur, curSegs);
		} else {
			c.segs = curSegs; // the incumbent, with its already-searched tables
		}
		auto binStats = evalBins(c.p, c.segs, wLo, wHi);
		tablePass(c.p, c.segs, binStats, 8, 2, false, wLo, wHi, false);
		c.st = mergeAll(binStats);
		cands.push_back(std::move(c));
	}
	std::sort(cands.begin(), cands.end(), [](const CandA& a, const CandA& b) { return cmpStats(a.st, b.st) < 0; });
	printf("--- stage 1: %zu candidates scanned (%.1f sec), top 10 ---\n", cands.size(), omp_get_wtime() - t0);
	for (size_t i = 0; i < cands.size() && i < 10; i++) {
		printf("  A0=%a realMax=[-%.5f, +%.5f]\n", (double)cands[i].p.A0,
			(double)-cands[i].st.realMaxNeg, (double)cands[i].st.realMaxPos);
	}

	// stage 2: window descent on the top 10
	if (cands.size() > 10) cands.resize(10);
	for (CandA& c : cands) {
		c.st = descend(c.p, c.segs, false, 8, wLo, wHi, false);
	}
	std::sort(cands.begin(), cands.end(), [](const CandA& a, const CandA& b) { return cmpStats(a.st, b.st) < 0; });
	printf("--- stage 2: window descent done (%.1f sec), top 3 ---\n", omp_get_wtime() - t0);
	for (size_t i = 0; i < cands.size() && i < 3; i++) {
		printf("  A0=%a realMax=[-%.5f, +%.5f]\n", (double)cands[i].p.A0,
			(double)-cands[i].st.realMaxNeg, (double)cands[i].st.realMaxPos);
	}

	// stage 3: full-domain descent on the top 3, compare with the incumbent
	if (cands.size() > 3) cands.resize(3);
	for (size_t i = 0; i < cands.size(); i++) {
		CandA& c = cands[i];
		printf("--- stage 3: full descent for A0=%a ---\n", (double)c.p.A0);
		ErrStats winSt = c.st;
		c.st = descend(c.p, c.segs, false, 12, 0, EB_N, false);
		printStats("  full", c.st);
		// window validity check: the window must still contain the max
		printf("  window realMax was [-%.5f, +%.5f]\n", (double)-winSt.realMaxNeg, (double)winSt.realMaxPos);
	}
	CandA incumbent;
	incumbent.p = cur;
	incumbent.segs = curSegs;
	{
		Precomp pc;
		rebuildPrecomp(cur, curSegs, pc);
		incumbent.st = evalAll(cur, curSegs, pc);
	}
	printStats("incumbent (current constants)", incumbent.st);
	std::sort(cands.begin(), cands.end(), [](const CandA& a, const CandA& b) { return cmpStats(a.st, b.st) < 0; });

	if (cmpStats(cands[0].st, incumbent.st) < 0) {
		printf("--- winner: A0=%a beats the incumbent; final polish ---\n", (double)cands[0].p.A0);
		CandA& w = cands[0];
		w.st = descend(w.p, w.segs, false, 0, 0, EB_N, true);
		Precomp pc;
		rebuildPrecomp(w.p, w.segs, pc);
		report(w.p, w.segs, pc, "winner");
		printParams(stdout, w.p);
		const char *outName = "log_searchA0_result.txt";
		FILE *f = fopen(outName, "w");
		if (f) {
			printParams(f, w.p);
			fclose(f);
			printf("(saved to %s)\n", outName);
		}
	} else {
		printf("--- no A0 candidate beats the incumbent: the current A0=%a is (near-)optimal ---\n", (double)cur.A0);
	}
	printf("total %.1f sec\n", omp_get_wtime() - t0);
	return 0;
}

static int validate(const Params& p)
{
	void (*kernel)(float*, const float*, size_t);
	if (p.avx2) {
		kernel = fmath_logf_v_avx2;
	} else {
		if (fmath_logf_v == fmath_logf_v_avx2) {
			fprintf(stderr, "this CPU does not dispatch to the AVX-512 kernel; validate needs AVX-512\n");
			return 1;
		}
		kernel = p.tq ? fmath_logf_v_avx512_tq : fmath_logf_v_avx512;
	}
	auto segs = buildSegs(p);
	checkSegs(segs, p.tblN);
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
			kernel(y.data(), x.data(), BLK);
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
	printf("validate OK: %s model is bit-exact over all positive normal floats (%.2f sec)\n", p.avx2 ? "avx2" : p.tq ? "tq" : "poly", omp_get_wtime() - t0);
	return 0;
}

// coordinate descent (table passes + poly passes with a widening ladder) on
// the exponent window [eiLo, eiHi); maxIter = 0 means run until convergence
static ErrStats descend(Params& p, const std::vector<Seg>& segs, bool unpin, int maxIter, int eiLo, int eiHi, bool verbose)
{
	Precomp pc;
	rebuildPrecomp(p, segs, pc);
	auto binStats = evalBins(p, segs, eiLo, eiHi);
	const int K1base = 16, K2base = 4, KP = 32;
	int K1 = K1base, K2 = K2base;
	double t0 = omp_get_wtime();
	for (int iter = 1; maxIter == 0 || iter <= maxIter; iter++) {
		if (verbose) printf("--- iteration %d (K1=%d K2=%d, %.1f sec) ---\n", iter, K1, K2, omp_get_wtime() - t0);
		bool imp = tablePass(p, segs, binStats, K1, K2, unpin, eiLo, eiHi, verbose);
		rebuildPrecomp(p, segs, pc);
		imp |= polyPass(p, segs, pc, binStats, KP, eiLo, eiHi, verbose);
		if (imp) {
			K1 = K1base;
			K2 = K2base;
		} else if (K1 < 64) {
			K1 *= 2;
			K2 *= 2;
			if (verbose) printf("no improvement; widening neighborhood\n");
		} else {
			if (verbose) printf("converged\n");
			break;
		}
	}
	return mergeAll(binStats);
}

static int search(Params p, bool unpin)
{
	auto segs = buildSegs(p);
	checkSegs(segs, p.tblN);
	buildRef();
	Precomp pc;
	rebuildPrecomp(p, segs, pc);
	printf("--- initial constants ---\n");
	report(p, segs, pc, "initial");
	{
		// sanity: per-bin stats must add up to the full sweep
		ErrStats sum = mergeAll(evalBins(p, segs));
		ErrStats all = evalAll(p, segs, pc);
		if (cmpStats(sum, all) != 0 || sum.cnt1 != all.cnt1) {
			fprintf(stderr, "internal error: per-bin stats do not match full sweep\n");
			return 1;
		}
	}
	double t0 = omp_get_wtime();
	if (p.tq || p.avx2) {
		// the seed coefficients (poly-form values for tq, L2-optimal values
		// for avx2) may sit further from the lexicographic optimum than the
		// +-32 ulp descent reach, so walk them in with a coarse-to-fine
		// ladder first
		const int wLo = 120, wHi = 133; // e in [-6, +7)
		auto binStats = evalBins(p, segs, wLo, wHi);
		for (int step : {512, 64, 8}) {
			for (int round = 0; round < 6; round++) {
				if (!polyPass(p, segs, pc, binStats, 32, wLo, wHi, false, step)) break;
			}
			printf("coarse ladder step %4d: c2=%a c3=%a c4=%a c5=%a\n", step,
				(double)p.c2, (double)p.c3, (double)p.c4, (double)p.c5);
		}
	}
	descend(p, segs, unpin, 0, 0, EB_N, true);
	rebuildPrecomp(p, segs, pc);
	printf("--- final constants (%.1f sec) ---\n", omp_get_wtime() - t0);
	report(p, segs, pc, "final");
	printParams(stdout, p);
	const char *outName = p.avx2 ? "log_search_result_avx2.txt" : p.tq ? "log_search_result_tq.txt" : "log_search_result.txt";
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
	bool tq = false;
	bool avx2 = false;
	for (int i = 2; i < argc; i++) {
		if (strcmp(argv[i], "--unpin") == 0) unpin = true;
		if (strcmp(argv[i], "--tq") == 0) tq = true;
		if (strcmp(argv[i], "--avx2") == 0) avx2 = true;
	}
	if (tq && avx2) {
		fprintf(stderr, "--tq and --avx2 are exclusive\n");
		return 1;
	}
	Params p = avx2 ? currentParamsAVX2() : tq ? currentParamsTq() : currentParams();
	if (strcmp(cmd, "validate") == 0) {
		return validate(p);
	}
	if (strcmp(cmd, "report") == 0) {
		auto segs = buildSegs(p);
		checkSegs(segs, p.tblN);
		buildRef();
		Precomp pc;
		rebuildPrecomp(p, segs, pc);
		report(p, segs, pc, "current");
		return 0;
	}
	if (strcmp(cmd, "search") == 0) {
		return search(p, unpin);
	}
	if (strcmp(cmd, "perexp") == 0) {
		return perExp(p);
	}
	if (strcmp(cmd, "searchA0") == 0) {
		if (avx2) {
			fprintf(stderr, "searchA0 applies only to the AVX-512 kernel (the avx2 index has no scale)\n");
			return 1;
		}
		return searchA0();
	}
	fprintf(stderr, "usage: log_search.exe validate|report|search|perexp|searchA0 [--unpin] [--tq] [--avx2]\n");
	return 1;
}
