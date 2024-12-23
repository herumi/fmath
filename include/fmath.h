#pragma once
/**
	@author herumi
	@note modified new BSD license
	http://opensource.org/licenses/BSD-3-Clause
*/
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

void fmath_init(); // select AVX-512 functions if it is available

void fmath_expf_v_avx512(float *dst, const float *src, size_t n);
void fmath_logf_v_avx512(float *dst, const float *src, size_t n);

void fmath_expf_v_avx2(float *dst, const float *src, size_t n);
void fmath_logf_v_avx2(float *dst, const float *src, size_t n);

extern void (*fmath_expf_v)(float *dst, const float *src, size_t n);
extern void (*fmath_logf_v)(float *dst, const float *src, size_t n);

#ifdef __cplusplus
}
#endif

namespace fmath {

inline void init()
{
	fmath_init();
}

inline void expf_v(float *dst, const float *src, size_t n)
{
	fmath_expf_v(dst, src, n);
}

inline void logf_v(float *dst, const float *src, size_t n)
{
	fmath_logf_v(dst, src, n);
}

inline float expf(float x)
{
	float y;
	expf_v(&y, &x, 1);
	return y;
}

inline float logf(float x)
{
	float y;
	logf_v(&y, &x, 1);
	return y;
}

} // fmath

