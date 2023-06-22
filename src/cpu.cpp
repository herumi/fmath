#include "cpu.hpp"
#include <stdio.h>

static const uint64_t g_cpuType = Cpu::getType();

struct Init {
	Init()
	{
		uint64_t t = FMATH_tAVX512F | FMATH_tAVX512VL | FMATH_tAVX512DQ;
		if ((g_cpuType & t) != t) {
			fprintf(stderr, "AVX-512 is not supported\n");
		}
	}
} s_init;


uint64_t fmath_get_cpu_type()
{
	return g_cpuType;
}
