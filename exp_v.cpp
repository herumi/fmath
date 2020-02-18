#include "fmath2.hpp"
#include <cybozu/test.hpp>
#include <cybozu/benchmark.hpp>
#include <vector>

float g_maxe;

float diff(float x, float y)
{
	return std::abs(x - y) / x;
}

CYBOZU_TEST_AUTO(diff)
{
	float maxe = 0;
	double ave = 0;
	int aveN = 0;
	for (float x = -30; x < 30; x += 1e-5) {
		float y1 = fmath2::expfC(x);
		float y2 = std::exp(x);
		float e = diff(y1, y2);
		if (e > maxe) {
			maxe = e;
		}
		ave += e;
		aveN++;
	}
	printf("maxe=%e\n", maxe);
	printf("ave=%e\n", ave / aveN);
	g_maxe = maxe;
}

void checkDiff(const float *x, const float *y, size_t n)
{
	for (size_t i = 0; i < n; i++) {
		float d = diff(x[i], y[i]);
		CYBOZU_TEST_ASSERT(d <= g_maxe);
	}
}

CYBOZU_TEST_AUTO(expf_v)
{
	const size_t n = 300;
	float y0[n];
	float y1[n];
	float y2[n];
	for (size_t i = 0; i < n; i++) {
		float x = float((i - n/2.0) / n * 20);
		y0[i] = x;
		y1[i] = x;
		y2[i] = x;
	}
	fmath2::expf_vC(y1, n);
	fmath2::expf_v(y2, n);
	checkDiff(y1, y2, n);
}

typedef std::vector<float> Fvec;

template<class F>
void copy_exp(Fvec& out, const Fvec& in, const F& f)
{
	out = in;
	f(&out[0], out.size());
}

void std_exp_v(float *px, size_t n)
{
	for (size_t i = 0; i < n; i++) {
		px[i] = std::exp(px[i]);
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
	float y0[16];
	float *base = getBoundary();
	// can't write base[16]
	for (int i = 0; i < 16; i++) {
		float *y1 = base + i;
		for (int j = 0; j < 16 - i; j++) {
			y0[j] = float(j);
			y1[j] = y0[j];
		}
		int n = 16 - i;
		fmath2::expf_vC(y0, n);
		fmath2::expf_v(y1, n);
		checkDiff(y0, y1, n);
	}
}

CYBOZU_TEST_AUTO(bench)
{
	Fvec x, y, z;
	const size_t n = 3000;
	x.resize(n);
	y.resize(n);
	z.resize(n);
	const size_t C = 10000;
	for (size_t i = 0; i < n; i++) {
		x[i] = sin(i / double(n) * 7) * 20;
	}
	CYBOZU_BENCH_C("std_exp_v", C, copy_exp, y, x, std_exp_v);
	CYBOZU_BENCH_C("expf_vC", C, copy_exp, z, x, fmath2::expf_vC);
	checkDiff(y.data(), z.data(), n);
	CYBOZU_BENCH_C("expf_v", C, copy_exp, z, x, fmath2::expf_v);
	checkDiff(y.data(), z.data(), n);
}
