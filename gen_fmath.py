from s_xbyak import *
import math
import argparse

LOG2_E = 'log2_e'
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

# exp_v(float *dst, const float *src, size_t n);
class ExpGen:
  def __init__(self, param):
    self.unrollN = param.exp_unrollN
    self.mode = param.exp_mode
  def data(self):
    makeLabel(LOG2_E)
    v = 1 / math.log(2)
    dd_(hex(float2uint(v)))

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

    if self.mode == 'allreg':
      self.EXP_COEF_N = 6
      self.EXP_CONST_N = self.EXP_COEF_N + 1 # coeff[], log2_e
    elif self.mode == 'allimm':
      self.EXP_COEF_N = 0
      self.EXP_CONST_N = 2 # coeff[], log2_e, tx
    elif self.mode == 'allimm2':
      self.EXP_COEF_N = 0
      self.EXP_CONST_N = 3 # coeff[], log2_e, tx, tx2
    else:
      self.EXP_COEF_N = 0
      self.EXP_CONST_N = 1 # log2_e

  def expCore(self, n, args):
    (v0, v1, v2) = args
    un = genUnrollFunc(n)
    un(vmulps)(v0, v0, self.log2_e)
    un(vreduceps)(v1, v0, 0) # a = x - n
    un(vsubps)(v0, v0, v1) # n = x - a = round(x)

    if self.mode == 'allreg':
      un(vmovaps)(v2, self.expCoeff[5])
      for i in range(4, -1, -1):
        un(vfmadd213ps)(v2, v1, self.expCoeff[i])
      un(vscalefps)(v0, v2, v0) # v2 * 2^v1

    if self.mode == 'allmem':
      lea(rax, ptr(rip+self.EXP_COEF))
      vpbroadcastd(v2[0], ptr(rax+5*4))
      for i in range(1, n):
        un(vmovaps)(v2[i], v2[0])
      for i in range(4, -1, -1):
        un(vfmadd213ps)(v2, v1, ptr_b(rax+i*4))
      un(vscalefps)(v0, v2, v0) # v2 * 2^v1

    if self.mode == 'allimm':
      mov(eax, float2uint(self.expTbl[5]))
      vpbroadcastd(v2[0], eax)
      for i in range(1, n):
        un(vmovaps)(v2[i], v2[0])

      for i in range(4, -1, -1):
        mov(eax, float2uint(self.expTbl[i]))
        vpbroadcastd(self.tx, eax)
        un(vfmadd213ps)(v2, v1, self.tx)
      un(vscalefps)(v0, v2, v0) # v2 * 2^v1

    if self.mode == 'allimm2':
      mov(eax, float2uint(self.expTbl[5]))
      vpbroadcastd(v2[0], eax)
      mov(eax, float2uint(self.expTbl[4]))
      vpbroadcastd(self.tx, eax)
      for i in range(1, n):
        un(vmovaps)(v2[i], v2[0])

      mov(eax, float2uint(self.expTbl[3]))
      vpbroadcastd(self.tx2, eax)
      un(vfmadd213ps)(v2, v1, self.tx)

      mov(eax, float2uint(self.expTbl[2]))
      vpbroadcastd(self.tx, eax)
      un(vfmadd213ps)(v2, v1, self.tx2)

      mov(eax, float2uint(self.expTbl[1]))
      vpbroadcastd(self.tx2, eax)
      un(vfmadd213ps)(v2, v1, self.tx)

      mov(eax, float2uint(self.expTbl[0]))
      vpbroadcastd(self.tx, eax)
      un(vfmadd213ps)(v2, v1, self.tx2)

      un(vfmadd213ps)(v2, v1, self.tx)

      un(vscalefps)(v0, v2, v0) # v2 * 2^v1

  def code(self):
    unrollN = self.unrollN
    EXP_TMP_N = 3
    align(16)
    with FuncProc('fmath_expf_avx512'):
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
        if self.mode == 'allimm':
          self.tx = sf.v[constPos+self.EXP_COEF_N+1]
        if self.mode == 'allimm2':
          self.tx = sf.v[constPos+self.EXP_COEF_N+1]
          self.tx2 = sf.v[constPos+self.EXP_COEF_N+2]

        vbroadcastss(self.log2_e, ptr(rip+LOG2_E))
        for i in range(self.EXP_COEF_N):
          vbroadcastss(self.expCoeff[i], ptr(rip + self.EXP_COEF + 4 * i))

        framework(self.expCore, dst, src, n, unrollN, (v0, v1, v2))

# log_v(float *dst, const float *src, size_t n);
class LogGen:
  def __init__(self, param):
    self.unrollN = param.log_unrollN
    self.mode = param.log_mode
    self.precise = True
    self.checkSign = True # return -Inf for 0 and NaN for negative
  def data(self):
    self.c2 = -0.49999999
    self.c3 = 0.3333955701
    self.c4 = -0.25008487
    self.logTbl1 = []
    self.logTbl2 = []
    self.L = 4
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

  def logCore(self, n, args):
    (v0, v1, v2, v3, keepX, vk) = args
    t = self.t
    un = genUnrollFunc(n)
    if self.precise:
      un(vmovaps)(keepX, v0)

    setInt(v3[0], 127 << 23)
    un(vgetexpps)(v1, v0)
    setInt(t, 0x7fffff)
    un(vpandd)(v0, v0, t)
    un(vpsrad)(v2, v0, 23 - self.L) # d
    un(vpord)(v0, v0, v3[0]) # a
    un(vpermps)(v3, v2, self.tbl1) # b
    un(vfmsub213ps)(v0, v3, self.one) # c = a * b - 1
    un(vpermps)(v3, v2, self.tbl2) # log_b
    setFloat(t, math.log(2))
    un(vfmsub213ps)(v1, t, v3) # z = n * log2 - log_b

    # precise log for small |x-1|
    if self.precise:
      un(vsubps)(v2, keepX, self.one) # x-1
      setInt(t, 0x7fffffff)
      un(vandps)(v2, v2, t) # |x-1|
      setFloat(t, 0.02)
      un(vcmpltps)(vk, v2, t)
      un(vsubps)(zipOr(v0, vk), keepX, self.one) # c = v0 = x-1
      un(vxorps)(zipOr(v1, vk), v1, v1) # z = 0

    un(vmovaps)(v2, v0)
    setFloat(t, self.c4)
    setFloat(v3[0], self.c3)
    un(vfmadd213ps)(v2, t, v3[0]) # t = c * (-1/4) + (1/3)
    setFloat(t, self.c2)
    un(vfmadd213ps)(v2, v0, t) # t = t * c + (-1/2)
    un(vfmadd213ps)(v2, v0, self.one) # t = t * c + 1
    un(vfmadd213ps)(v0, v2, v1) # c = c * t + z

    if self.checkSign:
      # check x < 0 or x == 0
      NEG = 1 << 6
      ZERO = (1 << 1) | (1 << 2)
      un(vfpclassps)(vk, keepX, NEG)
      setInt(t, 0x7fc00000) # NaN
      un(vmovaps)(zipOr(v0, vk), t)
      un(vfpclassps)(vk, keepX, ZERO)
      setInt(t, 0xff800000) # -Inf
      un(vmovaps)(zipOr(v0, vk), t)

  def code(self):
    unrollN = 4 # self.unrollN
    LOG_TMP_N = 4
    if self.precise:
      LOG_TMP_N += 1
    LOG_CONST_N = 4 # one, tbl1, tbl2, t
    align(16)
    with FuncProc('fmath_logf_avx512'):
      with StackFrame(3, 1, useRCX=True, vNum=LOG_TMP_N*unrollN+LOG_CONST_N, vType=T_ZMM) as sf:
        dst = sf.p[0]
        src = sf.p[1]
        n = sf.p[2]
        v0 = sf.v[0:unrollN]
        v1 = sf.v[1*unrollN:2*unrollN]
        v2 = sf.v[2*unrollN:3*unrollN]
        v3 = sf.v[3*unrollN:4*unrollN]
        vk = []
        if self.precise:
          keepX = sf.v[4*unrollN:5*unrollN]
          for i in range(unrollN):
            vk.append(MaskReg(i+2))
        else:
          keepX = []
        constPos = LOG_TMP_N*unrollN
        self.one = sf.v[constPos]
        self.tbl1 = sf.v[constPos+1]
        self.tbl2 = sf.v[constPos+2]
        self.t = sf.v[constPos+3]
        setFloat(self.one, 1.0)
        vmovups(self.tbl1, ptr(rip + self.LOG_TBL1))
        vmovups(self.tbl2, ptr(rip + self.LOG_TBL2))

        framework(self.logCore, dst, src, n, unrollN, (v0, v1, v2, v3, keepX, vk))

def main():
  parser = getDefaultParser()
  parser.add_argument('-exp_un', '--exp_unrollN', help='number of unroll exp', type=int, default=4)
  parser.add_argument('-exp_mode', '--exp_mode', help='exp mode', type=str, default='allreg')
  parser.add_argument('-log_un', '--log_unrollN', help='number of unroll log', type=int, default=4)
  parser.add_argument('-log_mode', '--log_mode', help='log mode', type=str, default='allreg')
  global param
  param = parser.parse_args()

  init(param)
  exp = ExpGen(param)
  log = LogGen(param)
  segment('data')
  exp.data()
  log.data()

  segment('text')
  exp.code()
  log.code()

  term()

if __name__ == '__main__':
  main()
