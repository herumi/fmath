#include "fmath.hpp"
#include <cybozu/benchmark.hpp>
#include <cybozu/inttype.hpp>

#if 1
void check_exp_pd()
{
	puts("check_exp_pd");
	MIE_ALIGN(32) double in[2], out[2];
	const int N = 1000;
	double x = -3;
	__m128d vx, vy;
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < 2; j++) {
			in[j] = x + ((i * 8 + j) * 3.1 / N);
		}
		vx = _mm_load_pd(in);
		vy = fmath::exp_pd(vx);
		_mm_store_pd(out, vy);
		for (int j = 0; j < 2; j++) {
			double z = ::exp(in[j]);
			double e = fabs(z - out[j]) / z;
			if (e > 1e-3) {
				printf("err x=%f ok=%f ng=%f e=%f\n", in[j], z, out[j], e);
			}
		}
	}
	volatile __m128d z;
	CYBOZU_BENCH("exp_pd", z = fmath::exp_pd, vx);
	cybozu::disable_warning_unused_variable(z);
}
#endif

void check_expd_v()
{
	puts("check_exp_v");
	MIE_ALIGN(32) double x[4] = { 1.1, 0, -0.5, -3.5 };
	double y[4];
	for (int i = 0; i < 4; i++) {
		y[i] = exp(x[i]);
	}
	fmath::expd_v(x, 4);
	for (int i = 0; i < 4; i++) {
		double e = fabs(y[i] - x[i]) / x[i];
		if (e > 1e-6) {
			printf("err ok=%f ng=%f e=%f\n", x[i], y[i], e);
		}
	}
}
void check_exp_ps256()
{
	puts("check_exp_ps256");
	MIE_ALIGN(32) float in[8], out[8];
	const int N = 1000;
	float x = -3;
	__m256 vx, vy;
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < 8; j++) {
			in[j] = x + ((i * 8 + j) * 3.1f / N);
		}
		vx = _mm256_load_ps(in);
		vy = fmath::exp_ps256(vx);
		_mm256_store_ps(out, vy);
		for (int j = 0; j < 8; j++) {
			float z = ::expf(in[j]);
			double e = fabs(z - out[j]) / z;
			if (e > 1e-4) {
				printf("err x=%f ok=%f ng=%f e=%f\n", in[j], z, out[j], e);
			}
		}
	}
	volatile __m256 z;
	CYBOZU_BENCH("exp_ps256", z = fmath::exp_ps256, vx);
	cybozu::disable_warning_unused_variable(z);
}
int main()
{
	check_exp_ps256();
	check_exp_pd();
	check_exp_ps256();
}
