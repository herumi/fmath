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

# parse "1.0", "1.0f", "1.0f,", "0x1.e5b538p-5", "0x1.e5b538p-5f", "[1, 2, 3f, 4]"
def parseHexFloat(s):
  def remove(s):
    if s[-1] == ',':
      s = s[0:-1]
    if s[-1] == 'f':
      s = s[0:-1]
    return s
  if ',' in s:
    return list(map(lambda x: float.fromhex(remove(x)), s.split()))
  else:
    return float.fromhex(remove(s))

# generate a function of void (*f)(float *dst, const float *src, size_t n);
# dst : dst pointer register
# src : src pointer register
# n : size of array
# unrollN : number of unroll
# v0 : input/output parameters
def LoopGenAVX512(func, dst, src, n, unrollN, v0):
  SIMD_BYTE = 64
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

def LoopGenAVX2(func, dst, src, n, unrollN, v0):
  SIMD_BYTE = 32
  un = genUnrollFunc()
  mod8L = Label()
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
  vmovups(ym0, ptr(src))
  add(src, SIMD_BYTE)
  func(1, v0[0:1])
  vmovups(ptr(dst), ym0)
  add(dst, SIMD_BYTE)
  sub(n, ELEM_N)
  L(check2L)
  cmp(n, ELEM_N)
  jae(lpL)

  L(mod8L)
  and_(ecx, ELEM_N-1)
  jz(exitL)

  small1L = Label()
  xor_(rdx, rdx)
  L(small1L)
  mov(eax, ptr(src+rdx*4))
  mov(ptr(rsp+rdx*4), eax)
  add(rdx, 1)
  cmp(rdx, rcx)
  jne(small1L)

  vmovups(ym0, ptr(rsp))
  func(1, v0[0:1])
  vmovups(ptr(rsp), ym0)

  small2L = Label()
  xor_(rdx, rdx)
  L(small2L)
  mov(eax, ptr(rsp+rdx*4))
  mov(ptr(dst+rdx*4), eax)
  add(rdx, 1)
  cmp(rdx, rcx)
  jne(small2L)

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

def putMem(name, s, v, repeat=1):
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
  vs = []
  for e in v:
    vs.extend([e]*repeat)
  writer(vs)

class Algo:
  def __init__(self, unrollN, mode):
    self.unrollN = unrollN
    self.mode = mode
    self.tmpRegN = 0 # # of temporary registers
    self.constRegN = 0 # # of constant (permanent) registers
    self.maskRegPos = 2 # v0 is not exists and v1 is reserved, so idx begins with number 2

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
    for i in range(n):
      vk.append(MaskReg(self.maskRegPos+i))
    return vk

# exp_v(float *dst, const float *src, size_t n);
class ExpGenAVX512(Algo):
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
    with FuncProc('fmath_expf_v_avx512'):
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

        LoopGenAVX512(self.expCore, dst, src, n, unrollN, v0)

class ExpGenAVX2(Algo):
  def __init__(self, unrollN, mode):
    super().__init__(unrollN, mode)
    self.setTmpRegN(3)
    self.EXP_COEF_N = 6
    self.setConstRegN(self.EXP_COEF_N + 1) # coeff[], x_min

  def data(self):
    putMem('i127', 'u32', 127)
    putMem('log_x_min', 'u32', hex(float2uint(parseHexFloat('-0x1.61814ap+6f')))) # fmath::exp_avx2(-0x1.644714p+6) is error
    putMem('Inf', 'u32', hex(0x7f800000))

  def expCore(self, n, v0):
    with self.regManager.pos:
      v1 = self.regManager.allocReg(n)
      v2 = self.regManager.allocReg(n)
      keep = self.regManager.allocReg(n)
      t = v2[0]

      un = genUnrollFunc()

      un(vmaxps)(v0, v0, self.x_min)
      vbroadcastss(t, ptr(rip+'log2_e'))
      if False:
        un(vmulps)(v1, v0, t)
        un(vroundps)(v0, v1, 0) # nearest even
        un(vsubps)(v1, v1, v0) # a = x - n
        un(vcvttps2dq)(v0, v0) # n = int(n)
      else: # a little faster
        un(vmulps)(v1, v0, t)
        un(vcvtps2dq)(v0, v1)
        un(vcvtdq2ps)(v2, v0)
        un(vsubps)(v1, v1, v2)

      vpbroadcastd(t, ptr(rip+'i127'))
      un(vpaddd)(v0, v0, t)
      un(vpslld)(v0, v0, 23)

      un(vmovaps)(v2, self.expCoeff[5])
      for i in range(4, -1, -1):
        un(vfmadd213ps)(v2, v1, self.expCoeff[i])
      un(vmulps)(v0, v0, v2)

  def code(self):
    unrollN = self.unrollN
    align(16)
    with FuncProc('fmath_expf_v_avx2'):
      with StackFrame(3, 0, useRCX=True, useRDX=True, stackSizeByte=32, vNum=self.getTotalRegN(), vType=T_YMM) as sf:
        self.regManager = RegManager(sf.v)
        dst = sf.p[0]
        src = sf.p[1]
        n = sf.p[2]
        v0 = self.regManager.allocReg(unrollN)
        self.expCoeff = self.regManager.allocReg(self.EXP_COEF_N)
        self.x_min = self.regManager.allocReg1()

        vbroadcastss(self.x_min, ptr(rip+'log_x_min'))
        for i in range(self.EXP_COEF_N):
          vbroadcastss(self.expCoeff[i], ptr(rip+'exp_coef'+i*4))

        LoopGenAVX2(self.expCore, dst, src, n, unrollN, v0)

# log_v(float *dst, const float *src, size_t n);
# updated by https://lpha-z.hatenablog.com/entry/2023/09/03/231500
class LogGenAVX512(Algo):
  def __init__(self, unrollN, mode, checkSign=False):
    super().__init__(unrollN, mode)
    self.checkSign = checkSign # return -Inf for 0 and NaN for negative
    self.L = 4 # table bit size
    self.deg = 4
    tmpRegN = 5
    #if self.checkSign:
    #  tmpRegN += 1
    constRegN = 5 # tbl1, tbl2, t, one, c[deg]
    self.setTmpRegN(tmpRegN)
    self.setConstRegN(constRegN)
  def data(self):
    align(64)
    self.ctbl = parseHexFloat("-0x1.ffffe2p-2f, 0x1.556f14p-2f, -0x1.fb1370p-3f")

    putMem('log_coef', 'f32', self.ctbl)
    putMem('log_A0', 'f32', float.fromhex('0x1.fd9c88p-1'))
    putMem('log_A1', 'f32', float.fromhex('0x1.p+19'))
    putMem('log_A2', 'f32', float.fromhex('0x1.79c328p+0'))
    putMem('log_A3', 'f32', 0.5)
    putMem('log_A4', 'f32', float.fromhex('0x1.62e430p-1'))

    invs_table = """
      0x1.0000000p+0f,
      0x1.e286920p-1f,
      0x1.c726fe0p-1f,
      0x1.af35980p-1f,
      0x1.99a95e0p-1f,
      0x1.861a9e0p-1f,
      0x1.746c640p-1f,
      0x1.6435820p-1f,
      0x1.5564f40p+0f,
      0x1.47a8960p+0f,
      0x1.3b1c5e0p+0f,
      0x1.2f640a0p+0f,
      0x1.24958c0p+0f,
      0x1.1a813e0p+0f,
      0x1.11180c0p+0f,
      0x1.04d9b40p+0f,
    """
    logTbl1 = parseHexFloat(invs_table)
    logTbl2 = [0]
    for v in logTbl1[1:]:
      logTbl2.append(-math.log(v))

    putMem('log_tbl1', 'f32', logTbl1)
    putMem('log_tbl2', 'f32', logTbl2)

#    putMem('minusInf', 'u32', hex(0xff800000), 16)


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
      vk = self.getMaskRegs(n)

      t = self.t
      un = genUnrollFunc()
      if self.checkSign:
        # the following code returns -NaN if v0 = 0xffffffff, so set it if v0 < 0
        un(vpsrad)(v1, v0, 31)
        un(vorps)(v0, v0, v1)

      un(vgetexpps)(v1, v0) # expo
      un(vgetmantps)(v0, v0, 0) # mant
      un(vmovaps)(v2, v0)
      un(vfmadd213ps)(v2, self.A0, ptr_b(rip+'log_A1')) # idxf
      un(vcmpgeps)(vk, v0, ptr_b(rip+'log_A2'))
      un(vaddps)(zipOr(v1, vk), v1, self.one)
      un(vmulps)(zipOr(v0, vk), v0, ptr_b(rip+'log_A3'))

      un(vpermps)(v3, v2, self.tbl1) # invs
      un(vfmsub213ps)(v0, v3, self.one) # t
      un(vpermps)(v2, v2, self.tbl2) # logs

      un(vmovaps)(v3, self.c3)
      un(vfmadd213ps)(v3, v0, ptr_b(rip+'log_coef'+1*4)) # poly = c4 * v0 + c3
      un(vfmadd213ps)(v3, v0, ptr_b(rip+'log_coef'+0*4)) # poly = poly * v0 + c2
      un(vfmadd213ps)(v3, v0, self.one) # poly = poly * v0 + 1
      un(vfmadd132ps)(v1, v2, ptr_b(rip+'log_A4')) # expo * A4 + v2
      un(vfmadd213ps)(v0, v3, v1) # v0 = t * poly + z

#      if self.checkSign:
#        # set -Inf if x < 0
#        z = v1[0]
#        vxorps(z, z, z)
#        un(vcmpltps)(vk, keepX, z)
#        un(vblendmps)(zipOr(v0, vk), v0, ptr_b(rip+'minusNaN'))

  def code(self):
    unrollN = self.unrollN
    tmpN = self.tmpRegN
    align(16)
    with FuncProc('fmath_logf_v_avx512'):
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
        self.A0 = self.regManager.allocReg1()
        self.c3 = self.regManager.allocReg1()

        setFloat(self.one, 1.0)
        vbroadcastss(self.A0, ptr(rip+'log_A0'))
        vbroadcastss(self.c3, ptr(rip+'log_coef'+(self.deg-2)*4))
        vmovups(self.tbl1, ptr(rip+'log_tbl1'))
        vmovups(self.tbl2, ptr(rip+'log_tbl2'))

        LoopGenAVX512(self.logCore, dst, src, n, unrollN, v0)

# QQQ
N=8
class LogGenAVX2(Algo):
  def __init__(self, unrollN, mode, checkSign=False):
    super().__init__(unrollN, mode)
    self.checkSign = checkSign # return -Inf for 0 and NaN for negative
    self.L = 4 # table bit size
    self.deg = 4
    tmpRegN = 7
    #if self.checkSign:
    #  tmpRegN += 1
    constRegN = 7 # tbl1L, tbl1H, tbl2L, tbl2H, t, one, c[deg]
    self.setTmpRegN(tmpRegN)
    self.setConstRegN(constRegN)
  def data(self):
    align(64)
    putMem('minusNaN', 'u32', hex(0xffc00000), N)
    putMem('log2_i7fffffff', 'u32', 0x7fffffff, N)
    self.ctbl = parseHexFloat("-0x1.ffffe2p-2f, 0x1.556f14p-2f, -0x1.fb1370p-3f")

    putMem('log2_coef', 'f32', self.ctbl, N)
    putMem('log2_A0', 'f32', float.fromhex('0x1.fd9c88p-1'), N)
    putMem('log2_A1', 'f32', float.fromhex('0x1.p+19'), N)
    putMem('log2_A2', 'f32', float.fromhex('0x1.79c328p+0'), N)
    putMem('log2_A3', 'f32', 0.5, N)
    putMem('log2_A4', 'f32', float.fromhex('0x1.62e430p-1'), N)
    putMem('log2_i15', 'u32', 15, N)


    invs_table = """
      0x1.0000000p+0f,
      0x1.e286920p-1f,
      0x1.c726fe0p-1f,
      0x1.af35980p-1f,
      0x1.99a95e0p-1f,
      0x1.861a9e0p-1f,
      0x1.746c640p-1f,
      0x1.6435820p-1f,
      0x1.5564f40p+0f,
      0x1.47a8960p+0f,
      0x1.3b1c5e0p+0f,
      0x1.2f640a0p+0f,
      0x1.24958c0p+0f,
      0x1.1a813e0p+0f,
      0x1.11180c0p+0f,
      0x1.04d9b40p+0f,
    """
    logTbl1 = parseHexFloat(invs_table)
    logTbl2 = [0]
    for v in logTbl1[1:]:
      logTbl2.append(-math.log(v))

    align(64)
    putMem('log2_tbl1', 'f32', logTbl1)
    putMem('log2_tbl2', 'f32', logTbl2)
    putMem('log2_i7', 'u32', 7, 8) # 3 bit


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

  def vpermpsEmu(self, y, x, tL, tH, tblL, tblH):
    un = genUnrollFunc()
    n = len(x)
    for i in range(n):
      vpermps(tL, x[i], tblL)
      vpermps(tH, x[i], tblH)
      vpslld(y[i], x[i], 31-3)
      vblendvps(y[i], tL, tH, y[i])

  def logCore(self, n, v0):
    with self.regManager.pos:
      v1 = self.regManager.allocReg(n)
      v2 = self.regManager.allocReg(n)
      v3 = self.regManager.allocReg(n)
      tL = self.regManager.allocReg1()
      tH = self.regManager.allocReg1()

      t = self.t
      un = genUnrollFunc()

      un(vgetexpps)(v1, v0) # expo
      un(vgetmantps)(v0, v0, 0) # mant
      un(vmovaps)(v2, v0)
      un(vfmadd213ps)(v2, self.A0, ptr(rip+'log2_A1')) # idxf
      for i in range(n):
        vcmpgeps(tL, v0[i], ptr(rip+'log2_A2'))
        vandps(tH, self.one, tL)
        vaddps(v1[i], v1[i], tH)
        vblendvps(tH, self.one, ptr(rip+'log2_A3'), tL)
        vmulps(v0[i], v0[i], tH)

      self.vpermpsEmu(v3, v2, tL, tH, self.tbl1, self.tbl1H)
      un(vfmsub213ps)(v0, v3, self.one) # t
      self.vpermpsEmu(v2, v2, tL, tH, self.tbl2, self.tbl2H)

      un(vmovaps)(v3, self.c3)
      un(vfmadd213ps)(v3, v0, ptr(rip+'log2_coef'+1*4*N)) # poly = c4 * v0 + c3
      un(vfmadd213ps)(v3, v0, ptr(rip+'log2_coef'+0*4*N)) # poly = poly * v0 + c2
      un(vfmadd213ps)(v3, v0, self.one) # poly = poly * v0 + 1
      un(vfmadd132ps)(v1, v2, ptr(rip+'log2_A4')) # expo * A4 + v2
      un(vfmadd213ps)(v0, v3, v1) # v0 = t * poly + z


  def code(self):
    unrollN = self.unrollN
    tmpN = self.tmpRegN
    align(16)
    with FuncProc('fmath_logf_v_avx2'):
      with StackFrame(3, 0, useRCX=True, useRDX=True, stackSizeByte=32, vNum=self.getTotalRegN(), vType=T_YMM) as sf:
        self.regManager = RegManager(sf.v)
        dst = sf.p[0]
        src = sf.p[1]
        n = sf.p[2]
        v0 = self.regManager.allocReg(unrollN)
        self.one = self.regManager.allocReg1()
        self.tbl1 = self.regManager.allocReg1()
        self.tbl1H = self.regManager.allocReg1()
        self.tbl2 = self.regManager.allocReg1()
        self.tbl2H = self.regManager.allocReg1()
        self.t = self.regManager.allocReg1()
        self.A0 = self.regManager.allocReg1()
        self.c3 = self.regManager.allocReg1()

        setFloat(self.one, 1.0)
        vmovaps(self.A0, ptr(rip+'log2_A0'))
        vmovaps(self.c3, ptr(rip+'log2_coef'+(self.deg-2)*4*N))
        vmovups(self.tbl1, ptr(rip+'log2_tbl1'))
        vmovups(self.tbl1H, ptr(rip+'log2_tbl1'+4*8))
        vmovups(self.tbl2, ptr(rip+'log2_tbl2'))
        vmovups(self.tbl2H, ptr(rip+'log2_tbl2'+4*8))

        LoopGenAVX2(self.logCore, dst, src, n, unrollN, v0)

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
  exp512 = ExpGenAVX512(param.exp_unrollN, param.exp_mode)
  log512 = LogGenAVX512(param.log_unrollN, param.log_mode)
  exp2 = ExpGenAVX2(3, param.exp_mode)
  log2 = LogGenAVX2(1, param.exp_mode)
  exp512.data()
  log512.data()
  exp2.data()
  log2.data()

  segment('text')
  exp512.code()
  log512.code()
  exp2.code()
  log2.code()

  term()

if __name__ == '__main__':
  main()
