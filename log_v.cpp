#include "fmath2.hpp"
#include <cybozu/test.hpp>
#include <cybozu/benchmark.hpp>
#include <float.h>
#include <vector>

#ifdef FMATH_NEW
#include <xbyak/xbyak_util.h>
#include <cmath>
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

#endif

float g_maxe;

float diff(float x, float y)
{
	float d = std::abs(x - y);
	return fabs(x) > 1e-10 ? d / fabs(x) : d;
}

float fmath_logf(float x)
{
	float y;
	fmath::logf_v(&y, &x, 1);
	return y;
}

void std_log_v(float *dst, const float *src, size_t n)
{
	for (size_t i = 0; i < n; i++) {
		dst[i] = std::log(src[i]);
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

CYBOZU_TEST_AUTO(setMaxE)
{
	puts("fmath::logf_v");
	putDiff(1, 2, 1e-6, fmath_logf);
	putDiff(2, 3, 1e-6, fmath_logf);
	putDiff(0.99, 1.01, 1e-6, fmath_logf);
	g_maxe = putDiff(1e-6, 4, 1e-6, fmath_logf);
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

typedef std::vector<float> Fvec;

void putClk(const char *msg, size_t n)
{
	printf("%s %.2fclk\n", msg, cybozu::bench::g_clk.getClock() / double(n));
}

CYBOZU_TEST_AUTO(bench)
{
	Fvec x, y0, y1;
	const size_t n = 1024 * 16;
	x.resize(n);
	y0.resize(n);
	y1.resize(n);
	const int C = 30000;
	for (size_t i = 0; i < n; i++) {
		x[i] = abs(sin(i / double(n) * 7) * 20 + 1e-8);
	}
	printf("for float x[%zd];\n", n);
	CYBOZU_BENCH_C("", C, std_log_v, &y0[0], &x[0], n);
	putClk("std_log_v", C * (n / 16));
	CYBOZU_BENCH_C("", C, fmath::logf_v, &y1[0], &x[0], n);
	putClk("fmath::logf_v", C * (n / 16));
	checkDiff(y0.data(), y1.data(), n);
}

CYBOZU_TEST_AUTO(limit)
{
	float x[] = { -3, 0, FLT_MIN, 1e-8, 1, 1 + FLT_EPSILON, 1 - 1.0/3, 1 - 1e-5, 1 + 1.0/3, 1 + 1e-5, 2, 100, 1e8, FLT_MAX };
	const size_t n = sizeof(x) / sizeof(x[0]);
	float y0[n];
	float y1[n];
	std_log_v(y0, x, n);
	fmath::logf_v(y1, x, n);
	for (size_t i = 0; i < n; i++) {
		printf("x=%.8e std=%.8e fmath2=%.8e diff=%e\n", x[i], y0[i], y1[i], diff(y0[i], y1[i]));
	}
}
