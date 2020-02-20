#include "fmath2.hpp"
#include <cybozu/test.hpp>
#include <cybozu/benchmark.hpp>
#include <vector>

float g_maxe;

float diff(float x, float y)
{
	return std::abs(x - y) / x;
}

float putDiff(float begin, float end, float step)
{
	float maxe = 0;
	double ave = 0;
	int aveN = 0;
	for (float x = begin; x < end; x += step) {
		float y1 = fmath2::expfC(x);
		float y2 = std::exp(x);
		float e;
		e = diff(y1, y2);
		if (e > maxe) {
			maxe = e;
		}
		ave += e;
		aveN++;
	}
	printf("range [%e, %e] step=%e\n", begin, end, step);
	printf("maxe=%e\n", maxe);
	printf("ave=%e\n", ave / aveN);
	return maxe;
}

CYBOZU_TEST_AUTO(setMaxE)
{
	putDiff(-10, 10, 0.5);
	g_maxe = putDiff(-30, 30, 1e-5);
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
	fmath2::expf_vC(y1, x, n);
	fmath2::expf_v(y2, x, n);
	checkDiff(y1, y2, n);
}

typedef std::vector<float> Fvec;

void std_exp_v(float *dst, const float *src, size_t n)
{
	for (size_t i = 0; i < n; i++) {
		dst[i] = std::exp(src[i]);
	}
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
		fmath2::expf_vC(y0, x, n);
		fmath2::expf_v(y1, x, n);
		checkDiff(y0, y1, n);
	}
}

CYBOZU_TEST_AUTO(bench)
{
	Fvec x, y0, y1;
	const size_t n = 3000;
	x.resize(n);
	y0.resize(n);
	y1.resize(n);
	const size_t C = 10000;
	for (size_t i = 0; i < n; i++) {
		x[i] = sin(i / double(n) * 7) * 20;
	}
	printf("for float x[%zd];\n", n);
	CYBOZU_BENCH_C("std_exp_v", C, std_exp_v, &y0[0], &x[0], n);
	CYBOZU_BENCH_C("expf_v  C", C, fmath2::expf_vC, &y1[0], &x[0], n);
	checkDiff(y0.data(), y1.data(), n);
	y1.clear();
	y1.resize(n);
	CYBOZU_BENCH_C("expf_v  ", C, fmath2::expf_v, &y1[0], &x[0], n);
	checkDiff(y0.data(), y1.data(), n);
}

CYBOZU_TEST_AUTO(limit)
{
	const size_t n = 4;
	float x[n] = { -100, -80, 80, 100 };
	float y0[n];
	float y1[n];
	std_exp_v(y0, x, n);
	fmath2::expf_v(y1, x, n);
	for (size_t i = 0; i < n; i++) {
		printf("x=%e std=%e fmath2=%e\n", x[i], y0[i], y1[i]);
	}
}
