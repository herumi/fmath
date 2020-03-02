#include "fmath2.hpp"
#include <cybozu/test.hpp>
#include <cybozu/benchmark.hpp>
#include <vector>

float g_maxe;

float diff(float x, float y)
{
	return std::abs(x - y) / x;
}

float fmath_expf(float x)
{
	float y;
	fmath::expf_v(&y, &x, 1);
	return y;
}

inline float expfC(float x)
{
	using namespace fmath;
	const local::ConstVar& C = *local::Inst<>::code.constVar;
	x = (std::min)(x, C.expMax);
	x = (std::max)(x, C.expMin);
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

CYBOZU_TEST_AUTO(setMaxE)
{
	puts("expfC");
	putDiff(-10, 10, 0.5, expfC);
	putDiff(-30, 30, 1e-5, expfC);
	puts("fmath::expf_v");
	putDiff(-10, 10, 0.5, fmath_expf);
	g_maxe = putDiff(-30, 30, 1e-5, fmath_expf);
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
	const size_t C = 30000;
	for (size_t i = 0; i < n; i++) {
		x[i] = sin(i / double(n) * 7) * 20;
	}
	printf("for float x[%zd];\n", n);
	CYBOZU_BENCH_C("std_exp_v", C, std_exp_v, &y0[0], &x[0], n);
	CYBOZU_BENCH_C("expf_v  ", C, fmath::expf_v, &y1[0], &x[0], n);
	checkDiff(y0.data(), y1.data(), n);
}

CYBOZU_TEST_AUTO(limit)
{
	const size_t n = 4;
	float x[n] = { -100, -80, 80, 100 };
	float y0[n];
	float y1[n];
	std_exp_v(y0, x, n);
	fmath::expf_v(y1, x, n);
	for (size_t i = 0; i < n; i++) {
		printf("x=%e std=%e fmath2=%e\n", x[i], y0[i], y1[i]);
	}
}
