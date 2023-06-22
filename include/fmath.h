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

void fmath_expf_avx512(float *dst, const float *src, size_t n);
void fmath_logf_avx512(float *dst, const float *src, size_t n);

#ifdef __cplusplus
}
#endif

namespace fmath {

inline void expf_v(float *dst, const float *src, size_t n)
{
	fmath_expf_avx512(dst, src, n);
}

inline void logf_v(float *dst, const float *src, size_t n)
{
	fmath_logf_avx512(dst, src, n);
}

} // fmath

