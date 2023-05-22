from s_xbyak import *
import math
import argparse

LOG2_E = 'log2_e'
SIMD_BYTE = 64

# expand args
# Unroll(2, op, [xm0, xm1], [xm2, xm3], xm4)
# -> op(xm0, xm2, xm4)
#    op(xm1, xm3, xm4)
def Unroll(n, op, *args, addrOffset=SIMD_BYTE):
  xs = list(args)
  for i in range(n):
    ys = []
    for e in xs:
      if isinstance(e, list):
        ys.append(e[i])
      elif isinstance(e, Address) and not e.broadcast:
        ys.append(e + addrOffset*i)
      else:
        ys.append(e)
    op(*ys)

def genUnrollFunc(n):
  """
    return a function takes op and outputs a function that takes *args and outputs n unrolled op
  """
  def fn(op, addrOffset=SIMD_BYTE):
    def gn(*args):
      Unroll(n, op, *args, addrOffset=addrOffset)
    return gn
  return fn

# generate a function of void (*f)(float *dst, const float *src, size_t n);
# dst : dst pointer register
# src : src pointer register
# n : size of array
# unrollN : number of unroll
# v0 = args[0] : input/output parameters
# args[1:] : temporary parameter
def framework(func, dst, src, n, unrollN, args):
  un = genUnrollFunc(unrollN)
  v0 = args[0]
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
  add(src, 64*unrollN)
  func(unrollN, args)
  un(vmovups)(ptr(dst), v0)
  add(dst, 64*unrollN)
  sub(n, 16*unrollN)
  L(check1L)
  cmp(n, 16*unrollN)
  jae(lpUnrollL)

  jmp(check2L)

  L(lpL)
  vmovups(zm0, ptr(src))
  add(src, 64)
  func(1, args)
  vmovups(ptr(dst), zm0)
  add(dst, 64)
  sub(n, 16)
  L(check2L)
  cmp(n, 16)
  jae(lpL)

  L(mod16L)
  and_(ecx, 15)
  jz(exitL)
  mov(eax, 1)    # eax = 1
  shl(eax, cl)   # eax = 1 << n
  sub(eax, 1)
  kmovd(k1, eax)
  vmovups(zm0|k1|T_z, ptr(src))
  func(1, args)
  vmovups(ptr(dst)|k1, zm0)
  L(exitL)

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
    self.expTbl = expTblMaple
    self.EXP_COEF = 'exp_coef'
    self.EXP_COEF_N = 6
    self.EXP_CONST_N = self.EXP_COEF_N + 1 # coeff[], log2_e
    assert len(self.expTbl) == self.EXP_COEF_N
    makeLabel(self.EXP_COEF)
    for v in self.expTbl:
      dd_(hex(float2uint32(v)))

  def expCore(self, n, args):
    (v0, v1, v2) = args
    un = genUnrollFunc(n)
    un(vmulps)(v0, v0, self.log2_e)
    un(vreduceps)(v1, v0, 0) # a = x - n
    un(vsubps)(v0, v0, v1) # n = x - a = round(x)

    un(vmovaps)(v2, self.expCoeff[5])
    for i in range(4, -1, -1):
      un(vfmadd213ps)(v2, v1, self.expCoeff[i])
    un(vscalefps)(v0, v2, v0) # v2 * 2^v1

  def code(self, param):
    EXP_TMP_N = 3
    unrollN = param.unroll
    align(16)
    with FuncProc('fmath_exp_v_avx512'):
      with StackFrame(3, 1, useRCX=True, vNum=EXP_TMP_N*unrollN+self.EXP_CONST_N, vType=T_ZMM) as sf:
        dst = sf.p[0]
        src = sf.p[1]
        n = sf.p[2]
        v0 = sf.v[0:unrollN]
        v1 = sf.v[1*unrollN:2*unrollN]
        v2 = sf.v[2*unrollN:3*unrollN]
        constPos = EXP_TMP_N*unrollN
        self.expCoeff = sf.v[constPos:constPos+self.EXP_COEF_N]
        self.log2_e = sf.v[constPos+self.EXP_COEF_N]
        vbroadcastss(self.log2_e, ptr(rip+LOG2_E))
        for i in range(self.EXP_COEF_N):
          vbroadcastss(self.expCoeff[i], ptr(rip + self.EXP_COEF + 4 * i))

        framework(self.expCore, dst, src, n, unrollN, (v0, v1, v2))

def main():
  parser = getDefaultParser()
  parser.add_argument('-un', '--unroll', help='number of unroll', type=int, default=4)
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
