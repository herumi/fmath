#include "fmath2.hpp"
#include <cybozu/test.hpp>
#include <cybozu/benchmark.hpp>
#include <vector>

float g_maxe;

CYBOZU_TEST_AUTO(diff)
{
	float maxe = 0;
	for (float x = -30; x < 30; x += 1e-5) {
		float y1 = fmath2::expfC(x);
		float y2 = std::exp(x);
		float e = std::abs(y1 - y2) / y1;
		if (e > maxe) {
			maxe = e;
		}
	}
	printf("maxe=%e\n", maxe);
	g_maxe = maxe;
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
	for (size_t i = 0; i < n; i++) {
		float d = (std::abs)(y1[i] - y2[i]) / y1[i];
		CYBOZU_TEST_ASSERT(d <= g_maxe);
#if 0
		if (d > g_maxe) {
			printf("%zd d=%e exp(%e) %e %e\n", i, d, y0[i], y1[i], y2[i]);
		}
#endif
	}
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

CYBOZU_TEST_AUTO(bench)
{
	Fvec x, y;
	const size_t n = 10000;
	x.resize(n);
	y.resize(n);
	const size_t C = 10000;
	for (size_t i = 0; i < n; i++) {
		x[i] = sin(i / double(n) * 3) * 20;
	}
	CYBOZU_BENCH_C("std_exp_v", C, copy_exp, y, x, std_exp_v);
	CYBOZU_BENCH_C("expf_vC", C, copy_exp, y, x, fmath2::expf_vC);
	CYBOZU_BENCH_C("expf_v", C, copy_exp, y, x, fmath2::expf_v);
}
