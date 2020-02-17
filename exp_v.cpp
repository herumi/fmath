#include "fmath2.hpp"
#include <cybozu/test.hpp>

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
	const size_t n = 64;
	float y0[n];
	float y1[n];
	float y2[n];
	for (size_t i = 0; i < n; i++) {
		float x = float((i - n/2.0) / n * 3.0);
		y0[i] = x;
		y1[i] = x;
		y2[i] = x;
	}
	fmath2::expf_vC(y1, n);
	fmath2::expf_v(y2, n);
	for (size_t i = 0; i < 8; i++) {
		float d = std::abs(y1[i] - y2[i]);
//		CYBOZU_TEST_ASSERT(d <= g_maxe);
		if (d > g_maxe) {
			printf("exp(%e) %e %e\n", y0[i], y1[i], y2[i]);
		}
	}
}
