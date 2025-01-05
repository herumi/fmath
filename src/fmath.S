# for gas
#ifdef __linux__
  #define PRE(x) x
  #define TYPE(x) .type x, @function
  #define SIZE(x) .size x, .-x
.section .note.GNU-stack,"",%progbits
#else
  #ifdef _WIN32
    #define PRE(x) x
  #else
    #define PRE(x) _ ## x
  #endif
  #define TYPE(x)
  #define SIZE(x)
#endif
.data
PRE(log2_e):
.long 0x3fb8aa3b
PRE(exp_coef):
.long 0x3f800000,0x3f317218,0x3e75fd0b,0x3d63578a,0x3c1e6362,0x3aaf9319
.balign 64
PRE(log_coef):
.long 0xbefffff1,0x3eaab78a,0xbe7d89b8
PRE(log_A0):
.long 0x3f7ece44
PRE(log_A1):
.long 0x49000000
PRE(log_A2):
.long 0x3fbce194
PRE(log_A3):
.long 0x3f000000
PRE(log_A4):
.long 0x3f317218
PRE(log_tbl1):
.long 0x3f800000,0x3f714349,0x3f63937f,0x3f579acc,0x3f4cd4af,0x3f430d4f,0x3f3a3632,0x3f321ac1,0x3faab27a,0x3fa3d44b,0x3f9d8e2f,0x3f97b205,0x3f924ac6,0x3f8d409f,0x3f888c06,0x3f826cda
PRE(log_tbl2):
.long 0x0,0x3d72da9c,0x3df108c5,0x3e2fda3b,0x3e645854,0x3e8b37f6,0x3ea2f755,0x3eb9c1d5,0xbe93627e,0xbe7cb7b8,0xbe54bb9b,0xbe2deba5,0xbe08c7de,0xbdc9c3f4,0xbd84611f,0xbc99c2c4
PRE(i127):
.long 127
PRE(log_x_min):
.long 0xc2b0c0a5
PRE(Inf):
.long 0x7f800000
.balign 64
PRE(minusNaN):
.long 0xffc00000,0xffc00000,0xffc00000,0xffc00000,0xffc00000,0xffc00000,0xffc00000,0xffc00000
PRE(log2_i7fffffff):
.long 2147483647,2147483647,2147483647,2147483647,2147483647,2147483647,2147483647,2147483647
PRE(log2_coef):
.long 0xbefffff1,0xbefffff1,0xbefffff1,0xbefffff1,0xbefffff1,0xbefffff1,0xbefffff1,0xbefffff1,0x3eaab78a,0x3eaab78a,0x3eaab78a,0x3eaab78a,0x3eaab78a,0x3eaab78a,0x3eaab78a,0x3eaab78a,0xbe7d89b8,0xbe7d89b8,0xbe7d89b8,0xbe7d89b8,0xbe7d89b8,0xbe7d89b8,0xbe7d89b8,0xbe7d89b8
PRE(log2_A0):
.long 0x3f7ece44,0x3f7ece44,0x3f7ece44,0x3f7ece44,0x3f7ece44,0x3f7ece44,0x3f7ece44,0x3f7ece44
PRE(log2_A1):
.long 0x49000000,0x49000000,0x49000000,0x49000000,0x49000000,0x49000000,0x49000000,0x49000000
PRE(log2_A2):
.long 0x3fbce194,0x3fbce194,0x3fbce194,0x3fbce194,0x3fbce194,0x3fbce194,0x3fbce194,0x3fbce194
PRE(log2_A3):
.long 0x3f000000,0x3f000000,0x3f000000,0x3f000000,0x3f000000,0x3f000000,0x3f000000,0x3f000000
PRE(log2_A4):
.long 0x3f317218,0x3f317218,0x3f317218,0x3f317218,0x3f317218,0x3f317218,0x3f317218,0x3f317218
PRE(log2_i15):
.long 15,15,15,15,15,15,15,15
.balign 64
PRE(log2_tbl1):
.long 0x3f800000,0x3f714349,0x3f63937f,0x3f579acc,0x3f4cd4af,0x3f430d4f,0x3f3a3632,0x3f321ac1,0x3faab27a,0x3fa3d44b,0x3f9d8e2f,0x3f97b205,0x3f924ac6,0x3f8d409f,0x3f888c06,0x3f826cda
PRE(log2_tbl2):
.long 0x0,0x3d72da9c,0x3df108c5,0x3e2fda3b,0x3e645854,0x3e8b37f6,0x3ea2f755,0x3eb9c1d5,0xbe93627e,0xbe7cb7b8,0xbe54bb9b,0xbe2deba5,0xbe08c7de,0xbdc9c3f4,0xbd84611f,0xbc99c2c4
PRE(log2_i7):
.long 7,7,7,7,7,7,7,7
.text
.balign 16
.global PRE(fmath_expf_v_avx512)
PRE(fmath_expf_v_avx512):
TYPE(fmath_expf_v_avx512)
vbroadcastss PRE(log2_e)(%rip), %zmm13
vbroadcastss PRE(exp_coef)(%rip), %zmm7
vbroadcastss PRE(exp_coef)+4(%rip), %zmm8
vbroadcastss PRE(exp_coef)+8(%rip), %zmm9
vbroadcastss PRE(exp_coef)+12(%rip), %zmm10
vbroadcastss PRE(exp_coef)+16(%rip), %zmm11
vbroadcastss PRE(exp_coef)+20(%rip), %zmm12
mov %rdx, %rcx
jmp .L2
.balign 32
.L1:
vmovups (%rsi), %zmm0
vmovups 64(%rsi), %zmm1
vmovups 128(%rsi), %zmm2
vmovups 192(%rsi), %zmm3
vmovups 256(%rsi), %zmm4
vmovups 320(%rsi), %zmm5
vmovups 384(%rsi), %zmm6
add $448, %rsi
vmulps %zmm13, %zmm0, %zmm0
vmulps %zmm13, %zmm1, %zmm1
vmulps %zmm13, %zmm2, %zmm2
vmulps %zmm13, %zmm3, %zmm3
vmulps %zmm13, %zmm4, %zmm4
vmulps %zmm13, %zmm5, %zmm5
vmulps %zmm13, %zmm6, %zmm6
vreduceps $0, %zmm0, %zmm14
vreduceps $0, %zmm1, %zmm15
vreduceps $0, %zmm2, %zmm16
vreduceps $0, %zmm3, %zmm17
vreduceps $0, %zmm4, %zmm18
vreduceps $0, %zmm5, %zmm19
vreduceps $0, %zmm6, %zmm20
vsubps %zmm14, %zmm0, %zmm0
vsubps %zmm15, %zmm1, %zmm1
vsubps %zmm16, %zmm2, %zmm2
vsubps %zmm17, %zmm3, %zmm3
vsubps %zmm18, %zmm4, %zmm4
vsubps %zmm19, %zmm5, %zmm5
vsubps %zmm20, %zmm6, %zmm6
vmovaps %zmm12, %zmm21
vmovaps %zmm12, %zmm22
vmovaps %zmm12, %zmm23
vmovaps %zmm12, %zmm24
vmovaps %zmm12, %zmm25
vmovaps %zmm12, %zmm26
vmovaps %zmm12, %zmm27
vfmadd213ps %zmm11, %zmm14, %zmm21
vfmadd213ps %zmm11, %zmm15, %zmm22
vfmadd213ps %zmm11, %zmm16, %zmm23
vfmadd213ps %zmm11, %zmm17, %zmm24
vfmadd213ps %zmm11, %zmm18, %zmm25
vfmadd213ps %zmm11, %zmm19, %zmm26
vfmadd213ps %zmm11, %zmm20, %zmm27
vfmadd213ps %zmm10, %zmm14, %zmm21
vfmadd213ps %zmm10, %zmm15, %zmm22
vfmadd213ps %zmm10, %zmm16, %zmm23
vfmadd213ps %zmm10, %zmm17, %zmm24
vfmadd213ps %zmm10, %zmm18, %zmm25
vfmadd213ps %zmm10, %zmm19, %zmm26
vfmadd213ps %zmm10, %zmm20, %zmm27
vfmadd213ps %zmm9, %zmm14, %zmm21
vfmadd213ps %zmm9, %zmm15, %zmm22
vfmadd213ps %zmm9, %zmm16, %zmm23
vfmadd213ps %zmm9, %zmm17, %zmm24
vfmadd213ps %zmm9, %zmm18, %zmm25
vfmadd213ps %zmm9, %zmm19, %zmm26
vfmadd213ps %zmm9, %zmm20, %zmm27
vfmadd213ps %zmm8, %zmm14, %zmm21
vfmadd213ps %zmm8, %zmm15, %zmm22
vfmadd213ps %zmm8, %zmm16, %zmm23
vfmadd213ps %zmm8, %zmm17, %zmm24
vfmadd213ps %zmm8, %zmm18, %zmm25
vfmadd213ps %zmm8, %zmm19, %zmm26
vfmadd213ps %zmm8, %zmm20, %zmm27
vfmadd213ps %zmm7, %zmm14, %zmm21
vfmadd213ps %zmm7, %zmm15, %zmm22
vfmadd213ps %zmm7, %zmm16, %zmm23
vfmadd213ps %zmm7, %zmm17, %zmm24
vfmadd213ps %zmm7, %zmm18, %zmm25
vfmadd213ps %zmm7, %zmm19, %zmm26
vfmadd213ps %zmm7, %zmm20, %zmm27
vscalefps %zmm0, %zmm21, %zmm0
vscalefps %zmm1, %zmm22, %zmm1
vscalefps %zmm2, %zmm23, %zmm2
vscalefps %zmm3, %zmm24, %zmm3
vscalefps %zmm4, %zmm25, %zmm4
vscalefps %zmm5, %zmm26, %zmm5
vscalefps %zmm6, %zmm27, %zmm6
vmovups %zmm0, (%rdi)
vmovups %zmm1, 64(%rdi)
vmovups %zmm2, 128(%rdi)
vmovups %zmm3, 192(%rdi)
vmovups %zmm4, 256(%rdi)
vmovups %zmm5, 320(%rdi)
vmovups %zmm6, 384(%rdi)
add $448, %rdi
sub $112, %rdx
.L2:
cmp $112, %rdx
jae .L1
jmp .L4
.balign 32
.L3:
vmovups (%rsi), %zmm0
add $64, %rsi
vmulps %zmm13, %zmm0, %zmm0
vreduceps $0, %zmm0, %zmm14
vsubps %zmm14, %zmm0, %zmm0
vmovaps %zmm12, %zmm15
vfmadd213ps %zmm11, %zmm14, %zmm15
vfmadd213ps %zmm10, %zmm14, %zmm15
vfmadd213ps %zmm9, %zmm14, %zmm15
vfmadd213ps %zmm8, %zmm14, %zmm15
vfmadd213ps %zmm7, %zmm14, %zmm15
vscalefps %zmm0, %zmm15, %zmm0
vmovups %zmm0, (%rdi)
add $64, %rdi
sub $16, %rdx
.L4:
cmp $16, %rdx
jae .L3
.L5:
and $15, %ecx
jz .L6
mov $1, %eax
shl %cl, %eax
sub $1, %eax
kmovd %eax, %k1
vmovups (%rsi), %zmm0{%k1}{z}
vmulps %zmm13, %zmm0, %zmm0
vreduceps $0, %zmm0, %zmm14
vsubps %zmm14, %zmm0, %zmm0
vmovaps %zmm12, %zmm15
vfmadd213ps %zmm11, %zmm14, %zmm15
vfmadd213ps %zmm10, %zmm14, %zmm15
vfmadd213ps %zmm9, %zmm14, %zmm15
vfmadd213ps %zmm8, %zmm14, %zmm15
vfmadd213ps %zmm7, %zmm14, %zmm15
vscalefps %zmm0, %zmm15, %zmm0
vmovups %zmm0, (%rdi){%k1}
.L6:
vzeroupper
ret
SIZE(fmath_expf_v_avx512)
.balign 16
.global PRE(fmath_logf_v_avx512)
PRE(fmath_logf_v_avx512):
TYPE(fmath_logf_v_avx512)
mov $1065353216, %eax
vpbroadcastd %eax, %zmm4
vbroadcastss PRE(log_A0)(%rip), %zmm8
vbroadcastss PRE(log_coef)+8(%rip), %zmm9
vmovups PRE(log_tbl1)(%rip), %zmm5
vmovups PRE(log_tbl2)(%rip), %zmm6
mov %rdx, %rcx
jmp .L8
.balign 32
.L7:
vmovups (%rsi), %zmm0
vmovups 64(%rsi), %zmm1
vmovups 128(%rsi), %zmm2
vmovups 192(%rsi), %zmm3
add $256, %rsi
vgetexpps %zmm0, %zmm10
vgetexpps %zmm1, %zmm11
vgetexpps %zmm2, %zmm12
vgetexpps %zmm3, %zmm13
vgetmantps $0, %zmm0, %zmm0
vgetmantps $0, %zmm1, %zmm1
vgetmantps $0, %zmm2, %zmm2
vgetmantps $0, %zmm3, %zmm3
vmovaps %zmm0, %zmm14
vmovaps %zmm1, %zmm15
vmovaps %zmm2, %zmm16
vmovaps %zmm3, %zmm17
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm8, %zmm14
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm8, %zmm15
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm8, %zmm16
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm8, %zmm17
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm0, %k2
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm1, %k3
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm2, %k4
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm3, %k5
vaddps %zmm4, %zmm10, %zmm10{%k2}
vaddps %zmm4, %zmm11, %zmm11{%k3}
vaddps %zmm4, %zmm12, %zmm12{%k4}
vaddps %zmm4, %zmm13, %zmm13{%k5}
vmulps PRE(log_A3)(%rip){1to16}, %zmm0, %zmm0{%k2}
vmulps PRE(log_A3)(%rip){1to16}, %zmm1, %zmm1{%k3}
vmulps PRE(log_A3)(%rip){1to16}, %zmm2, %zmm2{%k4}
vmulps PRE(log_A3)(%rip){1to16}, %zmm3, %zmm3{%k5}
vpermps %zmm5, %zmm14, %zmm18
vpermps %zmm5, %zmm15, %zmm19
vpermps %zmm5, %zmm16, %zmm20
vpermps %zmm5, %zmm17, %zmm21
vfmsub213ps %zmm4, %zmm18, %zmm0
vfmsub213ps %zmm4, %zmm19, %zmm1
vfmsub213ps %zmm4, %zmm20, %zmm2
vfmsub213ps %zmm4, %zmm21, %zmm3
vpermps %zmm6, %zmm14, %zmm14
vpermps %zmm6, %zmm15, %zmm15
vpermps %zmm6, %zmm16, %zmm16
vpermps %zmm6, %zmm17, %zmm17
vmovaps %zmm9, %zmm18
vmovaps %zmm9, %zmm19
vmovaps %zmm9, %zmm20
vmovaps %zmm9, %zmm21
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm18
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm1, %zmm19
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm2, %zmm20
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm3, %zmm21
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm0, %zmm18
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm1, %zmm19
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm2, %zmm20
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm3, %zmm21
vfmadd213ps %zmm4, %zmm0, %zmm18
vfmadd213ps %zmm4, %zmm1, %zmm19
vfmadd213ps %zmm4, %zmm2, %zmm20
vfmadd213ps %zmm4, %zmm3, %zmm21
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm14, %zmm10
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm15, %zmm11
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm16, %zmm12
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm17, %zmm13
vfmadd213ps %zmm10, %zmm18, %zmm0
vfmadd213ps %zmm11, %zmm19, %zmm1
vfmadd213ps %zmm12, %zmm20, %zmm2
vfmadd213ps %zmm13, %zmm21, %zmm3
vmovups %zmm0, (%rdi)
vmovups %zmm1, 64(%rdi)
vmovups %zmm2, 128(%rdi)
vmovups %zmm3, 192(%rdi)
add $256, %rdi
sub $64, %rdx
.L8:
cmp $64, %rdx
jae .L7
jmp .L10
.balign 32
.L9:
vmovups (%rsi), %zmm0
add $64, %rsi
vgetexpps %zmm0, %zmm10
vgetmantps $0, %zmm0, %zmm0
vmovaps %zmm0, %zmm11
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm8, %zmm11
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm0, %k2
vaddps %zmm4, %zmm10, %zmm10{%k2}
vmulps PRE(log_A3)(%rip){1to16}, %zmm0, %zmm0{%k2}
vpermps %zmm5, %zmm11, %zmm12
vfmsub213ps %zmm4, %zmm12, %zmm0
vpermps %zmm6, %zmm11, %zmm11
vmovaps %zmm9, %zmm12
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm12
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm0, %zmm12
vfmadd213ps %zmm4, %zmm0, %zmm12
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm11, %zmm10
vfmadd213ps %zmm10, %zmm12, %zmm0
vmovups %zmm0, (%rdi)
add $64, %rdi
sub $16, %rdx
.L10:
cmp $16, %rdx
jae .L9
.L11:
and $15, %ecx
jz .L12
mov $1, %eax
shl %cl, %eax
sub $1, %eax
kmovd %eax, %k1
vmovups (%rsi), %zmm0{%k1}{z}
vgetexpps %zmm0, %zmm10
vgetmantps $0, %zmm0, %zmm0
vmovaps %zmm0, %zmm11
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm8, %zmm11
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm0, %k2
vaddps %zmm4, %zmm10, %zmm10{%k2}
vmulps PRE(log_A3)(%rip){1to16}, %zmm0, %zmm0{%k2}
vpermps %zmm5, %zmm11, %zmm12
vfmsub213ps %zmm4, %zmm12, %zmm0
vpermps %zmm6, %zmm11, %zmm11
vmovaps %zmm9, %zmm12
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm12
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm0, %zmm12
vfmadd213ps %zmm4, %zmm0, %zmm12
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm11, %zmm10
vfmadd213ps %zmm10, %zmm12, %zmm0
vmovups %zmm0, (%rdi){%k1}
.L12:
vzeroupper
ret
SIZE(fmath_logf_v_avx512)
.balign 16
.global PRE(fmath_expf_v_avx2)
PRE(fmath_expf_v_avx2):
TYPE(fmath_expf_v_avx2)
sub $40, %rsp
mov %rdx, %r11
vbroadcastss PRE(log_x_min)(%rip), %ymm9
vbroadcastss PRE(exp_coef)(%rip), %ymm3
vbroadcastss PRE(exp_coef)+4(%rip), %ymm4
vbroadcastss PRE(exp_coef)+8(%rip), %ymm5
vbroadcastss PRE(exp_coef)+12(%rip), %ymm6
vbroadcastss PRE(exp_coef)+16(%rip), %ymm7
vbroadcastss PRE(exp_coef)+20(%rip), %ymm8
mov %r11, %rcx
jmp .L14
.balign 32
.L13:
vmovups (%rsi), %ymm0
vmovups 32(%rsi), %ymm1
vmovups 64(%rsi), %ymm2
add $96, %rsi
vmaxps %ymm9, %ymm0, %ymm0
vmaxps %ymm9, %ymm1, %ymm1
vmaxps %ymm9, %ymm2, %ymm2
vbroadcastss PRE(log2_e)(%rip), %ymm13
vmulps %ymm13, %ymm0, %ymm10
vmulps %ymm13, %ymm1, %ymm11
vmulps %ymm13, %ymm2, %ymm12
vcvtps2dq %ymm10, %ymm0
vcvtps2dq %ymm11, %ymm1
vcvtps2dq %ymm12, %ymm2
vcvtdq2ps %ymm0, %ymm13
vcvtdq2ps %ymm1, %ymm14
vcvtdq2ps %ymm2, %ymm15
vsubps %ymm13, %ymm10, %ymm10
vsubps %ymm14, %ymm11, %ymm11
vsubps %ymm15, %ymm12, %ymm12
vpbroadcastd PRE(i127)(%rip), %ymm13
vpaddd %ymm13, %ymm0, %ymm0
vpaddd %ymm13, %ymm1, %ymm1
vpaddd %ymm13, %ymm2, %ymm2
vpslld $23, %ymm0, %ymm0
vpslld $23, %ymm1, %ymm1
vpslld $23, %ymm2, %ymm2
vmovaps %ymm8, %ymm13
vmovaps %ymm8, %ymm14
vmovaps %ymm8, %ymm15
vfmadd213ps %ymm7, %ymm10, %ymm13
vfmadd213ps %ymm7, %ymm11, %ymm14
vfmadd213ps %ymm7, %ymm12, %ymm15
vfmadd213ps %ymm6, %ymm10, %ymm13
vfmadd213ps %ymm6, %ymm11, %ymm14
vfmadd213ps %ymm6, %ymm12, %ymm15
vfmadd213ps %ymm5, %ymm10, %ymm13
vfmadd213ps %ymm5, %ymm11, %ymm14
vfmadd213ps %ymm5, %ymm12, %ymm15
vfmadd213ps %ymm4, %ymm10, %ymm13
vfmadd213ps %ymm4, %ymm11, %ymm14
vfmadd213ps %ymm4, %ymm12, %ymm15
vfmadd213ps %ymm3, %ymm10, %ymm13
vfmadd213ps %ymm3, %ymm11, %ymm14
vfmadd213ps %ymm3, %ymm12, %ymm15
vmulps %ymm13, %ymm0, %ymm0
vmulps %ymm14, %ymm1, %ymm1
vmulps %ymm15, %ymm2, %ymm2
vmovups %ymm0, (%rdi)
vmovups %ymm1, 32(%rdi)
vmovups %ymm2, 64(%rdi)
add $96, %rdi
sub $24, %r11
.L14:
cmp $24, %r11
jae .L13
jmp .L16
.balign 32
.L15:
vmovups (%rsi), %ymm0
add $32, %rsi
vmaxps %ymm9, %ymm0, %ymm0
vbroadcastss PRE(log2_e)(%rip), %ymm11
vmulps %ymm11, %ymm0, %ymm10
vcvtps2dq %ymm10, %ymm0
vcvtdq2ps %ymm0, %ymm11
vsubps %ymm11, %ymm10, %ymm10
vpbroadcastd PRE(i127)(%rip), %ymm11
vpaddd %ymm11, %ymm0, %ymm0
vpslld $23, %ymm0, %ymm0
vmovaps %ymm8, %ymm11
vfmadd213ps %ymm7, %ymm10, %ymm11
vfmadd213ps %ymm6, %ymm10, %ymm11
vfmadd213ps %ymm5, %ymm10, %ymm11
vfmadd213ps %ymm4, %ymm10, %ymm11
vfmadd213ps %ymm3, %ymm10, %ymm11
vmulps %ymm11, %ymm0, %ymm0
vmovups %ymm0, (%rdi)
add $32, %rdi
sub $8, %r11
.L16:
cmp $8, %r11
jae .L15
.L17:
and $7, %ecx
jz .L20
xor %rdx, %rdx
.L18:
mov (%rsi,%rdx,4), %eax
mov %eax, (%rsp,%rdx,4)
add $1, %rdx
cmp %rcx, %rdx
jne .L18
vmovups (%rsp), %ymm0
vmaxps %ymm9, %ymm0, %ymm0
vbroadcastss PRE(log2_e)(%rip), %ymm11
vmulps %ymm11, %ymm0, %ymm10
vcvtps2dq %ymm10, %ymm0
vcvtdq2ps %ymm0, %ymm11
vsubps %ymm11, %ymm10, %ymm10
vpbroadcastd PRE(i127)(%rip), %ymm11
vpaddd %ymm11, %ymm0, %ymm0
vpslld $23, %ymm0, %ymm0
vmovaps %ymm8, %ymm11
vfmadd213ps %ymm7, %ymm10, %ymm11
vfmadd213ps %ymm6, %ymm10, %ymm11
vfmadd213ps %ymm5, %ymm10, %ymm11
vfmadd213ps %ymm4, %ymm10, %ymm11
vfmadd213ps %ymm3, %ymm10, %ymm11
vmulps %ymm11, %ymm0, %ymm0
vmovups %ymm0, (%rsp)
xor %rdx, %rdx
.L19:
mov (%rsp,%rdx,4), %eax
mov %eax, (%rdi,%rdx,4)
add $1, %rdx
cmp %rcx, %rdx
jne .L19
.L20:
vzeroupper
add $40, %rsp
ret
SIZE(fmath_expf_v_avx2)
.balign 16
.global PRE(fmath_logf_v_avx2)
PRE(fmath_logf_v_avx2):
TYPE(fmath_logf_v_avx2)
sub $40, %rsp
mov %rdx, %r11
mov $1065353216, %eax
vpbroadcastd %eax, %ymm1
vmovaps PRE(log2_A0)(%rip), %ymm7
vmovaps PRE(log2_coef)+64(%rip), %ymm8
vmovups PRE(log2_tbl1)(%rip), %ymm2
vmovups PRE(log2_tbl1)+32(%rip), %ymm3
vmovups PRE(log2_tbl2)(%rip), %ymm4
vmovups PRE(log2_tbl2)+32(%rip), %ymm5
mov %r11, %rcx
jmp .L22
.balign 32
.L21:
vmovups (%rsi), %ymm0
add $32, %rsi
vgetexpps %ymm0, %ymm9
vgetmantps $0, %ymm0, %ymm0
vmovaps %ymm0, %ymm10
vfmadd213ps PRE(log2_A1)(%rip), %ymm7, %ymm10
vcmpgeps PRE(log2_A2)(%rip), %ymm0, %ymm12
vandps %ymm12, %ymm1, %ymm13
vaddps %ymm13, %ymm9, %ymm9
vblendvps %ymm12, PRE(log2_A3)(%rip), %ymm1, %ymm13
vmulps %ymm13, %ymm0, %ymm0
vpermps %ymm2, %ymm10, %ymm12
vpermps %ymm3, %ymm10, %ymm13
vpslld $28, %ymm10, %ymm11
vblendvps %ymm11, %ymm13, %ymm12, %ymm11
vfmsub213ps %ymm1, %ymm11, %ymm0
vpermps %ymm4, %ymm10, %ymm12
vpermps %ymm5, %ymm10, %ymm13
vpslld $28, %ymm10, %ymm10
vblendvps %ymm10, %ymm13, %ymm12, %ymm10
vmovaps %ymm8, %ymm11
vfmadd213ps PRE(log2_coef)+32(%rip), %ymm0, %ymm11
vfmadd213ps PRE(log2_coef)(%rip), %ymm0, %ymm11
vfmadd213ps %ymm1, %ymm0, %ymm11
vfmadd132ps PRE(log2_A4)(%rip), %ymm10, %ymm9
vfmadd213ps %ymm9, %ymm11, %ymm0
vmovups %ymm0, (%rdi)
add $32, %rdi
sub $8, %r11
.L22:
cmp $8, %r11
jae .L21
jmp .L24
.balign 32
.L23:
vmovups (%rsi), %ymm0
add $32, %rsi
vgetexpps %ymm0, %ymm9
vgetmantps $0, %ymm0, %ymm0
vmovaps %ymm0, %ymm10
vfmadd213ps PRE(log2_A1)(%rip), %ymm7, %ymm10
vcmpgeps PRE(log2_A2)(%rip), %ymm0, %ymm12
vandps %ymm12, %ymm1, %ymm13
vaddps %ymm13, %ymm9, %ymm9
vblendvps %ymm12, PRE(log2_A3)(%rip), %ymm1, %ymm13
vmulps %ymm13, %ymm0, %ymm0
vpermps %ymm2, %ymm10, %ymm12
vpermps %ymm3, %ymm10, %ymm13
vpslld $28, %ymm10, %ymm11
vblendvps %ymm11, %ymm13, %ymm12, %ymm11
vfmsub213ps %ymm1, %ymm11, %ymm0
vpermps %ymm4, %ymm10, %ymm12
vpermps %ymm5, %ymm10, %ymm13
vpslld $28, %ymm10, %ymm10
vblendvps %ymm10, %ymm13, %ymm12, %ymm10
vmovaps %ymm8, %ymm11
vfmadd213ps PRE(log2_coef)+32(%rip), %ymm0, %ymm11
vfmadd213ps PRE(log2_coef)(%rip), %ymm0, %ymm11
vfmadd213ps %ymm1, %ymm0, %ymm11
vfmadd132ps PRE(log2_A4)(%rip), %ymm10, %ymm9
vfmadd213ps %ymm9, %ymm11, %ymm0
vmovups %ymm0, (%rdi)
add $32, %rdi
sub $8, %r11
.L24:
cmp $8, %r11
jae .L23
.L25:
and $7, %ecx
jz .L28
xor %rdx, %rdx
.L26:
mov (%rsi,%rdx,4), %eax
mov %eax, (%rsp,%rdx,4)
add $1, %rdx
cmp %rcx, %rdx
jne .L26
vmovups (%rsp), %ymm0
vgetexpps %ymm0, %ymm9
vgetmantps $0, %ymm0, %ymm0
vmovaps %ymm0, %ymm10
vfmadd213ps PRE(log2_A1)(%rip), %ymm7, %ymm10
vcmpgeps PRE(log2_A2)(%rip), %ymm0, %ymm12
vandps %ymm12, %ymm1, %ymm13
vaddps %ymm13, %ymm9, %ymm9
vblendvps %ymm12, PRE(log2_A3)(%rip), %ymm1, %ymm13
vmulps %ymm13, %ymm0, %ymm0
vpermps %ymm2, %ymm10, %ymm12
vpermps %ymm3, %ymm10, %ymm13
vpslld $28, %ymm10, %ymm11
vblendvps %ymm11, %ymm13, %ymm12, %ymm11
vfmsub213ps %ymm1, %ymm11, %ymm0
vpermps %ymm4, %ymm10, %ymm12
vpermps %ymm5, %ymm10, %ymm13
vpslld $28, %ymm10, %ymm10
vblendvps %ymm10, %ymm13, %ymm12, %ymm10
vmovaps %ymm8, %ymm11
vfmadd213ps PRE(log2_coef)+32(%rip), %ymm0, %ymm11
vfmadd213ps PRE(log2_coef)(%rip), %ymm0, %ymm11
vfmadd213ps %ymm1, %ymm0, %ymm11
vfmadd132ps PRE(log2_A4)(%rip), %ymm10, %ymm9
vfmadd213ps %ymm9, %ymm11, %ymm0
vmovups %ymm0, (%rsp)
xor %rdx, %rdx
.L27:
mov (%rsp,%rdx,4), %eax
mov %eax, (%rdi,%rdx,4)
add $1, %rdx
cmp %rcx, %rdx
jne .L27
.L28:
vzeroupper
add $40, %rsp
ret
SIZE(fmath_logf_v_avx2)
