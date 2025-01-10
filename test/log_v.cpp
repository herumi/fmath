#define CYBOZU_TEST_DISABLE_AUTO_RUN
#include "fmath.h"
#include <cybozu/test.hpp>
#include <cybozu/benchmark.hpp>
#include <float.h>
#include <vector>
#include <cmath>
#include "reference.hpp"

namespace local {

union fi {
	float f;
	uint32_t i;
};

inline float u2f(uint32_t x)
{
	fi fi;
	fi.i = x;
	return fi.f;
}

inline uint32_t f2u(float x)
{
	fi fi;
	fi.f = x;
	return fi.i;
}

} // local

float g_maxe;

float diff(float x, float y)
{
	float d = std::fabs(x - y);
	return fabs(x) > 1e-10 ? d / fabs(x) : d;
}

// array version by std::logf
void std_logf_v(float *dst, const float *src, size_t n)
{
	for (size_t i = 0; i < n; i++) {
		dst[i] = std::log(src[i]);
	}
}

// array version by fmath::logf (slow)
void fmath_logf_v_slow(float *dst, const float *src, size_t n)
{
	for (size_t i = 0; i < n; i++) {
		dst[i] = fmath_logfC(src[i]);
	}
}
// single version by fmath::logf_v (slow) for same interface of std::logf
float fmath_logf_slow(float x)
{
	float y;
	fmath_logf_v(&y, &x, 1);
	return y;
}

template<class F>
float putDiff(float begin, float end, float step, const F& f)
{
	float maxe = 0;
	float maxx = 0;
	double ave = 0;
	int aveN = 0;
	for (float x = begin; x < end; x += step) {
		float y0 = std::log(x);
		float y1 = f(x);
		float e = diff(y0, y1);
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
	fmath_init();
	const size_t N = 8;
	float x[N], y[N];
	for (size_t i = 0; i < N; i++) {
		x[i] = i*0.3+1;
		y[i] = 0;
	}
	fmath::logf_v(y, x, N);
	for (size_t i = 0; i < N; i++) {
		float z = logf(x[i]);
		printf("%2zd x=%e std=%e my=%e diff=%e\n", i, x[i], z, y[i], fabs(z-y[i]));
	}
}

CYBOZU_TEST_AUTO(setMaxE)
{
	puts("fmath::logf_v");
	putDiff(1, 2, 1e-6, fmath_logf_slow);
	putDiff(2, 3, 1e-6, fmath_logf_slow);
	putDiff(0.99, 1.01, 1e-6, fmath_logf_slow);
	putDiff(1, 1.01, 1e-6, fmath_logf_slow);
	putDiff(0.99, 1, 1e-6, fmath_logf_slow);
	g_maxe = putDiff(1e-6, 4, 1e-6, fmath_logf_slow);
	printf("g_maxe=%e\n", g_maxe);
}

void checkDiff(const float *x, const float *y, size_t n, bool put = true)
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

typedef std::vector<float> Fvec;

void putClk(const char *msg, size_t n)
{
	printf("%s %.2fclk\n", msg, cybozu::bench::g_clk.getClock() / double(n));
}

CYBOZU_TEST_AUTO(bench)
{
	Fvec x, y0, y1;
	const size_t base = 5 * 7 * 11 * 9 * 16;
	const size_t n = (65536 / base) * base;
	x.resize(n);
	y0.resize(n);
	y1.resize(n);
	const int C = 30000;
	for (size_t i = 0; i < n; i++) {
		x[i] = fabs(sin(i / double(n) * 7) * 20 + 1e-8);
	}
	printf("for float x[%zd];\n", n);

	CYBOZU_BENCH_C("", C, std_logf_v, &y0[0], &x[0], n);
	putClk("std_logf_v", C * (n / 32));

//	CYBOZU_BENCH_C("", C, fmath_logf_v_slow, &y1[0], &x[0], n);
//	putClk("fmath_logfC", C * (n / 32));

	CYBOZU_BENCH_C("", C, fmath_logf_v, &y1[0], &x[0], n);
	putClk("fmath::logf_v", C * (n / 32));

	checkDiff(y0.data(), y1.data(), n);
}

CYBOZU_TEST_AUTO(limit)
{
	float x[] = { -3, 0, FLT_MIN, 1e-8, 1, 1 + FLT_EPSILON, 1 - 1.0/3, 1 - 1e-5, 1 + 1.0/3, 1 + 1e-5, 2, 100, 1e8, FLT_MAX };
	const size_t n = sizeof(x) / sizeof(x[0]);
	float y0[n];
	float y1[n];
	std_logf_v(y0, x, n);
	fmath::logf_v(y1, x, n);
	for (size_t i = 0; i < n; i++) {
		printf("x=%.8e std=%.8e fmath2=%.8e diff=%e\n", x[i], y0[i], y1[i], diff(y0[i], y1[i]));
	}
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
	CYBOZU_BENCH_C("", C, fmath::logf_v, &y1[0], &x[0], n);
	putClk("fmath::logf_v", C * (n / 32));
}

int main(int argc, char *argv[])
{
	if (argc > 1) {
		bench();
		return 0;
	}
#if 0
	puts("small");
	for (float x = 1e-3; x < 0.03; x += 1e-3) {
		float y = logf(x);
		float z = fmath_logf_slow(x);
		float d = fabs(y - z);
		printf("x=%f y=%f z=%f %e\n", x, y, z, d);
	}
	puts("large");
	for (float x = 0.1; x < 1; x += 0.1) {
		float y = logf(x);
		float z = fmath_logf_slow(x);
		float d = fabs(y - z);
		printf("x=%f y=%f z=%f %e\n", x, y, z, d);
	}
	return 0;
#endif
	return cybozu::test::autoRun.run(argc, argv);
}
