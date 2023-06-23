from s_xbyak import *
import math
import argparse

SIMD_BYTE = 64

# expand args
# Unroll(2, op, [xm0, xm1], [xm2, xm3], xm4)
# -> op(xm0, xm2, xm4)
#    op(xm1, xm3, xm4)
def Unroll(n, op, *args, addrOffset=None):
  xs = list(args)
  for i in range(n):
    ys = []
    for e in xs:
      if isinstance(e, list):
        ys.append(e[i])
      elif isinstance(e, Address):
        if addrOffset == None:
          if e.broadcast:
            addrOffset = 0
          else:
            addrOffset = SIMD_BYTE
        ys.append(e + addrOffset*i)
      else:
        ys.append(e)
    op(*ys)

def genUnrollFunc(n):
  """
    return a function takes op and outputs a function that takes *args and outputs n unrolled op
  """
  def fn(op, addrOffset=None):
    def gn(*args):
      Unroll(n, op, *args, addrOffset=addrOffset)
    return gn
  return fn

def zipOr(v, k):
  """
    return [v[i]|v[i]]
  """
  r = []
  for i in range(len(v)):
    r.append(v[i]|k[i])
  return r

def setInt(r, v):
  mov(eax, v)
  vpbroadcastd(r, eax)

def setFloat(r, v):
  setInt(r, float2uint(v))

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

  align(32)
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

  align(32)
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

class Counter:
  def __init__(self):
    self.c = 0
  def set(self, c):
    self.c = c
  def add(self, v):
    self.c += v
  def get(self):
    return self.c

  def __enter__(self):
    self.keep = self.c
    return self
  def __exit__(self, ex_type, ex_value, trace):
    self.c = self.keep

class Algo:
  def __init__(self, unrollN, mode):
    self.unrollN = unrollN
    self.mode = mode
    self.tmpRegN = 0 # # of temporary registers
    self.constRegN = 0 # # of constant (permanent) registers
    self.tmpCurPos = Counter() # position of current tmp regs

  def setTmpRegN(self, tmpRegN):
    self.tmpRegN = tmpRegN

  def setConstRegN(self, constRegN):
    self.constRegN = constRegN

  def getTotalRegN(self):
    return self.tmpRegN * self.unrollN + self.constRegN

  def getTmpRegs(self, sf, idx):
    """
    get idx-th (unrollN elements) tmp regs
    """
    if 0 <= idx < self.tmpRegN:
      return sf.v[idx*self.unrollN:(idx+1)*self.unrollN]
    else:
      raise Exception('bad idx', idx, self.tmpRegN)

  def allocTmpRegs(self):
    r = self.getTmpRegs(self.sf, self.tmpCurPos.get())
    self.tmpCurPos.add(1)
    return r

  def getMaskRegs(self, n):
    """
    get n elements mask regs
    v0 is not exists and v1 is reserved, so idx begins with number 2
    """
    vk = []
    for i in range(self.unrollN):
      vk.append(MaskReg(i+2))
    return vk

# exp_v(float *dst, const float *src, size_t n);
class ExpGen(Algo):
  def __init__(self, unrollN, mode):
    super().__init__(unrollN, mode)
    self.setTmpRegN(3)
    self.EXP_COEF_N = 6
    self.setConstRegN(self.EXP_COEF_N + 1) # coeff[], log2_e

  def data(self):
    align(32)

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
    makeLabel(self.EXP_COEF)
    for v in self.expTbl:
      dd_(hex(float2uint(v)))

  def expCore(self, n, args):
    (v0, v1, v2) = args
    un = genUnrollFunc(n)
    un(vmulps)(v0, v0, self.log2_e)
    un(vreduceps)(v1, v0, 0) # a = x - n
    un(vsubps)(v0, v0, v1) # n = x - a = round(x)

    un(vmovaps)(v2, self.expCoeff[5])
    for i in range(4, -1, -1):
      un(vfmadd213ps)(v2, v1, self.expCoeff[i])
    un(vscalefps)(v0, v2, v0) # v2 * 2^n

  def code(self):
    unrollN = self.unrollN
    align(16)
    with FuncProc('fmath_expf_avx512'):
      with StackFrame(3, 1, useRCX=True, vNum=self.getTotalRegN(), vType=T_ZMM) as sf:
        self.sf = sf
        dst = sf.p[0]
        src = sf.p[1]
        n = sf.p[2]
        v0 = self.getTmpRegs(sf, 0)
        v1 = self.getTmpRegs(sf, 1)
        v2 = self.getTmpRegs(sf, 2)
        constPos = self.tmpRegN*unrollN
        self.expCoeff = sf.v[constPos:constPos+self.EXP_COEF_N]
        self.log2_e = sf.v[constPos+self.EXP_COEF_N]

        setFloat(self.log2_e, 1/math.log(2))
        for i in range(self.EXP_COEF_N):
          vbroadcastss(self.expCoeff[i], ptr(rip + self.EXP_COEF + 4 * i))

        framework(self.expCore, dst, src, n, unrollN, (v0, v1, v2))

# log_v(float *dst, const float *src, size_t n);
class LogGen(Algo):
  def __init__(self, unrollN, mode):
    super().__init__(unrollN, mode)
    self.precise = True
    self.checkSign = False # return -Inf for 0 and NaN for negative
    self.L = 4 # table bit size (4 or 5)
    self.deg = 4 # degree of poly (4 or 3)
    tmpRegN = 4
    if self.precise:
      tmpRegN += 1
    constRegN = 5 # tbl1, tbl2, t, one, c[deg]
    if self.L == 5:
      constRegN += 2 # tbl1H, tbl2H
    self.setTmpRegN(tmpRegN)
    self.setConstRegN(constRegN)
  def data(self):
    align(32)
    self.LOG_COEF = 'log_coef'
    makeLabel(self.LOG_COEF)
    if self.deg == 3:
      self.ctbl = [1.0, -0.50004360205995410, 0.3333713161833]
    else:
      self.ctbl = [1.0, -0.49999999, 0.3333955701, -0.25008487]
# self.ctbl = [1.0, -0.4999999964869, 0.3333713161833, -0.250051797]
    for v in self.ctbl:
      dd_(hex(float2uint(v)))

    self.LOG2 = 'log2'
    makeLabel(self.LOG2)
    dd_(hex(float2uint(math.log(2))))

    self.C_0x7fffffff = 'abs_mask'
    makeLabel(self.C_0x7fffffff)
    dd_(hex(0x7fffffff))

    self.BOUNDARY = 'log_boundary'
    makeLabel(self.BOUNDARY)
    if self.L == 4:
      bound = 0.02
    else:
      bound = 0.01
    dd_(hex(float2uint(bound)))

    self.NaN = 'log_nan'
    makeLabel(self.NaN)
    dd_(hex(0x7fc00000))
    self.mInf = 'log_mInf'
    makeLabel(self.mInf)
    dd_(hex(0xff800000))

    self.logTbl1 = []
    self.logTbl2 = []
    LN = 1 << self.L
    for i in range(LN):
      u = (127 << 23) | ((i*2+1) << (23 - self.L - 1))
      v = 1 / uint2float(u)
      v = uint2float(float2uint(v)) # enforce C float type instead of double
      # v = numpy.float32(v)
      self.logTbl1.append(v)
      self.logTbl2.append(math.log(v))
    self.LOG_TBL1 = 'log_tbl1'
    self.LOG_TBL2 = 'log_tbl2'
    makeLabel(self.LOG_TBL1)
    for i in range(LN):
      dd_(hex(float2uint(self.logTbl1[i])))
    makeLabel(self.LOG_TBL2)
    for i in range(LN):
      dd_(hex(float2uint(self.logTbl2[i])))

  """
  x = 2^n a (1 <= a < 2)
  log x = n * log2 + log a
  L = 4
  d = (f2u(a) & mask(23)) >> (23 - L)
  b = T1[d] = approximate of 1/a
  log b = T2[d]
  c = ab - 1 is near zero
  a = (1 + c) / b
  log a = log(1 + c) - log b
  """
  def logCore(self, n, args):
    with self.tmpCurPos:

      v0 = self.allocTmpRegs()
      v1 = self.allocTmpRegs()
      v2 = self.allocTmpRegs()
      v3 = self.allocTmpRegs()
      t = self.t
      un = genUnrollFunc(n)
      if self.precise:
        keepX = self.allocTmpRegs()
        un(vmovaps)(keepX, v0)

      un(vgetexpps)(v1, v0) # n
      un(vgetmantps)(v0, v0, 0) # a
      un(vpsrad)(v2, v0, 23 - self.L) # d

      if self.L == 4:
        un(vpermps)(v3, v2, self.tbl1) # b
        un(vfmsub213ps)(v0, v3, self.one) # c = a * b - 1
        un(vpermps)(v3, v2, self.tbl2) # log_b
      elif self.L == 5:
        un(vmovaps)(v3, v2)
        un(vpermi2ps)(v2, self.tbl1, self.tbl1H) # b
        un(vfmsub213ps)(v0, v2, self.one) # c = a * b - 1
        un(vpermi2ps)(v3, self.tbl2, self.tbl2H) # log_b

      un(vfmsub132ps)(v1, v3, ptr_b(rip+self.LOG2)) # z = n * log2 - log_b

      # precise log for small |x-1|
      if self.precise:
        vk = self.getMaskRegs(self.unrollN)
        un(vsubps)(v2, keepX, self.one) # x-1
        un(vandps)(v3, v2, ptr_b(rip+self.C_0x7fffffff)) # |x-1|
        un(vcmpltps)(vk, v3, ptr_b(rip+self.BOUNDARY))
        un(vmovaps)(zipOr(v0, vk), v2) # c = v0 = x-1
        un(vxorps)(zipOr(v1, vk), v1, v1) # z = 0

      un(vmovaps)(v2, self.c3)
      if self.deg == 4:
        un(vfmadd213ps)(v2, v0, ptr_b(rip+self.LOG_COEF+2*4)) # t = c4 * v0 + c3
      un(vfmadd213ps)(v2, v0, ptr_b(rip+self.LOG_COEF+1*4)) # t = t * v0 + c2
      un(vfmadd213ps)(v2, v0, self.one) # t = t * v0 + 1
      un(vfmadd213ps)(v0, v2, v1) # v0 = v0 * t + z

      if self.checkSign:
        # check x < 0 or x == 0
        NEG = 1 << 6
        ZERO = (1 << 1) | (1 << 2)
        un(vfpclassps)(vk, keepX, NEG)
        un(vblendmps)(zipOr(v0, vk), v0, ptr_b(rip+self.NaN))
        un(vfpclassps)(vk, keepX, ZERO)
        un(vblendmps)(zipOr(v0, vk), v0, ptr_b(rip+self.mInf))

  def code(self):
    unrollN = self.unrollN
    tmpN = self.tmpRegN
    align(16)
    with FuncProc('fmath_logf_avx512'):
      with StackFrame(3, 1, useRCX=True, vNum=tmpN*unrollN+self.constRegN, vType=T_ZMM) as sf:
        self.sf = sf
        dst = sf.p[0]
        src = sf.p[1]
        n = sf.p[2]
        v0 = self.getTmpRegs(sf, 0)
        v1 = self.getTmpRegs(sf, 1)
        v2 = self.getTmpRegs(sf, 2)
        v3 = self.getTmpRegs(sf, 3)
        vk = []
        if self.precise:
          keepX = self.getTmpRegs(sf, 4)
        else:
          keepX = []
        constPos = tmpN*unrollN
        self.one = sf.v[constPos]
        self.tbl1 = sf.v[constPos+1]
        self.tbl2 = sf.v[constPos+2]
        self.t = sf.v[constPos+3]
        setFloat(self.one, 1.0)
        self.c3 = sf.v[constPos+4]
        setFloat(self.c3, self.ctbl[self.deg - 1])
        vmovups(self.tbl1, ptr(rip + self.LOG_TBL1))
        vmovups(self.tbl2, ptr(rip + self.LOG_TBL2))
        if self.L == 5:
          self.tbl1H = sf.v[constPos+5]
          self.tbl2H = sf.v[constPos+6]
          vmovups(self.tbl1H, ptr(rip + self.LOG_TBL1 + 64))
          vmovups(self.tbl2H, ptr(rip + self.LOG_TBL2 + 64))

        framework(self.logCore, dst, src, n, unrollN, (v0, v1, v2, v3, keepX))

def main():
  parser = getDefaultParser()
  parser.add_argument('-exp_un', '--exp_unrollN', help='number of unroll exp', type=int, default=7)
  parser.add_argument('-exp_mode', '--exp_mode', help='exp mode', type=str, default='allreg')
  parser.add_argument('-log_un', '--log_unrollN', help='number of unroll log', type=int, default=4)
  parser.add_argument('-log_mode', '--log_mode', help='log mode', type=str, default='allreg')
  global param
  param = parser.parse_args()

  init(param)
  exp = ExpGen(param.exp_unrollN, param.exp_mode)
  log = LogGen(param.log_unrollN, param.log_mode)
  segment('data')
  exp.data()
  log.data()

  segment('text')
  exp.code()
  log.code()

  term()

if __name__ == '__main__':
  main()
