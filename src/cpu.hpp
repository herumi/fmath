#pragma once
/*
	@author herumi
*/
#include "cpu.h"
#include <stdlib.h>
#include <assert.h>

#ifdef _WIN32
	#if defined(_MSC_VER) && (_MSC_VER < 1400) && defined(XBYAK32)
		static inline __declspec(naked) void __cpuid(int[4], int)
		{
			__asm {
				push	ebx
				push	esi
				mov		eax, dword ptr [esp + 4 * 2 + 8] // eaxIn
				cpuid
				mov		esi, dword ptr [esp + 4 * 2 + 4] // data
				mov		dword ptr [esi], eax
				mov		dword ptr [esi + 4], ebx
				mov		dword ptr [esi + 8], ecx
				mov		dword ptr [esi + 12], edx
				pop		esi
				pop		ebx
				ret
			}
		}
	#else
		#include <intrin.h> // for __cpuid
	#endif
#else
	#ifndef __GNUC_PREREQ
    	#define __GNUC_PREREQ(major, minor) ((((__GNUC__) << 16) + (__GNUC_MINOR__)) >= (((major) << 16) + (minor)))
	#endif
	#if __GNUC_PREREQ(4, 3) && !defined(__APPLE__)
		#include <cpuid.h>
	#else
		#if defined(__APPLE__) && defined(XBYAK32) // avoid err : can't find a register in class `BREG' while reloading `asm'
			#define __cpuid(eaxIn, a, b, c, d) __asm__ __volatile__("pushl %%ebx\ncpuid\nmovl %%ebp, %%esi\npopl %%ebx" : "=a"(a), "=S"(b), "=c"(c), "=d"(d) : "0"(eaxIn))
			#define __cpuid_count(eaxIn, ecxIn, a, b, c, d) __asm__ __volatile__("pushl %%ebx\ncpuid\nmovl %%ebp, %%esi\npopl %%ebx" : "=a"(a), "=S"(b), "=c"(c), "=d"(d) : "0"(eaxIn), "2"(ecxIn))
		#else
			#define __cpuid(eaxIn, a, b, c, d) __asm__ __volatile__("cpuid\n" : "=a"(a), "=b"(b), "=c"(c), "=d"(d) : "0"(eaxIn))
			#define __cpuid_count(eaxIn, ecxIn, a, b, c, d) __asm__ __volatile__("cpuid\n" : "=a"(a), "=b"(b), "=c"(c), "=d"(d) : "0"(eaxIn), "2"(ecxIn))
		#endif
	#endif
#endif

/**
	CPU detection class
*/
class Cpu {
public:
	static inline uint32_t get32bitAsBE(const char *x)
	{
		return x[0] | (x[1] << 8) | (x[2] << 16) | (x[3] << 24);
	}
	static inline uint32_t mask(int n)
	{
		return (1U << n) - 1;
	}
	static inline uint32_t extractBit(uint32_t val, uint32_t base, uint32_t end)
	{
		return (val >> base) & ((1u << (end - base)) - 1);
	}
	/*
		data[] = { eax, ebx, ecx, edx }
	*/
	static inline void getCpuid(uint32_t eaxIn, uint32_t data[4])
	{
#ifdef _WIN32
		__cpuid(reinterpret_cast<int*>(data), eaxIn);
#else
		__cpuid(eaxIn, data[0], data[1], data[2], data[3]);
#endif
	}
	static inline void getCpuidEx(uint32_t eaxIn, uint32_t ecxIn, uint32_t data[4])
	{
#ifdef _WIN32
		__cpuidex(reinterpret_cast<int*>(data), eaxIn, ecxIn);
#else
		__cpuid_count(eaxIn, ecxIn, data[0], data[1], data[2], data[3]);
#endif
	}
	static inline uint64_t getXfeature()
	{
#ifdef _MSC_VER
		return _xgetbv(0);
#else
		uint32_t eax, edx;
		// xgetvb is not support on gcc 4.2
//		__asm__ volatile("xgetbv" : "=a"(eax), "=d"(edx) : "c"(0));
		__asm__ volatile(".byte 0x0f, 0x01, 0xd0" : "=a"(eax), "=d"(edx) : "c"(0));
		return ((uint64_t)edx << 32) | eax;
#endif
	}

	static uint64_t getType()
	{
		uint64_t type_ = 0;
		uint32_t data[4] = {};
		const uint32_t& EAX = data[0];
		const uint32_t& EBX = data[1];
		const uint32_t& ECX = data[2];
		const uint32_t& EDX = data[3];
		getCpuid(0, data);
		const uint32_t maxNum = EAX;
		static const char intel[] = "ntel";
		static const char amd[] = "cAMD";
		if (ECX == get32bitAsBE(amd)) {
			type_ |= FMATH_tAMD;
		}
		if (ECX == get32bitAsBE(intel)) {
			type_ |= FMATH_tINTEL;
		}

		// Extended flags information
		getCpuid(0x80000000, data);

		getCpuid(1, data);
		if (ECX & (1U << 27)) type_ |= FMATH_tOSXSAVE;

		if (type_ & FMATH_tOSXSAVE) {
			// check XFEATURE_ENABLED_MASK[2:1] = '11b'
			uint64_t bv = getXfeature();
			if ((bv & 6) == 6) {
				if (ECX & (1U << 28)) type_ |= FMATH_tAVX;
				if (ECX & (1U << 12)) type_ |= FMATH_tFMA;
				// do *not* check AVX-512 state on macOS because it has on-demand AVX-512 support
#if !defined(__APPLE__)
				if (((bv >> 5) & 7) == 7)
#endif
				{
					getCpuidEx(7, 0, data);
					if (EBX & (1U << 16)) type_ |= FMATH_tAVX512F;
					if (type_ & FMATH_tAVX512F) {
						if (EBX & (1U << 17)) type_ |= FMATH_tAVX512DQ;
						if (EBX & (1U << 21)) type_ |= FMATH_tAVX512_IFMA;
						if (EBX & (1U << 26)) type_ |= FMATH_tAVX512PF;
						if (EBX & (1U << 27)) type_ |= FMATH_tAVX512ER;
						if (EBX & (1U << 28)) type_ |= FMATH_tAVX512CD;
						if (EBX & (1U << 30)) type_ |= FMATH_tAVX512BW;
						if (EBX & (1U << 31)) type_ |= FMATH_tAVX512VL;
						if (ECX & (1U << 1)) type_ |= FMATH_tAVX512_VBMI;
						if (ECX & (1U << 6)) type_ |= FMATH_tAVX512_VBMI2;
						if (ECX & (1U << 11)) type_ |= FMATH_tAVX512_VNNI;
						if (ECX & (1U << 12)) type_ |= FMATH_tAVX512_BITALG;
						if (ECX & (1U << 14)) type_ |= FMATH_tAVX512_VPOPCNTDQ;
						if (EDX & (1U << 2)) type_ |= FMATH_tAVX512_4VNNIW;
						if (EDX & (1U << 3)) type_ |= FMATH_tAVX512_4FMAPS;
						if (EDX & (1U << 8)) type_ |= FMATH_tAVX512_VP2INTERSECT;
						if ((type_ & FMATH_tAVX512BW) && (EDX & (1U << 23))) type_ |= FMATH_tAVX512_FP16;
					}
				}
			}
		}
		if (maxNum >= 7) {
			getCpuidEx(7, 0, data);
			const uint32_t maxNumSubLeaves = EAX;
			if (type_ & FMATH_tAVX && (EBX & (1U << 5))) type_ |= FMATH_tAVX2;
			if (EBX & (1U << 3)) type_ |= FMATH_tBMI1;
			if (EBX & (1U << 8)) type_ |= FMATH_tBMI2;
			if (EBX & (1U << 19)) type_ |= FMATH_tADX;
			if (EBX & (1U << 29)) type_ |= FMATH_tSHA;
			if (ECX & (1U << 8)) type_ |= FMATH_tGFNI;
			if (ECX & (1U << 9)) type_ |= FMATH_tVAES;
			if (ECX & (1U << 10)) type_ |= FMATH_tVPCLMULQDQ;
			if (EDX & (1U << 22)) type_ |= FMATH_tAMX_BF16;
			if (EDX & (1U << 24)) type_ |= FMATH_tAMX_TILE;
			if (EDX & (1U << 25)) type_ |= FMATH_tAMX_INT8;
			if (maxNumSubLeaves >= 1) {
				getCpuidEx(7, 1, data);
				if (EAX & (1U << 3)) type_ |= FMATH_tRAO_INT;
				if (EAX & (1U << 4)) type_ |= FMATH_tAVX_VNNI;
				if (type_ & FMATH_tAVX512F) {
					if (EAX & (1U << 5)) type_ |= FMATH_tAVX512_BF16;
				}
				if (EAX & (1U << 7)) type_ |= FMATH_tCMPCCXADD;
				if (EAX & (1U << 21)) type_ |= FMATH_tAMX_FP16;
				if (EAX & (1U << 23)) type_ |= FMATH_tAVX_IFMA;
				if (EDX & (1U << 4)) type_ |= FMATH_tAVX_VNNI_INT8;
				if (EDX & (1U << 5)) type_ |= FMATH_tAVX_NE_CONVERT;
				if (EDX & (1U << 14)) type_ |= FMATH_tPREFETCHITI;
			}
		}
		return type_;
	}
};

