from s_xbyak import *
import math
import argparse

LOG2_E = 'log2_e'
EXP_COEF = 'exp_coef'
EXP_COEF_N = 6
EXP_CONST_N = EXP_COEF_N + 1 # coeff[], log2_e
EXP_TMP_N = 3
EXP_UNROLL = 4
SIMD_BYTE = 64

# expand args
# Unroll(2, op, [xm0, xm1], [xm2, xm3], xm4)
# -> op(xm0, xm2, xm4)
#    op(xm1, xm3, xm4)
def Unroll(n, op, *args):
  xs = list(args)
  for i in range(n):
    ys = []
    for e in xs:
      if isinstance(e, list):
        ys.append(e[i])
      elif isinstance(e, Address) and not e.broadcast:
        ys.append(e + SIMD_BYTE*i)
      else:
        ys.append(e)
    op(*ys)

def genUnrollFunc(n):
  """
    return a function takes op and outputs a function that takes *args and outputs n unrolled op
  """
  def fn(op):
    def gn(*args):
      Unroll(n, op, *args)
    return gn
  return fn

# exp_v(float *dst, const float *src, size_t n);
class ExpGen:
  def data(self):
    makeLabel(LOG2_E)
    v = 1 / math.log(2)
    dd_(hex(float2uint32(v)))

    # Approximate polynomial of degree 5 of 2^x in [-0.5, 0.5]
    expTblSollya = [
      1.0,
      0.69314697759916432673321,
      0.24022242085378028852993,
      5.55073374325413607111023e-2,
      9.67151263952592023243060e-3,
      1.32647271963665363408990e-3,
    ]
    expTblMaple = [
      1.0,
      0.69314720006209416366,
      0.24022309327839673134,
      0.55503406821502749265e-1,
      0.96672496496672653297e-2,
      0.13395279182003177132e-2,
    ]
    expTbl = expTblMaple
    assert len(expTbl) == EXP_COEF_N
    makeLabel(EXP_COEF)
    for v in expTbl:
      dd_(hex(float2uint32(v)))

  def genExpOneAVX512n(self, n, v0, v1, v2):
    un = genUnrollFunc(n)
    un(vmulps)(v0, v0, self.log2_e)
    un(vrndscaleps)(v1, v0, 0) # n = round(x)
    un(vsubps)(v0, v0, v1) # a = x - n

    un(vmovaps)(v2, self.expCoeff[5])
    for i in range(4, -1, -1):
      un(vfmadd213ps)(v2, v0, self.expCoeff[i])
    un(vscalefps)(v0, v2, v1) # v2 * 2^v1

  def genExpOneAVX512(self):
    self.genExpOneAVX512n(1, [zm0], [zm1], [zm2])

  def code(self, param):
    global EXP_UNROLL
    EXP_UNROLL = param.unroll
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
        self.expCoeff = sf.v[constPos:constPos+EXP_COEF_N]
        self.log2_e = sf.v[constPos+EXP_COEF_N]
        un = genUnrollFunc(EXP_UNROLL)
        vbroadcastss(self.log2_e, ptr(rip+LOG2_E))
        for i in range(EXP_COEF_N):
          vbroadcastss(self.expCoeff[i], ptr(rip + EXP_COEF + 4 * i))

        mod16L = Label()
        exitL = Label()
        lpL = Label()
        check1L = Label()
        check2L = Label()
        lpUnrollL = Label()

        mov(rcx, n)
        jmp(check1L)

        L(lpUnrollL)
        un(vmovups)(v0, ptr(src))
        add(src, 64*EXP_UNROLL)
        self.genExpOneAVX512n(EXP_UNROLL, v0, v1, v2)
        un(vmovups)(ptr(dst), v0)
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
  parser.add_argument('-un', '--unroll', help='number of unroll', type=int, default=1)
  global param
  param = parser.parse_args()

  init(param)
  exp = ExpGen()
  segment('data')
  exp.data()

  segment('text')
  exp.code(param)

  term()

if __name__ == '__main__':
  main()
