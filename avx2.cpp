#include "fmath.hpp"
#include <cybozu/benchmark.hpp>
#include <cybozu/inttype.hpp>

void check_exp_ps256()
{
	MIE_ALIGN(32) float in[8], out[8];
	const int N = 10;
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
			if (fabs(z - out[j]) / z > 1e-5) {
				printf("err x=%f ok=%f ng=%f\n", in[j], z, out[j]);
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
}
