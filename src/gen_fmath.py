from s_xbyak import *
import math
import argparse

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
# v0 : input/output parameters
def genericLoopAVX512(func, dst, src, n, unrollN, v0):
  un = genUnrollFunc()
  mod16L = Label()
  exitL = Label()
  lpL = Label()
  check1L = Label()
  check2L = Label()
  lpUnrollL = Label()

  mov(rcx, n)
  jmp(check1L)

  ELEM_N = SIMD_BYTE // 4

  align(32)
  L(lpUnrollL)
  un(vmovups)(v0, ptr(src))
  add(src, SIMD_BYTE*unrollN)
  func(unrollN, v0)
  un(vmovups)(ptr(dst), v0)
  add(dst, SIMD_BYTE*unrollN)
  sub(n, ELEM_N*unrollN)
  L(check1L)
  cmp(n, ELEM_N*unrollN)
  jae(lpUnrollL)

  jmp(check2L)

  align(32)
  L(lpL)
  vmovups(zm0, ptr(src))
  add(src, SIMD_BYTE)
  func(1, v0[0:1])
  vmovups(ptr(dst), zm0)
  add(dst, SIMD_BYTE)
  sub(n, ELEM_N)
  L(check2L)
  cmp(n, ELEM_N)
  jae(lpL)

  L(mod16L)
  and_(ecx, 15)
  jz(exitL)
  mov(eax, 1)    # eax = 1
  shl(eax, cl)   # eax = 1 << n
  sub(eax, 1)
  kmovd(k1, eax)
  vmovups(zm0|k1|T_z, ptr(src))
  func(1, v0[0:1])
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

class RegManager:
  def __init__(self, v):
    self.v = v
    self.pos = Counter()

  def allocReg(self, n):
    pos = self.pos.get()
    self.pos.add(n)
    return self.v[pos:pos+n]

  def allocReg1(self):
    return self.allocReg(1)[0]

def getTypeSize(t):
  tbl = {
    'u8' : (int, 8),
    'u32': (int, 32),
    'u64': (int, 64),
    'f32': (float, 32),
    'f64': (float, 64),
  }
  return tbl[t]

def putMem(name, s, v):
  """
  name : label
  s : string of u8/u32/u64/f32/f64
  v : int/float/str/list
  """
  makeLabel(name)
  (t, size) = getTypeSize(s)
  if not isinstance(v, list):
    v = [v]
  if t == float:
    if size == 32:
      v = map(lambda x:hex(float2uint(x)), v)
    else:
      v = map(lambda x:hex(double2uint(x)), v)
  tbl = {
    (int, 8) : db_,
    (int, 32) : dd_,
    (int, 64) : dq_,
    (float, 32) : dd_,
    (float, 64) : dq_,
  }
  writer = tbl[(t, size)]
  writer(v)

class Algo:
  def __init__(self, unrollN, mode):
    self.unrollN = unrollN
    self.mode = mode
    self.tmpRegN = 0 # # of temporary registers
    self.constRegN = 0 # # of constant (permanent) registers

  def setTmpRegN(self, tmpRegN):
    self.tmpRegN = tmpRegN

  def setConstRegN(self, constRegN):
    self.constRegN = constRegN

  def getTotalRegN(self):
    return self.tmpRegN * self.unrollN + self.constRegN

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
    putMem('log2_e', 'f32', 1/math.log(2))

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
    tbl = expTblMaple
    putMem('exp_coef', 'f32', tbl)

  def expCore(self, n, v0):
    with self.regManager.pos:
      v1 = self.regManager.allocReg(n)
      v2 = self.regManager.allocReg(n)

      un = genUnrollFunc()
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
      with StackFrame(3, 0, useRCX=True, vNum=self.getTotalRegN(), vType=T_ZMM) as sf:
        self.regManager = RegManager(sf.v)
        dst = sf.p[0]
        src = sf.p[1]
        n = sf.p[2]
        v0 = self.regManager.allocReg(unrollN)
        self.expCoeff = self.regManager.allocReg(self.EXP_COEF_N)
        self.log2_e = self.regManager.allocReg1()

        vbroadcastss(self.log2_e, ptr(rip+'log2_e'))
        for i in range(self.EXP_COEF_N):
          vbroadcastss(self.expCoeff[i], ptr(rip+'exp_coef'+i*4))

        genericLoopAVX512(self.expCore, dst, src, n, unrollN, v0)

# log_v(float *dst, const float *src, size_t n);
# ref. https://lpha-z.hatenablog.com/entry/2023/09/03/231500
class LogGen(Algo):
  def __init__(self, unrollN, mode):
    super().__init__(unrollN, mode)
    self.precise = True
    self.checkSign = False # return -Inf for 0 and NaN for negative
    self.L = 4 # table bit size
    self.deg = 4
    tmpRegN = 4
    if self.precise:
      tmpRegN += 1
    constRegN = 5 # tbl1, tbl2, t, one, c[deg]
    self.setTmpRegN(tmpRegN)
    self.setConstRegN(constRegN)
  def data(self):
    align(32)
    self.ctbl = [1.0, -0.49999999, 0.3333955701, -0.25008487]

    putMem('log_coef', 'f32', self.ctbl)
    putMem('log2', 'f32', math.log(2))
    putMem('_0x7fffffff', 'u32', hex(0x7fffffff))

    bound = 0.02
    putMem('log_boundary', 'f32', bound)

    putMem('NaN', 'u32', hex(0x7fc00000))
    putMem('minusInf', 'u32', hex(0xff800000))

    logTbl1 = []
    logTbl2 = []
    LN = 1 << self.L
    for i in range(LN):
      u = (127 << 23) | ((i*2+1) << (23 - self.L - 1))
      v = 1 / uint2float(u)
      v = uint2float(float2uint(v)) # enforce C float type instead of double
      # v = numpy.float32(v)
      logTbl1.append(v)
      logTbl2.append(math.log(v))

    putMem('log_tbl1', 'f32', logTbl1)
    putMem('log_tbl2', 'f32', logTbl2)


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
  def logCore(self, n, v0):
    with self.regManager.pos:
      v1 = self.regManager.allocReg(n)
      v2 = self.regManager.allocReg(n)
      v3 = self.regManager.allocReg(n)

      t = self.t
      un = genUnrollFunc()
      if self.precise:
        keepX = self.regManager.allocReg(n)
        un(vmovaps)(keepX, v0)

      un(vgetexpps)(v1, v0) # n
      un(vgetmantps)(v0, v0, 0) # a
      un(vpsrad)(v2, v0, 23 - self.L) # d

      un(vpermps)(v3, v2, self.tbl1) # b
      un(vfmsub213ps)(v0, v3, self.one) # c = a * b - 1
      un(vpermps)(v3, v2, self.tbl2) # log_b

      un(vfmsub132ps)(v1, v3, ptr_b(rip+'log2')) # z = n * log2 - log_b

      # precise log for small |x-1|
      if self.precise:
        vk = self.getMaskRegs(self.unrollN)
        un(vsubps)(v2, keepX, self.one) # x-1
        un(vandps)(v3, v2, ptr_b(rip+'_0x7fffffff')) # |x-1|
        un(vcmpltps)(vk, v3, ptr_b(rip+'log_boundary'))
        un(vmovaps)(zipOr(v0, vk), v2) # c = v0 = x-1
        un(vxorps)(zipOr(v1, vk), v1, v1) # z = 0

      un(vmovaps)(v2, self.c3)
      un(vfmadd213ps)(v2, v0, ptr_b(rip+'log_coef'+2*4)) # t = c4 * v0 + c3
      un(vfmadd213ps)(v2, v0, ptr_b(rip+'log_coef'+1*4)) # t = t * v0 + c2
      un(vfmadd213ps)(v2, v0, self.one) # t = t * v0 + 1
      un(vfmadd213ps)(v0, v2, v1) # v0 = v0 * t + z

      if self.checkSign:
        # check x < 0 or x == 0
        NEG = 1 << 6
        ZERO = (1 << 1) | (1 << 2)
        un(vfpclassps)(vk, keepX, NEG)
        un(vblendmps)(zipOr(v0, vk), v0, ptr_b(rip+'NaN'))
        un(vfpclassps)(vk, keepX, ZERO)
        un(vblendmps)(zipOr(v0, vk), v0, ptr_b(rip+'minusInf'))

  def code(self):
    unrollN = self.unrollN
    tmpN = self.tmpRegN
    align(16)
    with FuncProc('fmath_logf_avx512'):
      with StackFrame(3, 0, useRCX=True, vNum=self.getTotalRegN(), vType=T_ZMM) as sf:
        self.regManager = RegManager(sf.v)
        dst = sf.p[0]
        src = sf.p[1]
        n = sf.p[2]
        v0 = self.regManager.allocReg(unrollN)
        self.one = self.regManager.allocReg1()
        self.tbl1 = self.regManager.allocReg1()
        self.tbl2 = self.regManager.allocReg1()
        self.t = self.regManager.allocReg1()
        self.c3 = self.regManager.allocReg1()

        setFloat(self.one, 1.0)
        vbroadcastss(self.c3, ptr(rip+'log_coef'+(self.deg-1)*4))
        vmovups(self.tbl1, ptr(rip+'log_tbl1'))
        vmovups(self.tbl2, ptr(rip+'log_tbl2'))
        if self.L == 5:
          self.tbl1H = self.regManager.allocReg1()
          self.tbl2H = self.regManager.allocReg1()
          vmovups(self.tbl1H, ptr(rip+'log_tbl1'+64))
          vmovups(self.tbl2H, ptr(rip+'log_tbl2'+64))

        genericLoopAVX512(self.logCore, dst, src, n, unrollN, v0)

def main():
  parser = getDefaultParser()
  parser.add_argument('-exp_un', '--exp_unrollN', help='number of unroll exp', type=int, default=7)
  parser.add_argument('-exp_mode', '--exp_mode', help='exp mode', type=str, default='allreg')
  parser.add_argument('-log_un', '--log_unrollN', help='number of unroll log', type=int, default=4)
  parser.add_argument('-log_mode', '--log_mode', help='log mode', type=str, default='allreg')
  global param
  param = parser.parse_args()

  init(param)
  segment('data')
  exp = ExpGen(param.exp_unrollN, param.exp_mode)
  log = LogGen(param.log_unrollN, param.log_mode)
  exp.data()
  log.data()

  segment('text')
  exp.code()
  log.code()

  term()

if __name__ == '__main__':
  main()
