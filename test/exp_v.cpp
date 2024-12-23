#define CYBOZU_TEST_DISABLE_AUTO_RUN
#include "fmath.h"
#include <vector>
#include <float.h>
#include <cybozu/test.hpp>
#include <cybozu/benchmark.hpp>
#include <cybozu/inttype.hpp>

#include <xbyak/xbyak_util.h>
#include <cmath>

namespace local {

union fi {
	float f;
	uint32_t i;
};

} // local

inline float u2f(uint32_t x)
{
	local::fi fi;
	fi.i = x;
	return fi.f;
}

inline uint32_t f2u(float x)
{
	local::fi fi;
	fi.f = x;
	return fi.i;
}


float g_maxe;

float diff(float x, float y)
{
	return std::abs(x - y) / x;
}

inline float split(int *pn, float x)
{
	int n;
	if (x >= 0) {
		n = int(x + 0.5f);
	} else {
		n = int(x - 0.5f);
	}
	*pn = n;
	return x - n;
}

inline float expfC(float x)
{
	struct {
		float log2;
		float log2_e;
		float expCoeff[5];
	} C;
	C.log2 = std::log(2.0f);
	C.log2_e = 1.0f / C.log2;
	const uint32_t expTbl[] = {
		0x3f800000,
		0x3effff12,
		0x3e2aaa56,
		0x3d2b89cc,
		0x3c091331,
	};
	for (int i = 0; i < 5; i++) {
		local::fi fi;
		fi.i = expTbl[i];
		C.expCoeff[i] = fi.f;
	}
	x *= C.log2_e;
	int n;
	float a = split(&n, x);
	/* |a| <= 0.5 */
	a *= C.log2;
	/* |a| <= 0.3466 */
	local::fi fi;
	fi.i = (n + 127) << 23; // 2^n
	/*
		e^a = 1 + a + a^2/2! + a^3/3! + a^4/4! + a^5/5!
		= 1 + a(1 + a(1/2! + a(1/3! + a(1/4! + a/5!))))
	*/
	x = C.expCoeff[4];
	x = a * x + C.expCoeff[3];
	x = a * x + C.expCoeff[2];
	x = a * x + C.expCoeff[1];
	x = a * x + C.expCoeff[0];
	x = a * x + C.expCoeff[0];
	return x * fi.f;
}

void std_exp_v(float *dst, const float *src, size_t n)
{
	for (size_t i = 0; i < n; i++) {
		dst[i] = std::exp(src[i]);
	}
}

template<class F>
float putDiff(float begin, float end, float step, const F& f)
{
	float maxe = 0;
	float maxx = 0;
	double ave = 0;
	int aveN = 0;
	for (float x = begin; x < end; x += step) {
		float y0 = std::exp(x);
		float y1 = f(x);
		float e;
		e = diff(y0, y1);
		if (e > maxe) {
			maxe = e;
			maxx = x;
		}
		ave += e;
		aveN++;
	}
	printf("range [%.2e, %.2e] step=%.2e\n", begin, end, step);
	printf("maxe=%e (x=%e)\n", maxe, maxx);
	printf("ave=%e\n", ave / aveN);
	return maxe;
}

CYBOZU_TEST_AUTO(first)
{
	const size_t N = 31;
	float x[N], y[N+1];
	const float edge = 100;
	y[N] = edge;
	for (size_t i = 0; i < N; i++) {
		x[i] = float(i * 0.5);
	}
	for (size_t n = 0; n < N; n++) {
		memset(y, 0, N*sizeof(y[0]));
		fmath::expf_v(y, x, n);
		for (size_t i = 0; i < n; i++) {
			float z = exp(x[i]);
			CYBOZU_TEST_NEAR(y[i], z, 1e-5*y[i]);
		}
		CYBOZU_TEST_EQUAL(y[N], edge);
	}
}

CYBOZU_TEST_AUTO(setMaxE)
{
	puts("expfC");
	putDiff(-10, 10, 0.5, expfC);
	putDiff(-30, 30, 1e-5, expfC);
	puts("fmath::expf_v");
	putDiff(-10, 10, 0.5, fmath::expf);
	g_maxe = putDiff(-30, 30, 1e-5, fmath::expf);
}

void checkDiff(const float *x, const float *y, size_t n, bool put = false)
{
	for (size_t i = 0; i < n; i++) {
		float d = diff(x[i], y[i]);
		if (put) {
			if (d > g_maxe) {
				printf("err n=%zd, i=%zd x=%e y=%e\n", n, i, x[i], y[i]);
			}
		} else {
			CYBOZU_TEST_ASSERT(d <= g_maxe);
		}
	}
}

CYBOZU_TEST_AUTO(expf_v)
{
	const size_t n = 300;
	float x[n];
	float y1[n];
	float y2[n];
	for (size_t i = 0; i < n; i++) {
		x[i] = float((i - n/2.0) / n * 20);
	}
	std_exp_v(y1, x, n);
	fmath::expf_v(y2, x, n);
	checkDiff(y1, y2, n);
}

typedef std::vector<float> Fvec;

void putClk(const char *msg, size_t n)
{
	printf("%s %.2fclk\n", msg, cybozu::bench::g_clk.getClock() / double(n));
}

// return address which can be wrriten 64 byte
float *getBoundary()
{
	const int size = 4096;
	static MIE_ALIGN(4096) uint8_t top[size * 3];
	float *base = (float*)(top + size - 64);
	bool isOK = Xbyak::CodeArray::protect(top + size, size, Xbyak::CodeArray::PROTECT_RE);
	CYBOZU_TEST_ASSERT(isOK);
	return base;
}

CYBOZU_TEST_AUTO(boundary)
{
	float x[16];
	float y0[16];
	for (int i = 0; i < 16; i++) {
		x[i] = i / 8.0f;
	}
	float *base = getBoundary();
	// can't write base[16]
	for (int i = 0; i < 16; i++) {
		float *y1 = base + i;
		int n = 16 - i;
		std_exp_v(y0, x, n);
		fmath::expf_v(y1, x, n);
		checkDiff(y0, y1, n);
	}
}

CYBOZU_TEST_AUTO(bench)
{
	Fvec x, y0, y1;
	const size_t n = 1024 * 16;
	x.resize(n);
	y0.resize(n);
	y1.resize(n);
	const int C = 90000;
	for (size_t i = 0; i < n; i++) {
		x[i] = sin(i / float(n) * 7) * 20;
	}
	printf("for float x[%zd];\n", n);
	CYBOZU_BENCH_C("", C, std_exp_v, &y0[0], &x[0], n);
	putClk("std::exp", C * (n / 16));
	CYBOZU_BENCH_C("", C, fmath::expf_v, &y1[0], &x[0], n);
	putClk("fmath::expf_v", C * (n / 16));
	checkDiff(y0.data(), y1.data(), n);
}

void limitTest(float f1(float), float f2(float))
{
	float tbl[] = { // abcdef
		0.0f, FLT_MIN, 0.5f, 1.0f, 9.1, 0x1.62e42ap+6f, 0x1.62e42cp+6f, 0x1.62e42ep+6f, 0x1.62e430p+6f/*exp(x)=inf*/, 0x1.62e432p+6f, FLT_MAX, u2f(0x7f800000), /*Inf*/
	};
	for (size_t i = 0; i < CYBOZU_NUM_OF_ARRAY(tbl); i++) {
		float x = tbl[i];
		float a = f1(x);
		float b = f2(x);
		float e = fabs(a - b);
		printf("x=%e std=%e fmath2=%e diff=%e\n", x, a, b, e);
		a = f1(-x);
		b = f2(-x);
		e = fabs(a - b);
		printf("x=%e std=%e fmath2=%e diff=%e\n", -x, a, b, e);
	}
}

void check(float x, float y, float z, float& max_e, float& max_x, float edge)
{
	float d1 = fabsf(y - z);
	float e = (d1 < 1e-7 || y < 1e-7) ? d1 : d1/y;
	if (e >= edge) {
		printf("ERR x=%f(%0.6a:%08x) y=%e(%0.6a) z=%e(%0.6a) e=%e\n", x, x, f2u(x), y, y, z, z, e);
		CYBOZU_TEST_ASSERT(false);
	}
	if (e > max_e) {
		max_e = e;
		max_x = x;
	}
}

void testAll()
{
	puts("testAll");
	const uint32_t INF = 0x7f800000;

	float max_e, max_x;

	// plus
	max_e = max_x = 0;
	for (uint32_t u = 0; u <= 0x7fffffff; u++) {
		float x = u2f(u);
		float y = expf(x);
		float z = fmath::expf(x);
		if (f2u(y) != INF && f2u(z) != INF) {
			check(x, y, z, max_e, max_x, 4.1e-6);
		}
	}
	printf("max_e=%e max_x=%e\n", max_e, max_x);

	// minus
	max_e = max_x = 0;
	for (uint32_t u = 0; u <= 0x7fffffff; u++) {
		float x = -u2f(u);
		float y = expf(x);
		float z = fmath::expf(x);
		if (f2u(y) != INF && f2u(z) != INF) {
			check(x, y, z, max_e, max_x, 1e-6);
		}
	}
	printf("max_e=%e max_x=%e\n", max_e, max_x);
}

CYBOZU_TEST_AUTO(expLimit)
{
	puts("expLimit");
	limitTest(std::exp, fmath::expf);
}

void bench()
{
	Fvec x, y0, y1;
	const size_t base = 5 * 7 * 11 * 9 * 16;
	const size_t n = (65536 / base) * base;
	x.resize(n);
	y0.resize(n);
	y1.resize(n);
	const int C = 50000;
	for (size_t i = 0; i < n; i++) {
		x[i] = sin(i / float(n) * 7) * 20;
	}
	CYBOZU_BENCH_C("", C, fmath::expf_v, &y1[0], &x[0], n);
	putClk("fmath::expf_v", C * (n / 32));
}

int main(int argc, char *argv[])
{
	if (argc > 1) {
		switch (argv[1][0]) {
		case 'b':
			bench();
			return 0;
		case 'a':
			testAll();
			return 0;
		default:
			printf("ERR %c\n", argv[1][0]);
			return 1;
		}
	}
	return cybozu::test::autoRun.run(argc, argv);
}
