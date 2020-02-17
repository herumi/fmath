#include <stdio.h>
#include <math.h>
#include <stdint.h>

union fi {
	float f;
	uint32_t i;
};

void put(uint32_t xi)
{
	fi fi;
	fi.i = xi;
	float x = fi.f;
	printf("%08x exp(%e:%a)=%e(:%a)\n", xi, x, x, exp(x), exp(x));
}

void putCoeff()
{
	float tbl[] = {
#if 0
		1.000000052276062585891237691455,
		1.000000028135653438688105542581,
		0.499990863829736189441620496800,
		0.166664559185089434903091818628,
		0.041894680057037697783306908441,
		0.008371908330155209697200274848,
#else
		1,
		1,
		0.499992894870871676569001141213,
/*
		0.166665402458828552475388469125,
		0.041879461611370920249584030398,
		0.008366392101059765345146428936,
*/
0.166665402458828552475600344586,
0.0418783362899079300060205008974,
0.00836639210105976534636108550722

#endif
	};
	for (int i = 0; i < 6; i++) {
		fi fi;
		fi.f = tbl[i];
		printf("%.7e %08x\n", fi.f, fi.i);
	}
}

int main()
{
	const uint32_t minx = 0xc2aeac50;
	const uint32_t maxx = 0x42b17218;
	uint32_t tbl[] = {
		minx + 1, minx, minx - 1, maxx - 1, maxx, maxx + 1
	};
	for (size_t i = 0; i < sizeof(tbl)/sizeof(tbl[0]); i++) {
		put(tbl[i]);
	}
	putCoeff();
}
