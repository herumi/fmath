#define XBYAK_ONLY_CLASS_CPU
#include "xbyak_util.h"
#include "fmath.h"
#include <stdlib.h>
#include <string.h>
#include <memory.h>
#include <math.h>
#include "table.h"

inline uint32_t f2u(float x)
{
	uint32_t u;
	memcpy(&u, &x, 4);
	return u;
}

inline float u2f(uint32_t x)
{
	float f;
	memcpy(&f, &x, 4);
	return f;
}

inline uint32_t mask(uint32_t x)
{
	return (uint32_t(1) << x) - 1;
}

inline float vgetexpps(float x)
{
	return ((f2u(x) << 1) >> 24) - 127.f;
}

inline float vgetmantps(float x)
{
	return u2f((f2u(x) & 0x00ffffff) | f2u(1.0f));
}

extern "C" float fmath_logf(float x)
{
#if 0
#else
	float expo = vgetexpps(x);
	float mant = vgetmantps(x);
#endif
	const float ROUND = 1<<(23-logc_L);//0x1.p+20f;
	const float BOUND = 1.5f - 1.0f/(1<<(logc_L+1)); // 23/16=1+1/2-1/16
	uint32_t idx = f2u(mant + ROUND) & mask(logc_L);
	if (mant >= BOUND) {
		expo += 1.0f;
		mant *= 0.5f;
	}

	float invs = logc_tbl[idx].inv;
	float t    = fma(mant, invs, -1.0f);
	float logs = logc_tbl[idx].mlog;

#if logc_L == 3
	float A = -.4999993134703166062199020;
	float B = .3333377208103342588645233;
	float C = -.2507196324449547040133221;
	float D = .1983421366559079527220503;
	float poly = fma(fma(fma(fma(D, t, C), t, B), t, A), t, 1.0f);
#else
	float A = -.5000027035498107640250172;
	float B = .3333281180811569374969424;
	float poly = fma(fma(B, t, A), t, 1.0f);
#endif
	const float log2 = 0x1.62e430p-1f;
	float ret  = fma(poly, t, fma(expo, log2, logs));
	return ret;
}


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

