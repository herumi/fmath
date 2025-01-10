#pragma once

#include <bit>
#include "table.h"

inline uint32_t f2u(float x)
{
#if 1
	return std::bit_cast<uint32_t>(x);
#else
	uint32_t u;
	memcpy(&u, &x, 4);
	return u;
#endif
}

inline float u2f(uint32_t x)
{
#if 1
	return std::bit_cast<float>(x);
#else
	float f;
	memcpy(&f, &x, 4);
	return f;
#endif
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

float g_mint = 100;
float g_maxt = -100;

float fmath_logfC(float x)
{
	const float BOUND = 1.5f - 1.0f/(1<<(logc_L+1)); // 23/16=1+1/2-1/16
#if 1
	const float ROUND = 1<<(23-logc_L);//0x1.p+20f;
	float n = vgetexpps(x);
	float a = vgetmantps(x);
	uint32_t idx = f2u(a + ROUND) & mask(logc_L);
	if (a >= BOUND) {
        n += 1.0f;
        a *= 0.5f;
	}
#else
	// x = 2^n * a
	uint32_t u = f2u(x) & 0x7fffffff;
	int ni = (u >> 23) - 127;
	uint32_t ai = u & mask(23);
	uint32_t idx = ((ai + (1<<(22-logc_L))) >> (23-logc_L)) & mask(logc_L);
	uint32_t v = f2u(1.0f);
	if (ai >= (f2u(BOUND) & mask(23))) {
		ni++;
		v = f2u(0.5f);
	}
	float n = ni;
	float a = u2f(ai | v);
#endif

	float invs = logc_tbl[idx].inv;
	float t    = fma(a, invs, -1.0f);

if (t < g_mint) g_mint = t;
if (t > g_maxt) g_maxt = t;

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
	float ret  = fma(poly, t, fma(n, log2, logs));
	return ret;
}


