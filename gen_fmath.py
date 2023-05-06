from s_xbyak import *
import math
import argparse

LOG_2 = 'log2'
LOG2_E = 'log2_e'
EXP_COEF = 'exp_coef'
EXP_COEF_N = 5
EXP_CONST_N = EXP_COEF_N + 2 # coeff[], log2, log2_e
EXP_TMP_N = 3
EXP_UNROLL = 4

# expand args
# Loop(2, op, [xm0, xm1], [xm2, xm3], xm4)
# -> op(xm0, xm2, xm4)
#    op(xm1, xm3, xm4)
def Loop(n, op, *args):
  xs = list(args)
  for i in range(n):
    ys = []
    for e in xs:
      if isinstance(e, list):
        ys.append(e[i])
      else:
        ys.append(e)
    op(*ys)

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
    assert len(expTbl) == EXP_COEF_N
    makeLabel(EXP_COEF)
    for v in expTbl:
      dd_(hex(v))

  def genExpOneAVX512n(self, n, v0, v1, v2):
    Loop(n, vmulps, v0, v0, self.log2_e)
    Loop(n, vrndscaleps, v1, v0, 0) # n = round(x)
    Loop(n, vsubps, v0, v0, v1) # a = x - n
    Loop(n, vmulps, v0, v0, self.log2) # a *= log2
    Loop(n, vmovaps, v2, self.expCoeff[4])
    Loop(n, vfmadd213ps , v2, v0, self.expCoeff[3])
    Loop(n, vfmadd213ps , v2, v0, self.expCoeff[2])
    Loop(n, vfmadd213ps , v2, v0, self.expCoeff[1])
    Loop(n, vfmadd213ps , v2, v0, self.expCoeff[0])
    Loop(n, vfmadd213ps , v2, v0, self.expCoeff[0])
    Loop(n, vscalefps, v0, v2, v1) # v2 * 2^v1

  def genExpOneAVX512(self):
    self.genExpOneAVX512n(1, [zm0], [zm1], [zm2])

  def code(self):
    align(16)
    with FuncProc('fmath_exp_v_avx512'):
      with StackFrame(3, 1, useRCX=True, vNum=EXP_TMP_N*EXP_UNROLL+EXP_CONST_N, vType=T_ZMM) as sf:
        dst = sf.p[0]
        src = sf.p[1]
        n = sf.p[2]
        v0 = sf.v[0:EXP_UNROLL]
        v1 = sf.v[1*EXP_UNROLL:2*EXP_UNROLL]
        v2 = sf.v[2*EXP_UNROLL:3*EXP_UNROLL]
        constPos = EXP_TMP_N*EXP_UNROLL
        self.log2 = sf.v[constPos]
        self.log2_e = sf.v[constPos+1]
        self.expCoeff = sf.v[constPos+2:constPos+2+EXP_COEF_N]
        lea(rax, rip(LOG_2))
        vbroadcastss(self.log2, rip(LOG_2))
        vbroadcastss(self.log2_e, rip(LOG2_E))
        for i in range(EXP_COEF_N):
          vbroadcastss(self.expCoeff[i], rip(EXP_COEF + '+' + str(4 * i)))

        mod16L = Label()
        exitL = Label()
        lpL = Label()
        check1L = Label()
        check2L = Label()
        lpUnrollL = Label()

        mov(rcx, n)
        jmp(check1L)

        L(lpUnrollL)
        for i in range(EXP_UNROLL):
          vmovups(v0[i], ptr(src+64*i))
        add(src, 64*EXP_UNROLL)
        self.genExpOneAVX512n(EXP_UNROLL, v0, v1, v2)
        for i in range(EXP_UNROLL):
          vmovups(ptr(dst+64*i), v0[i])
        add(dst, 64*EXP_UNROLL)
        sub(n, 16*EXP_UNROLL)
        L(check1L)
        cmp(n, 16*EXP_UNROLL)
        jae(lpUnrollL)

        jmp(check2L)

        L(lpL)
        vmovups(zm0, ptr(src))
        add(src, 64)
        self.genExpOneAVX512()
        vmovups(ptr(dst), zm0)
        add(dst, 64)
        sub(n, 16)
        L(check2L)
        cmp(n, 16)
        jae(lpL)

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
