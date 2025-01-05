#define XBYAK_ONLY_CLASS_CPU
#include "xbyak_util.h"
#include "fmath.h"

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
	static const Xbyak::util::Cpu cpu;
	using namespace Xbyak::util;
	if (cpu.has(Cpu::tAVX512F|Cpu::tAVX512DQ)) {
		fmath_expf_v = fmath_expf_v_avx512;
//		fmath_logf_v = fmath_logf_v_avx512;
	}
}

}

