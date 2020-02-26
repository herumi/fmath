#pragma once
/**
	@author herumi
	@note modified new BSD license
	http://opensource.org/licenses/BSD-3-Clause
*/
#include <xbyak/xbyak_util.h>
#include <cmath>

namespace fmath {

namespace local {

union fi {
	float f;
	uint32_t i;
};

inline float cvt(uint32_t x)
{
	fi fi;
	fi.i = x;
	return fi.f;
}

struct ConstVar {
	static const size_t expN = 5;
	static const size_t logN = 4;
	float expMin; // exp(expMin) = 0
	float expMax; // exp(expMax) = inf
	float log2; // log(2)
	float log2_e; // log_2(e) = 1 / log2
	float expCoeff[expN]; // near to 1/(i + 1)!
	float log2div2; // log(2)/2
	float sqrt2;
	float logCoeff[logN];
	void init()
	{
		expMin = cvt(0xc2aeac50);
		expMax = cvt(0x42b17218);
		log2 = std::log(2.0f);
		log2_e = 1.0f / log2;
		log2div2 = log2 / 2;
		sqrt2 = std::sqrt(2.0f);
#if 0
		// maxe=4.888831e-06
		float z = 1;
		for (size_t i = 0; i < expN; i++) {
			expCoeff[i] = z;
			z /= (i + 2);
		}
#else
		// maxe=1.938668e-06
		const uint32_t expTbl[expN] = {
			0x3f800000,
			0x3effff12,
			0x3e2aaa56,
			0x3d2b89cc,
			0x3c091331,
		};
		for (size_t i = 0; i < expN; i++) {
			expCoeff[i] = cvt(expTbl[i]);
		}
#endif
		const float logTbl[logN] = {
			0.9999999968719069552145263001550,
			0.3333347422539786943017443341906,
			0.1998289745987578035122400619786,
			0.1505016409143539640686624507163,
		};
		for (size_t i = 0; i < logN; i++) {
			logCoeff[i] = logTbl[i] * 2;
		}
	}
};

/*
The constans expCoeff are generated by Maple.
f := x->A+B*x+C*x^2+D*x^3+E*x^4+F*x^5;
g:=int((f(x)-exp(x))^2,x=-L..L);
sols:=solve({diff(g,A)=0,diff(g,B)=0,diff(g,C)=0,diff(g,D)=0,diff(g,E)=0,diff(g,F)=0},{A,B,C,D,E,F});
Digits:=1000;
s:=eval(sols,L=log(2)/2);
evalf(s,20);
*/
struct Code : public Xbyak::CodeGenerator {
	typedef Xbyak::Zmm Zmm;
	Xbyak::util::Cpu cpu;
	ConstVar *constVar;
	typedef void (*VecFunc)(float *dst, const float *src, size_t n);
	VecFunc expf_v;
	VecFunc logf_v;
	Code()
		: Xbyak::CodeGenerator(4096 * 2, Xbyak::DontSetProtectRWE)
		, expf_v(0)
		, logf_v(0)
	{
		if (!cpu.has(Xbyak::util::Cpu::tAVX512F)) {
			fprintf(stderr, "AVX-512 is not supported\n");
			return;
		}
		size_t dataSize = sizeof(ConstVar);
		dataSize = (dataSize + 4095) & ~size_t(4095);
		Xbyak::Label constVarL = L();
		constVar = (ConstVar*)getCode();
		constVar->init();
		setSize(dataSize);
		expf_v = getCurr<VecFunc>();
		genExp(constVarL);
		align(16);
		logf_v = getCurr<VecFunc>();
		genLog(constVarL);
		setProtectModeRE();
	}
	~Code()
	{
		setProtectModeRW();
	}
	// zm0 = exp(zm0)
	// use zm0, zm1, zm2
	void genExpOne(const Zmm& i127, const Zmm& expMin, const Zmm& expMax, const Zmm& log2, const Zmm& log2_e, const Zmm expCoeff[5])
	{
		vminps(zm0, expMax);
		vmaxps(zm0, expMin);
		vmulps(zm0, log2_e);
#if 1
		// a little faster if we can assume nearest round mode
		vcvtps2dq(zm1, zm0);
		vcvtdq2ps(zm2, zm1);
		vsubps(zm0, zm2);
#else
		vrndscaleps(zm1, zm0, 0); // n = round(x)
		vsubps(zm0, zm1); // a
		vcvtps2dq(zm1, zm1);
#endif
		vmulps(zm0, log2);
		vpaddd(zm1, zm1, i127);
		vpslld(zm1, zm1, 23); // fi.f
		vmovaps(zm2, expCoeff[4]);
		vfmadd213ps(zm2, zm0, expCoeff[3]);
		vfmadd213ps(zm2, zm0, expCoeff[2]);
		vfmadd213ps(zm2, zm0, expCoeff[1]);
		vfmadd213ps(zm2, zm0, expCoeff[0]);
		vfmadd213ps(zm2, zm0, expCoeff[0]);
		vmulps(zm0, zm2, zm1);
	}
	// exp_v(float *dst, const float *src, size_t n);
	void genExp(const Xbyak::Label& constVarL)
	{
		const int keepRegN = 7;
		using namespace Xbyak;
		util::StackFrame sf(this, 3, util::UseRCX, 64 * keepRegN);
		const Reg64& dst = sf.p[0];
		const Reg64& src = sf.p[1];
		const Reg64& n = sf.p[2];

		// prolog
#ifdef XBYAK64_WIN
		vmovups(ptr[rsp + 64 * 0], zm6);
		vmovups(ptr[rsp + 64 * 1], zm7);
#endif
		for (int i = 2; i < keepRegN; i++) {
			vmovups(ptr[rsp + 64 * i], Zmm(i + 6));
		}

		// setup constant
		const Zmm& i127 = zmm3;
		const Zmm& expMin = zmm4;
		const Zmm& expMax = zmm5;
		const Zmm& log2 = zmm6;
		const Zmm& log2_e = zmm7;
		const Zmm expCoeff[] = { zmm8, zmm9, zmm10, zmm11, zmm12 };
		mov(eax, 127);
		vpbroadcastd(i127, eax);
		lea(rax, ptr[rip+constVarL]);
		vbroadcastss(expMin, ptr[rax + offsetof(ConstVar, expMin)]);
		vbroadcastss(expMax, ptr[rax + offsetof(ConstVar, expMax)]);
		vbroadcastss(log2, ptr[rax + offsetof(ConstVar, log2)]);
		vbroadcastss(log2_e, ptr[rax + offsetof(ConstVar, log2_e)]);
		for (size_t i = 0; i < ConstVar::expN; i++) {
			vbroadcastss(expCoeff[i], ptr[rax + offsetof(ConstVar, expCoeff[0]) + sizeof(float) * i]);
		}

		// main loop
		Label mod16, exit;
		mov(ecx, n);
		and_(n, ~15);
		jz(mod16);
	Label lp = L();
		vmovups(zm0, ptr[src]);
		add(src, 64);
		genExpOne(i127, expMin, expMax, log2, log2_e, expCoeff);
		vmovups(ptr[dst], zm0);
		add(dst, 64);
		sub(n, 16);
		jnz(lp);
	L(mod16);
		and_(ecx, 15);
		jz(exit);
		mov(eax, 1);
		shl(eax, cl);
		sub(eax, 1);
		kmovd(k1, eax);
		vmovups(zm0|k1|T_z, ptr[src]);
		genExpOne(i127, expMin, expMax, log2, log2_e, expCoeff);
		vmovups(ptr[dst]|k1, zm0|k1);
	L(exit);
		// epilog
#ifdef XBYAK64_WIN
		vmovups(zm6, ptr[rsp + 64 * 0]);
		vmovups(zm7, ptr[rsp + 64 * 1]);
#endif
		for (int i = 2; i < keepRegN; i++) {
			vmovups(Zmm(i + 6), ptr[rsp + 64 * i]);
		}
	}
	// out = 1/in
	void inverse(const Zmm& out, const Zmm& in, const Zmm& t)
	{
		assert(!(out == in && in == t));
		/*
			t = rcp(x)
			1/x = 2 * t - x t^2
		*/
		vrcp14ps(t, in);
		vaddps(out, t, t);
		vmulps(t, t, t);
		vmulps(t, t, in);
		vsubps(out, out, t);
	}
	// out = -1/in
	void inverseNeg(const Zmm& out, const Zmm& in, const Zmm& t)
	{
		assert(!(out == in && in == t));
		/*
			t = rcp(x)
			1/x = -(x t^2 - 2t)
		*/
		vrcp14ps(out, in);
		vaddps(t, out, out);
		vmulps(out, out, out);
		vfmsub213ps(out, in, t);
	}
	// zm0 = log(zm0)
	// use zm0, zm1, zm2
	void genLogOne(const Zmm& t1, const Zmm& t2, const Zmm& i127shl23, const Zmm& x7fffff, const Zmm& sqrt2, const Zmm& log2, const Zmm& log2div2, const Zmm *logCoeff)
	{
		vpsubd(zm1, zm0, i127shl23);
		vpsrad(zm1, zm1, 23); // e
		vcvtdq2ps(zm1, zm1); // float(e)
		vpandd(zm0, zm0, x7fffff);
		vpord(zm0, zm0, i127shl23); // y

		vaddps(zm2, zm0, sqrt2); // y + sqrt2
		inverseNeg(t1, zm2, t2); // t1 = -1/zm2
		vfmadd213ps(zm1, log2, log2div2); // e

		vsubps(zm0, sqrt2, zm0); // sqrt2 - y

		vmulps(zm2, zm0, t1); // a = (y - sqrt2) / (y + sqrt2)
		vmulps(t1, zm2, zm2); // b
		vmovaps(zm0, logCoeff[3]);
		vfmadd213ps(zm0, t1, logCoeff[2]);
		vfmadd213ps(zm0, t1, logCoeff[1]);
		vfmadd213ps(zm0, t1, logCoeff[0]);
		vfmadd213ps(zm0, zm2, zm1);
	}
	// log_v(float *dst, const float *src, size_t n);
	void genLog(const Xbyak::Label& constVarL)
	{
		const int keepRegN = 8;
		using namespace Xbyak;
		util::StackFrame sf(this, 3, util::UseRCX, 64 * keepRegN);
		const Reg64& dst = sf.p[0];
		const Reg64& src = sf.p[1];
		const Reg64& n = sf.p[2];

		// prolog
#ifdef XBYAK64_WIN
		vmovups(ptr[rsp + 64 * 0], zm6);
		vmovups(ptr[rsp + 64 * 1], zm7);
#endif
		for (int i = 2; i < keepRegN; i++) {
			vmovups(ptr[rsp + 64 * i], Zmm(i + 6));
		}

		// setup constant
		const Zmm& i127shl23 = zmm3;
		const Zmm& x7fffff = zmm4;
		const Zmm& sqrt2 = zmm5;
		const Zmm& log2 = zmm6;
		const Zmm& log2div2 = zmm7;
		const Zmm logCoeff[] = { zmm8, zmm9, zmm10, zmm11 };
		const Zmm& t1 = zmm12;
		const Zmm& t2 = zmm13;
		mov(eax, 127 << 23);
		vpbroadcastd(i127shl23, eax);
		mov(eax, 0x7fffff);
		vpbroadcastd(x7fffff, eax);

		lea(rax, ptr[rip+constVarL]);
		vbroadcastss(sqrt2, ptr[rax + offsetof(ConstVar, sqrt2)]);
		vbroadcastss(log2, ptr[rax + offsetof(ConstVar, log2)]);
		vbroadcastss(log2div2, ptr[rax + offsetof(ConstVar, log2div2)]);
		for (size_t i = 0; i < ConstVar::logN; i++) {
			vbroadcastss(logCoeff[i], ptr[rax + offsetof(ConstVar, logCoeff[0]) + sizeof(float) * i]);
		}

		// main loop
		Label mod16, exit;
		mov(ecx, n);
		and_(n, ~15);
		jz(mod16, T_NEAR);
	Label lp = L();
		vmovups(zm0, ptr[src]);
		add(src, 64);
		genLogOne(t1, t2, i127shl23, x7fffff, sqrt2, log2, log2div2, logCoeff);
		vmovups(ptr[dst], zm0);

		add(dst, 64);
		sub(n, 16);
		jnz(lp);
	L(mod16);
		and_(ecx, 15);
		jz(exit, T_NEAR);
		mov(eax, 1);
		shl(eax, cl);
		sub(eax, 1);
		kmovd(k1, eax);
		vmovups(zm0|k1|T_z, ptr[src]);
		genLogOne(t1, t2, i127shl23, x7fffff, sqrt2, log2, log2div2, logCoeff);
		vmovups(ptr[dst]|k1, zm0|k1);
	L(exit);

		// epilog
#ifdef XBYAK64_WIN
		vmovups(zm6, ptr[rsp + 64 * 0]);
		vmovups(zm7, ptr[rsp + 64 * 1]);
#endif
		for (int i = 2; i < keepRegN; i++) {
			vmovups(Zmm(i + 6), ptr[rsp + 64 * i]);
		}
	}
};

template<size_t dummy = 0>
struct Inst {
	static const Code code;
};

template<size_t dummy>
MIE_ALIGN(32) const Code Inst<dummy>::code;

} // fmath::local

inline float split(int *pn, float x)
{
	int n;
	if (x >= 0) {
		n = int(x + 0.5f);
	} else {
		n = int(x - 0.5f);
	}
	*pn = n;
	return x - n;
}

inline float expfC(float x)
{
	const local::ConstVar& C = *local::Inst<>::code.constVar;
	x = (std::min)(x, C.expMax);
	x = (std::max)(x, C.expMin);
	x *= C.log2_e;
	int n;
	float a = split(&n, x);
	/* |a| <= 0.5 */
	a *= C.log2;
	/* |a| <= 0.3466 */
	local::fi fi;
	fi.i = (n + 127) << 23; // 2^n
	/*
		e^a = 1 + a + a^2/2! + a^3/3! + a^4/4! + a^5/5!
		= 1 + a(1 + a(1/2! + a(1/3! + a(1/4! + a/5!))))
	*/
	x = C.expCoeff[4];
	x = a * x + C.expCoeff[3];
	x = a * x + C.expCoeff[2];
	x = a * x + C.expCoeff[1];
	x = a * x + C.expCoeff[0];
	x = a * x + C.expCoeff[0];
	return x * fi.f;
}

inline float logfC(float x)
{
	const local::ConstVar& C = *local::Inst<>::code.constVar;
	local::fi fi;
	fi.f = x;
	float e = (int(fi.i - (127 << 23))) >> 23;
	fi.i = (fi.i & 0x7fffff) | (127 << 23);
	float y = fi.f;
	/*
		x = y * 2^e (1 <= y < 2)
		log(x) = e log2 + log y
		a = (y - sqrt(2)) / (y + sqrt(2))
		|a| <= (sqrt(2) - 1)/(sqrt(2) + 1)
		y = sqrt(2) (1+a)/(1-a)
		log(x) = e log2 + 1/2 log 2 + log((1+a)/(1-a))
		log((1+a)/(1-a)) = 2a(1 + a^2/3 + a^4/5 + a^6/7)
		b = a^2
		log(x) = (e+1/2) log2 + 2a(1 + b(1/3 + b(1/5 + b/7)))
	*/
	float a = (y - C.sqrt2) / (y + C.sqrt2);
	e = C.log2 * e + C.log2div2;
	float b = a * a;
	x = C.logCoeff[3];
	x = b * x + C.logCoeff[2];
	x = b * x + C.logCoeff[1];
	x = b * x + C.logCoeff[0];
	x *= a;
	x += e;
	return x;
}

inline void expf_v(float *dst, const float *src, size_t n)
{
	local::Inst<>::code.expf_v(dst, src, n);
}

inline void logf_v(float *dst, const float *src, size_t n)
{
	local::Inst<>::code.logf_v(dst, src, n);
}

} // fmath2
