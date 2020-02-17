#include "fmath2.hpp"
//#include <cybozu/benchmark.hpp>

int main()
{
	float maxe = 0;
	for (float x = -30; x < 30; x += 1e-5) {
		float y1 = fmath2::expC(x);
		float y2 = std::exp(x);
		float e = std::abs(y1 - y2) / y1;
		if (e > maxe) {
			maxe = e;
		}
	}
	printf("maxe=%e\n", maxe);
}
