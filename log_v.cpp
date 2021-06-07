#include "fmath2.hpp"
#include <cybozu/test.hpp>
#include <cybozu/benchmark.hpp>
#include <float.h>
#include <vector>

float g_maxe;

float diff(float x, float y)
{
	float d = std::abs(x - y);
	return fabs(x) > 1e-10 ? d / x : d;
}

float fmath_logf(float x)
{
	float y;
	fmath::logf_v(&y, &x, 1);
	return y;
}

float logfC(float x)
{
	using namespace fmath;
	const local::ConstVar& C = *local::Inst<>::code.constVar;
	local::fi fi;
	fi.f = x;
	float e = (int(fi.i - (127 << 23))) >> 23;
	fi.i = (fi.i & 0x7fffff) | (127 << 23);
	float y = fi.f;
	/*
		x = y * 2^e (1 <= y < 2)
		log(x) = e log2 + log(y)
		a = (2/3) y - 1 (|a|<=1/3)
		y = 1.5(1 + a)
		log(y) = log 1.5 + log(1 + a)
		log(x) = e log2 + log 1.5 + (a - a^2/2 + a^3/3 - ...)
	*/
	float a = C.f2div3 * y - C.logCoeff[0];
	e = e * C.log2 + C.log1p5;

	const float *tbl = C.logCoeff;
#if 0
	float aa = a * a;
	float x0 = tbl[8];
	float x1 = tbl[7];
	x0 = x0 * aa + tbl[6];
	x1 = x1 * aa + tbl[5];
	x0 = x0 * aa + tbl[4];
	x1 = x1 * aa + tbl[3];
	x0 = x0 * aa + tbl[2];
	x1 = x1 * aa + tbl[1];
	x0 = x0 * aa + tbl[0];
	x = x1 * a + x0;
#else
	const int logN = C.logN;
	x = tbl[logN - 1];
	for (int i = logN - 2; i >= 0; i--) {
		x = x * a + tbl[i];
	}
#endif
	x = x * a + e;
	return x;
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
	puts("logfC");
	putDiff(1, 2, 1e-6, logfC);
	putDiff(1e-6, 4, 1e-6, logfC);
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
