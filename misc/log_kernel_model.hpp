#pragma once
/*
	bit-exact scalar model of fmath_logf_v_avx512 (LogGenAVX512 in src/gen_fmath.py)
	Every fma in the kernel is written as an explicit std::fma; this header must be
	compiled with -ffp-contract=off so no other expression gets fused.
*/
#include <bit>
#include <cmath>
#include <cstdint>

namespace log_model {

inline uint32_t f2u(float x) { return std::bit_cast<uint32_t>(x); }
inline float u2f(uint32_t u) { return std::bit_cast<float>(u); }

// valid for positive normal x only
inline float vgetexpps(float x)
{
	return (float)(int)((f2u(x) >> 23) - 127);
}

inline float vgetmantps(float x)
{
	return u2f((f2u(x) & 0x007fffff) | 0x3f800000);
}

struct Params {
	// fixed constants
	float A0; // index scale
	float A1; // 0x1.p+19 round/bias magic
	float A2; // mantissa-halving threshold
	float log2f; // log_A4
	// searched constants
	float c2, c3, c4; // log_coef[0..2]
	float tbl1[16]; // invs
	float tbl2[16]; // ~ -log(tbl1[i])
};

// current constants from gen_fmath.py (tuned by log_search.cpp)
inline Params currentParams()
{
	Params p;
	p.A0 = 0x1.fd9c88p-1f;
	p.A1 = 0x1.p+19f;
	p.A2 = 0x1.79c328p+0f;
	p.log2f = 0x1.62e430p-1f;
	p.c2 = -0x1.ffffe2p-2f;
	p.c3 = 0x1.556ebcp-2f;
	p.c4 = -0x1.fb137cp-3f;
	const float tbl1[16] = {
		0x1.000000p+0f,
		0x1.e2864ap-1f,
		0x1.c726b8p-1f,
		0x1.af3560p-1f,
		0x1.99a926p-1f,
		0x1.861af8p-1f,
		0x1.746c5cp-1f,
		0x1.6435b2p-1f,
		0x1.556520p+0f,
		0x1.47a884p+0f,
		0x1.3b1c42p+0f,
		0x1.2f6412p+0f,
		0x1.249568p+0f,
		0x1.1a8198p+0f,
		0x1.1118ccp+0f,
		0x1.04d878p+0f,
	};
	const float tbl2[16] = {
		0x0.000000p+0f,
		0x1.e5b9fep-5f,
		0x1.e21400p-4f,
		0x1.5fb580p-3f,
		0x1.c8b1c0p-3f,
		0x1.166f00p-2f,
		0x1.45eec0p-2f,
		0x1.738320p-2f,
		-0x1.26c580p-2f,
		-0x1.f96f00p-3f,
		-0x1.a97680p-3f,
		-0x1.5bd780p-3f,
		-0x1.118ec0p-3f,
		-0x1.938d02p-4f,
		-0x1.08cd7ep-4f,
		-0x1.333800p-6f,
	};
	for (int i = 0; i < 16; i++) {
		p.tbl1[i] = tbl1[i];
		p.tbl2[i] = tbl2[i];
	}
	return p;
}

// table index used by vpermps: low 4 bits of the bit pattern of idxf
inline uint32_t tblIdx(const Params& p, float mant)
{
	float idxf = std::fma(mant, p.A0, p.A1);
	return f2u(idxf) & 15;
}

inline float logModel(const Params& p, float x)
{
	float expo = vgetexpps(x); // vgetexpps
	float mant = vgetmantps(x); // vgetmantps
	uint32_t d = tblIdx(p, mant); // vfmadd213ps + vpermps
	if (mant >= p.A2) { // vcmpgeps
		expo += 1.0f; // vaddps (exact)
		mant *= 0.5f; // vmulps (exact)
	}
	float t = std::fma(mant, p.tbl1[d], -1.0f); // vfmsub213ps
	float poly = std::fma(p.c4, t, p.c3); // vfmadd213ps
	poly = std::fma(poly, t, p.c2); // vfmadd213ps
	poly = std::fma(poly, t, 1.0f); // vfmadd213ps
	float z = std::fma(expo, p.log2f, p.tbl2[d]); // vfmadd132ps
	return std::fma(t, poly, z); // vfmadd213ps
}

} // log_model
