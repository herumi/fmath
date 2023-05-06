from s_xbyak import *
import math
import argparse

LOG_2 = 'log2'
LOG2_E = 'log2_e'
EXP_COEF = 'exp_coef'
EXP_N = 5

# exp_v(float *dst, const float *src, size_t n);
class ExpGen:
  def data(self):
    log2 = math.log(2)
    constTbl = [
      (LOG_2, log2),
      (LOG2_E, 1 / log2),
    ]
    for (name, v) in constTbl:
      makeLabel(name)
      dd_(hex(float2uint32(v)))

    expTbl = [
      0x3f800000,
      0x3effff12,
      0x3e2aaa56,
      0x3d2b89cc,
      0x3c091331,
    ]
    assert len(expTbl) == EXP_N
    makeLabel(EXP_COEF)
    for v in expTbl:
      dd_(hex(v))

  def genExpOneAVX512(self):
    vmulps(zm0, zm0, self.log2_e)
    vrndscaleps(zm1, zm0, 0) # n = round(x)
    vsubps(zm0, zm0, zm1) # a = x - n
    vmulps(zm0, zm0, self.log2) # a *= log2
    vmovaps(zm2, self.expCoeff[4])
    vfmadd213ps(zm2, zm0, self.expCoeff[3])
    vfmadd213ps(zm2, zm0, self.expCoeff[2])
    vfmadd213ps(zm2, zm0, self.expCoeff[1])
    vfmadd213ps(zm2, zm0, self.expCoeff[0])
    vfmadd213ps(zm2, zm0, self.expCoeff[0])
    vscalefps(zm0, zm2, zm1) # zm2 * 2^zm1

  def code(self):
    align(16)
    with FuncProc('fmath_exp_v_avx512'):
      with StackFrame(3, 1, useRCX=True, vNum=5+EXP_N, vType=T_ZMM) as sf:
        dst = sf.p[0]
        src = sf.p[1]
        n = sf.p[2]
        self.log2 = sf.v[3]
        self.log2_e = sf.v[4]
        self.expCoeff = sf.v[5:5+EXP_N]
        lea(rax, rip(LOG_2))
        vbroadcastss(self.log2, rip(LOG_2))
        vbroadcastss(self.log2_e, rip(LOG2_E))
        for i in range(EXP_N):
          vbroadcastss(self.expCoeff[i], rip(EXP_COEF + '+' + str(4 * i)))

        mod16L = Label()
        exitL = Label()
        lpL = Label()
        mov(rcx, n)
        and_(n, ~15)
        jz(mod16L)

        L(lpL)
        vmovups(zm0, ptr(src))
        add(src, 64)
        self.genExpOneAVX512()
        vmovups(ptr(dst), zm0)
        add(dst, 64)
        sub(n, 16)
        jnz(lpL)

        L(mod16L)
        and_(ecx, 15)
        jz(exitL)
        mov(eax, 1)
        shl(eax, cl)
        sub(eax, 1)
        kmovd(k1, eax)
        vmovups(zm0|k1|T_z, ptr(src))
        self.genExpOneAVX512()
        vmovups(ptr(dst)|k1, zm0)
        L(exitL)
        

def main():
  parser = getDefaultParser()
#  parser.add_argument('-n', '--num', help='max size of Unit', type=int, default=9)
  global param
  param = parser.parse_args()

  init(param)
  exp = ExpGen()
  segment('data')
  exp.data()

  segment('text')
  exp.code()

  term()

if __name__ == '__main__':
  main()
