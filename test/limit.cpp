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
		1,
		1,
		0.499992894870871676569001141213,
		0.166665402458828552475600344586,
		0.0418783362899079300060205008974,
		0.00836639210105976534636108550722
	};
	for (size_t i = 0; i < sizeof(tbl)/sizeof(tbl[0]); i++) {
		fi fi;
		fi.f = tbl[i];
		printf("%.7e 0x%08x,\n", fi.f, fi.i);
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
