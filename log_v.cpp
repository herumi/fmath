#include "fmath2.hpp"
#include <cybozu/test.hpp>
#include <cybozu/benchmark.hpp>
#include <vector>

float g_maxe;

float diff(float x, float y)
{
	return std::abs(x - y);
}

float putDiff(float begin, float end, float step)
{
	float maxe = 0;
	float maxx = 0;
	double ave = 0;
	int aveN = 0;
	for (float x = begin; x < end; x += step) {
		float y1 = fmath::logfC(x);
		float y2 = std::log(x);
		float e;
		e = diff(y1, y2);
		if (e > maxe) {
			maxe = e;
			maxx = x;
		}
		ave += e;
		aveN++;
	}
	printf("range [%e, %e] step=%e\n", begin, end, step);
	printf("maxe=%e (x=%e)\n", maxe, maxx);
	printf("ave=%e\n", ave / aveN);
	return maxe;
}

CYBOZU_TEST_AUTO(setMaxE)
{
	putDiff(1, 2, 1e-6);
	putDiff(1e-7, 4, 0.1);
	g_maxe = putDiff(1e-6, 4, 1e-6);
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

void logf_vC(float *dst, const float *src, size_t n)
{
	for (size_t i = 0; i < n; i++) {
		dst[i] = fmath::logfC(src[i]);
	}
}

CYBOZU_TEST_AUTO(logf_v)
{
	const size_t n = 300;
	float x[n];
	float y1[n];
	float y2[n];
	for (size_t i = 0; i < n; i++) {
		x[i] = (i + 1) / float(n) * 4;
	}
	logf_vC(y1, x, n);
	fmath::logf_v(y2, x, n);
#if 0
	for (size_t i = 0; i < 16; i++) {
		printf("%2zd x=%e ok=%e ng=%e diff=%e\n", i, x[i], y1[i], y2[i], abs(y1[i] - y2[i]));
	}
#endif
	checkDiff(y1, y2, n, true);
}

typedef std::vector<float> Fvec;

void std_log_v(float *dst, const float *src, size_t n)
{
	for (size_t i = 0; i < n; i++) {
		dst[i] = std::log(src[i]);
	}
}

CYBOZU_TEST_AUTO(bench)
{
	Fvec x, y0, y1;
	const size_t n = 1024 * 16;
	x.resize(n);
	y0.resize(n);
	y1.resize(n);
	const size_t C = 100000;
	for (size_t i = 0; i < n; i++) {
		x[i] = abs(sin(i / double(n) * 7) * 20 + 1e-8);
	}
	printf("for float x[%zd];\n", n);
	CYBOZU_BENCH_C("std_log_v", C, std_log_v, &y0[0], &x[0], n);
	CYBOZU_BENCH_C("logf_v  C", C, logf_vC, &y1[0], &x[0], n);
	checkDiff(y0.data(), y1.data(), n);
	y1.clear();
	y1.resize(n);
	CYBOZU_BENCH_C("logf_v  ", C, fmath::logf_v, &y1[0], &x[0], n);
	checkDiff(y0.data(), y1.data(), n);
}

CYBOZU_TEST_AUTO(limit)
{
	const size_t n = 5;
	float x[n] = { 0, 1e-8, 1, 100, 1e8 };
	float y0[n];
	float y1[n];
	std_log_v(y0, x, n);
	fmath::logf_v(y1, x, n);
	for (size_t i = 0; i < n; i++) {
		printf("x=%e std=%e fmath2=%e\n", x[i], y0[i], y1[i]);
	}
}
