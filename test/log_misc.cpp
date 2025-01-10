#include <stdio.h>
#include <memory.h>
#include <stdint.h>
#include <float.h>
#include <math.h>
#include <bit>
#include "fmath.h"
#include <cybozu/benchmark.hpp>
#include <cybozu/xorshift.hpp>
#include "reference.hpp"
//#include "../fmath_old.hpp"

inline float vpermps(float x, const float *tbl)
{
	return tbl[f2u(x) & 0xf];
}

float invs_table[16] = {
	0x1.000000p+0f, // 16/16
	0x1.e1e1e2p-1f, // 16/17
	0x1.c71c72p-1f, // 16/18
	0x1.af286cp-1f, // 16/19
	0x1.99999ap-1f, // 16/20
	0x1.861862p-1f, // 16/21
	0x1.745d18p-1f, // 16/22
	0x1.642c86p-1f, // 16/23
	0x1.555556p+0f, // 32/24
	0x1.47ae14p+0f, // 32/25
	0x1.3b13b2p+0f, // 32/26
	0x1.2f684cp+0f, // 32/27
	0x1.24924ap+0f, // 32/28
	0x1.1a7b96p+0f, // 32/29
	0x1.111112p+0f, // 32/30
	0x1.084550p+0f, // ~32/31
};
float logs_table[16] = {
	+0x0.000000p+0f,
	+0x1.f0a30ap-5f,
	+0x1.e27074p-4f,
	+0x1.5ff306p-3f,
	+0x1.c8ff7ap-3f,
	+0x1.1675cap-2f,
	+0x1.4618bap-2f,
	+0x1.739d7ep-2f,
	-0x1.269624p-2f,
	-0x1.f991c4p-3f,
	-0x1.a93ed8p-3f,
	-0x1.5bf408p-3f,
	-0x1.1178eep-3f,
	-0x1.9335e4p-4f,
	-0x1.08599ap-4f,
	-0x1.047a88p-5f,
};

float my_logf(float x)
{
	float expo = vgetexpps(x);
	float mant = vgetmantps(x);
	float idxf = mant + 0x1.p+19;
	if (mant >= 0x1.78p+0f) {
		expo += 1.0f;
		mant *= 0.5f;
	}

	float invs = vpermps(idxf, invs_table);
	float t    = fma(mant, invs, -1.0f);
	float logs = vpermps(idxf, logs_table);

	float poly = fma(fma(fma(-0x1.fe9d24p-3f, t, 0x1.557ee2p-2f), t, -0x1.00000cp-1f), t, 1.0f);
//    float log2 = log(2);
	const float log2 = 0x1.62e430p-1f;
	float ret  = fma(poly, t, fma(expo, log2, logs));
	return ret;
}

float vpermps2(float x, const float *tbl)
{
	return tbl[f2u(x) & 0x7];
}

#if 0
#define PUT(...) printf(__VA_ARGS__)
#else
#define PUT(...)
#endif

/*
f:=x->x+A*x^2+B*x^3+C*x^4+D*x^5;
g:=int((f(x)-log(1+x))^2,x=-0.5/9..0.5/8);
sols:= solve({diff(g,A)=0,diff(g,B)=0,diff(g,C)=0,diff(g,D)=0},{A,B,C,D});
Digits:=100;
s:=eval(sols);
evalf(s,25);
*/

void search()
{
	float mina = 0;
	double mind = 1;
	for (int i = 0; i < 1000; i++) {
		float a = u2f(f2u(32 / 31.) + i);
		double b = log(a);
		float c = b;
		double d = fabs(b - c);
		if (d < mind) {
			mina = a;
			mind = d;
		}
	}
	puts("search1");
	printf("mind=%e\n", mind);
	printf("a=%.6a -log(a)=%.6a\n", mina, -log(mina));
}

void search2()
{
	puts("search2");
	const int n = 8;
	puts("invs_table = [");
	for (int j = 0; j < n; j++) {
		float mina = 0;
		double mind = 1;
		float v = 1 + j / float(n);
		float a0 = j < n/2 ? 1/v : 2/v;
		for (int i = 0; i < 1000; i++) {
			float a = u2f(f2u(a0) + i);
			double b = logl(a);
			float c = b;
			double d = fabs(b - c);
			if (d < mind) {
				mina = a;
				mind = d;
			}

			a = u2f(f2u(a0) - i);
			b = logl(a);
			c = b;
			d = fabs(b - c);
			if (d < mind) {
				mina = a;
				mind = d;
			}
		}
		printf("%.6a,\n", mina);
	}
	puts("]");
}

/*
my_log(x) for x in [FLT_MIN, FLT_MAX]
eq= 2057411156
le1=  71155775
gt1=   2136209
le2=       655
gt2=      2632
err=         5

modify table2[7]
// [7] search by float a = u2f(f2u(16 / 15.) + i);
eq= 2057795224
le1=  70716460
gt1=   2191840
le2=       271
gt2=      2632
err=         5

// [7] search by float a = u2f(f2u(16 / 15.) - i);
eq= 2057795975
le1=  70716128
gt1=   2191421
le2=       271
gt2=      2632
err=         5

// [6] float a = u2f(f2u(16 / 14.) - i);
eq= 2057867299
le1=  70726581
gt1=   2109644
le2=       271
gt2=      2632
err=         5

// [6] float a = u2f(f2u(16 / 14.) + i);
eq= 2057866938
le1=  70726618
gt1=   2109968
le2=       271
gt2=      2632
err=         5

// [1] float a = u2f(f2u(8/9.) + i);
eq= 2058067311
le1=  70904393
gt1=   1732814
le2=      1878
gt2=        36
err=         0
minx=-0.055492(-0x1.c69788p-5) maxx=0.062500(0x1.000000p-4)
gcc
eq= 1594866282
le1= 301833446
gt1= 234004021
le2=      1764
gt2=       919
err=         0
*/
struct DiffCounter {
	uint32_t eq;
	uint32_t le1, le2, gt1, gt2;
	uint32_t err;
	DiffCounter()
		: eq(0), le1(0), le2(0), gt1(0), gt2(0), err(0) {}
	bool cmp(float x1, float x2)
	{
		uint32_t u1 = f2u(x1);
		uint32_t u2 = f2u(x2);
		if (u1 == u2) {
			eq++;
			return true;
		}
		if (u1 + 1 == u2) {
			le1++;
			return true;
		}
		if (u1 + 2 == u2) {
			le2++;
			return true;
		}
		if (u1 == u2 + 1) {
			gt1++;
			return true;
		}
		if (u1 == u2 + 2) {
			gt2++;
			return true;
		}
		err++;
		return false;
	}
	void put() const
	{
		printf("eq=% 10d\n", eq);
		printf("le1=% 10d\n", le1);
		printf("gt1=% 10d\n", gt1);
		printf("le2=% 10d\n", le2);
		printf("gt2=% 10d\n", gt2);
		printf("err=% 10d\n", err);
	}
};

void count(float stdf(float), void f(float *, const float *, size_t), uint32_t begin, uint32_t end)
{
	puts("count");
	DiffCounter dc;
	size_t remain = end - begin + 1;
	uint32_t u = begin;
	const size_t N = 4096;
	float xa[N], aa[N], ba[N];
	while (remain > 0) {
		size_t n = (std::min)(N, remain);
		for (size_t i = 0; i < n; i++) {
			xa[i] = u2f(u + i);
			aa[i] = stdf(xa[i]);
		}
		f(ba, xa, n);
		for (size_t i = 0; i < n; i++) {
			float x = xa[i];
			float a = aa[i];
			float b = ba[i];
			if (!dc.cmp(a, b)) {
				printf("u=%08x x=%f a=%f(%.6a) b=%f(%.6a) diff=%d\n", f2u(x), x, a, a, b, b, abs(int(f2u(a)) - int(f2u(b))));
			}
		}
		remain -= n;
		u += n;
	}
	dc.put();
}

/*
AVX-512 with gcc
eq= 1597497689
le1= 302549878
gt1= 230658864
le2=         0
gt2=         1
err=         0

AVX2 with Visual Studio
eq= 1594885605
le1= 301859683
gt1= 233959218
le2=      1891
gt2=        35
err=         0

AVX2 with gcc
eq= 1594866282
le1= 301833446
gt1= 234004021
le2=      1764
gt2=       919
err=         0
*/

void roundTest()
{
	puts("roundTest");
	printf("AAA=%f\n", u2f(0x3fb80000)*16);
	for (float x = 1; x < 2; x += 1/16.0) {
		float mant = vgetmantps(x);
		float idxf = x + 0x1.p+20;
		printf("x=%f(%08x:%.6a) mant=%f idx=%d %c\n", x, f2u(x), x, mant, f2u(idxf)&7, mant >= 0x1.78p+0f ? 'o' : '-');
	}
}

void bench()
{
	const int C = 1000000;
	{
		cybozu::CpuClock clk;
		cybozu::XorShift rg;
		float y = 0;
		for (int i = 0; i < C; i++) {
			uint32_t v = rg.get32() & 0x3fffffff;
			float x = u2f(v) + FLT_MIN;
			clk.begin();
			y += fmath_logfC(x);
			clk.end();
		}
		clk.put("fmath_logfC");
		printf("y=%e\n", y);
	}
	{
		cybozu::CpuClock clk;
		cybozu::XorShift rg;
		float y = 0;
		for (int i = 0; i < C; i++) {
			uint32_t v = rg.get32() & 0x3fffffff;
			float x = u2f(v) + FLT_MIN;
			clk.begin();
			y += logf(x);
			clk.end();
			x += 10.0/C;
		}
		clk.put("std::logf");
		printf("y=%e\n", y);
	}
#if 0
	{
		cybozu::CpuClock clk;
		cybozu::XorShift rg;
		float y = 0;
		for (int i = 0; i < C; i++) {
			uint32_t v = rg.get32() & 0x3fffffff;
			float x = u2f(v) + FLT_MIN;
			clk.begin();
			y += fmath_old::log(x);
			clk.end();
			x += 10.0/C;
		}
		clk.put("old::logf");
		printf("y=%e\n", y);
	}
#endif
}

void fmath_logfC_v(float *y, const float *x, size_t n)
{
	for (size_t i = 0; i < n; i++) {
		y[i] = fmath_logfC(x[i]);
	}
}

int main()
{
//	testNext();
	printf("half=%e %e\n", 0x1.8p+0, 0x1.78p+0);
	printf("log2=%.6a\n", log(2.0f));
//	search();
	search2();
	bench();
//	roundTest();
	puts("fmath::log");
	count(logf, fmath_logf_v, f2u(FLT_MIN), f2u(FLT_MAX));
#if 0
	puts("fmath_logfC");
	g_mint = 100;
	g_maxt = -100;
	count(logf, fmath_logfC_v, f2u(FLT_MIN), f2u(FLT_MAX));
	printf("g_mint=%f(%.6a) g_maxt=%f(%.6a)\n", g_mint, g_mint, g_maxt, g_maxt);
	// g_mint=-0.055492(-0x1.c69788p-5) g_maxt=0.062500(0x1.000000p-4)
#endif
}
