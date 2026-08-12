#pragma once
/*
	bit-exact scalar model of fmath_logf_v_avx512 (LogGenAVX512 in src/gen_fmath.py)
	and fmath_logf_v_avx2 (LogGenAVX2), for positive normal inputs.
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
	float A0; // index scale (avx512 only; avx2 has no scale)
	float A1; // round/bias magic: 0x1.p+19 (avx512) / 0x1.p+20 (avx2 log2_ROUND)
	float A2; // mantissa-halving threshold (avx2: log2_BOUND)
	float log2f; // log_A4 / log2_log2
	// kernel selection
	bool tq; // false: result = fma(t, poly(t), z) ; true: result = (t + t^2 q(t)) + z
	bool avx2; // fmath_logf_v_avx2: 8-entry table, degree-5 poly form
	int tblN; // 16 (avx512) / 8 (avx2)
	int coefN; // 3 (avx512: c2..c4) / 4 (avx2: c2..c5 = log2_A..D)
	// searched constants
	float c2, c3, c4, c5; // log_coef (c5 used only when coefN == 4)
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
	p.tq = false;
	p.avx2 = false;
	p.tblN = 16;
	p.coefN = 3;
	p.c5 = 0.0f;
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

// tq variant: must match the tq constants in gen_fmath.py
inline Params currentParamsTq()
{
	Params p = currentParams();
	p.tq = true;
	p.c3 = 0x1.5577bcp-2f;
	p.c4 = -0x1.fb848ep-3f;
	// the only table entry that differs from the poly-form tables
	p.tbl1[12] = 0x1.2493bap+0f;
	p.tbl2[12] = -0x1.1182fep-3f;
	return p;
}

// current constants of the AVX2 kernel (LogGenAVX2 in gen_fmath.py)
inline Params currentParamsAVX2()
{
	Params p;
	p.A0 = 0.0f; // unused: the avx2 index has no scale
	p.A1 = 0x1.p+20f; // log2_ROUND = 2^(23-3)
	p.A2 = 0x1.7p+0f; // log2_BOUND = 1 + 7/16
	p.log2f = 0x1.62e430p-1f;
	p.tq = false;
	p.avx2 = true;
	p.tblN = 8;
	p.coefN = 4;
	// log2_A, log2_B, log2_C, log2_D (tuned by log_search.cpp)
	p.c2 = -0x1.ffffd2p-2f;
	p.c3 = 0x1.5556b4p-2f;
	p.c4 = -0x1.00f054p-2f;
	p.c5 = 0x1.97edccp-3f;
	const float tbl1[8] = { // invs_tableAVX2_L3
		0x1.000000p+0f,
		0x1.c72458p-1f,
		0x1.9999e6p-1f,
		0x1.745d16p-1f,
		0x1.555d20p+0f,
		0x1.3b1bb8p+0f,
		0x1.248f28p+0f,
		0x1.110a6ep+0f,
	};
	for (int i = 0; i < 8; i++) {
		p.tbl1[i] = tbl1[i];
		// gen_fmath.py derives tbl2 as float(-log(tbl1[i]))
		p.tbl2[i] = i == 0 ? 0.0f : (float)-std::log((double)tbl1[i]);
	}
	for (int i = 8; i < 16; i++) {
		p.tbl1[i] = 0;
		p.tbl2[i] = 0;
	}
	return p;
}

// Horner evaluation of the polynomial part, one std::fma per instruction
inline float polyOf(const Params& p, float t)
{
	float poly = p.coefN == 4 ? std::fma(p.c5, t, p.c4) : p.c4;
	poly = std::fma(poly, t, p.c3);
	poly = std::fma(poly, t, p.c2);
	return std::fma(poly, t, 1.0f);
}

/*
	per-mantissa part of the kernel as (tOut, polyOut) with
	result = fma(tOut, polyOut, z) for both forms:
	poly form: tOut = t, polyOut = poly(t)
	tq form:   tOut = w = fma(t*t, q(t), t), polyOut = 1
	(fma(w, 1, z) rounds the exact sum w + z once, so it is bitwise
	identical to the kernel's vaddps)
*/
inline void tPoly(const Params& p, float mant, float invs, float& tOut, float& polyOut)
{
	float t = std::fma(mant, invs, -1.0f); // vfmsub213ps
	if (p.tq) {
		float q = std::fma(std::fma(p.c4, t, p.c3), t, p.c2); // 2 vfmadd213ps
		tOut = std::fma(t * t, q, t); // vmulps + vfmadd213ps
		polyOut = 1.0f;
	} else {
		tOut = t;
		polyOut = polyOf(p, t);
	}
}

// table index used by vpermps: low bits of the bit pattern of idxf
inline uint32_t tblIdx(const Params& p, float mant)
{
	float idxf = p.avx2 ? mant + p.A1 // vaddps
		: std::fma(mant, p.A0, p.A1); // vfmadd213ps
	return f2u(idxf) & (uint32_t)(p.tblN - 1);
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
	float t, poly;
	tPoly(p, mant, p.tbl1[d], t, poly);
	float z = std::fma(expo, p.log2f, p.tbl2[d]); // vfmadd132ps
	if (p.tq) return t + z; // vaddps (t holds w here)
	return std::fma(t, poly, z); // vfmadd213ps
}

} // log_model
