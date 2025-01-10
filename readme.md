# Fast Approximation Functions for std::logf and std::expf Operations on Arrays

This library provides high-performance approximation functions for array operations involving logarithm (`std::logf`) and exponential (`std::expf`) calculations.
The implementation prioritizes speed while maintaining practical accuracy.

**Note**: This version is not backward compatible with previous releases.

## Core Functions

```cpp
void (*fmath_logf_v)(float *dst, const float *src, size_t n);
void (*fmath_expf_v)(float *dst, const float *src, size_t n);
```

### Parameters
- `dst`: Output array that stores the computed results `f(src[i])`
- `src`: Input array containing source values
- `n`: Array length (number of elements to process)

### Quick Start

```cpp
#include "fmath.h"

const size_t n = 1000;
float src[n] = {1.0f, 2.0f, 3.0f, /* ... */};
float dst[n];

fmath_init();  // Required initialization on Windows (It is automatically called on Linux)

// Calculate natural logarithm for array
fmath_logf_v(dst, src, n);  // dst[i] = log(src[i])

// Calculate exponential for array
fmath_expf_v(dst, src, n);  // dst[i] = exp(src[i])
```

## System Requirements

- x86-64 CPU with AVX2 support
- Automatically utilizes AVX-512 if available

## Performance Benchmarks

### Linux (Xeon w9-3495X w/ AVX-512)

| Function | fmath (clk) | std (clk) | Speedup |
|----------|-------------|-----------|---------|
| logf_v   | 6.72       | 105.20    | 15.7x   |
| expf_v   | 2.80       | 51.90     | 18.5x   |

### Windows (Core i7-1165G7 w/ AVX-512)

| Function | fmath (clk) | std (clk) | Speedup |
|----------|-------------|-----------|---------|
| logf_v   | 15.22      | 257.46    | 16.9x   |
| expf_v   | 6.29       | 123.02    | 19.5x   |

### Windows (Core  i7-1255U w/o AVX-512)

| Function | fmath (clk) | std (clk) | Speedup |
|----------|-------------|-----------|---------|
| logf_v   | 25.90       | 244.19    | 9.4x  |
| expf_v   | 8.76        | 112.71    | 12.9x   |

# License

- modified new BSD License
- http://opensource.org/licenses/BSD-3-Clause

# Author

MITSUNARI Shigeo(herumi@nifty.com)

# Support the Project
[GitHub Sponsor](https://github.com/sponsors/herumi)
