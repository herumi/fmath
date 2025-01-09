#define XBYAK_ONLY_CLASS_CPU
#include "xbyak_util.h"
#include "fmath.h"
#include <stdlib.h>
#include <string.h>

#ifdef __GNUC__
	#define ATTRIBUTE __attribute__((constructor))
#else
	#define ATTRIBUTE
#endif

extern "C" {

void (*fmath_expf_v)(float *dst, const float *src, size_t n) = fmath_expf_v_avx2;
void (*fmath_logf_v)(float *dst, const float *src, size_t n) = fmath_logf_v_avx2;

void ATTRIBUTE fmath_init()
{
	const char *env = getenv("FMATH_CPU");
	if (env && strcmp(env, "avx2") == 0) return;
	const Xbyak::util::Cpu cpu;
	using namespace Xbyak::util;
	if (cpu.has(Cpu::tAVX512F|Cpu::tAVX512DQ)) {
		fmath_expf_v = fmath_expf_v_avx512;
		fmath_logf_v = fmath_logf_v_avx512;
	}
}

}

