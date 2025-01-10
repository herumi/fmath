#pragma once
#include <stdint.h>

#define FMATH_tOSXSAVE (1ull<<1)
#define FMATH_tAVX (1ull<<2)
#define FMATH_tFMA (1ull<<3)
#define FMATH_tAVX2 (1ull<<4)
#define FMATH_tBMI1 (1ull<<5)
#define FMATH_tBMI2 (1ull<<6)
#define FMATH_tINTEL (1ull<<7)
#define FMATH_tAMD (1ull<<8)
#define FMATH_tADX (1ull<<9)
#define FMATH_tAVX512F (1ull<<10)
#define FMATH_tAVX512DQ (1ull<<11)
#define FMATH_tAVX512_IFMA (1ull<<12)
#define FMATH_tAVX512_FP16 (1ull<<13)
#define FMATH_tAVX512PF (1ull<<14)
#define FMATH_tAVX512ER (1ull<<15)
#define FMATH_tAVX512CD (1ull<<16)
#define FMATH_tAVX512BW (1ull<<17)
#define FMATH_tAVX512VL (1ull<<18)
#define FMATH_tAVX512_VBMI (1ull<<19)
#define FMATH_tAVX512_4VNNIW (1ull<<20)
#define FMATH_tAVX512_4FMAPS (1ull<<21)
#define FMATH_tSHA (1ull<<22)
#define FMATH_tAVX512_VBMI2 (1ull<<23)
#define FMATH_tGFNI (1ull<<24)
#define FMATH_tVAES (1ull<<25)
#define FMATH_tVPCLMULQDQ (1ull<<26)
#define FMATH_tAVX512_VNNI (1ull<<27)
#define FMATH_tAVX512_BITALG (1ull<<28)
#define FMATH_tAVX512_VPOPCNTDQ (1ull<<29)
#define FMATH_tAVX512_BF16 (1ull<<30)
#define FMATH_tAVX512_VP2INTERSECT (1ull<<31)
#define FMATH_tAMX_TILE (1ull<<32)
#define FMATH_tAMX_INT8 (1ull<<33)
#define FMATH_tAMX_BF16 (1ull<<34)
#define FMATH_tAVX_VNNI (1ull<<35)
#define FMATH_tAMX_FP16 (1ull<<36)
#define FMATH_tAVX_VNNI_INT8 (1ull<<37)
#define FMATH_tAVX_NE_CONVERT (1ull<<38)
#define FMATH_tAVX_IFMA (1ull<<39)
#define FMATH_tRAO_INT (1ull<<40)
#define FMATH_tCMPCCXADD (1ull<<41)
#define FMATH_tPREFETCHITI (1ull<<42)	

#ifdef __cplusplus
extern "C" {
#endif

uint64_t fmath_get_cpu_type();

#ifdef __cplusplus
}
#endif
