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
.long 0xbefffff1,0x3eaab75e,0xbe7d89be
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
PRE(log_f1):
.long 0x3f800000
PRE(log_tbl1):
.long 0x3f800000,0x3f714325,0x3f63935c,0x3f579ab0,0x3f4cd493,0x3f430d7c,0x3f3a362e,0x3f321ad9,0x3faab290,0x3fa3d442,0x3f9d8e21,0x3f97b209,0x3f924ab4,0x3f8d40cc,0x3f888c66,0x3f826c3c
PRE(log_tbl2):
.long 0x0,0x3d72dcff,0x3df10a00,0x3e2fdac0,0x3e6458e0,0x3e8b3780,0x3ea2f760,0x3eb9c190,0xbe9362c0,0xbe7cb780,0xbe54bb40,0xbe2debc0,0xbe08c760,0xbdc9c681,0xbd8466bf,0xbc999c00
.balign 64
PRE(log_coef_tq):
.long 0xbefffff1,0x3eaabbde,0xbe7dc247
PRE(log_A0_tq):
.long 0x3f7ece44
PRE(log_A1_tq):
.long 0x49000000
PRE(log_A2_tq):
.long 0x3fbce194
PRE(log_A3_tq):
.long 0x3f000000
PRE(log_A4_tq):
.long 0x3f317218
PRE(log_f1_tq):
.long 0x3f800000
PRE(log_tbl1_tq):
.long 0x3f800000,0x3f714325,0x3f63935c,0x3f579ab0,0x3f4cd493,0x3f430d7c,0x3f3a362e,0x3f321ad9,0x3faab290,0x3fa3d442,0x3f9d8e21,0x3f97b209,0x3f9249dd,0x3f8d40cc,0x3f888c66,0x3f826c3c
PRE(log_tbl2_tq):
.long 0x0,0x3d72dcff,0x3df10a00,0x3e2fdac0,0x3e6458e0,0x3e8b3780,0x3ea2f760,0x3eb9c190,0xbe9362c0,0xbe7cb780,0xbe54bb40,0xbe2debc0,0xbe08c17f,0xbdc9c681,0xbd8466bf,0xbc999c00
PRE(i127):
.long 127
PRE(log_x_min):
.long 0xc2b0c0a5
PRE(Inf):
.long 0x7f800000
.balign 64
PRE(log2_0x7fffffff):
.long 2147483647,2147483647,2147483647,2147483647,2147483647,2147483647,2147483647,2147483647
PRE(log2_f127):
.long 0x42fe0000,0x42fe0000,0x42fe0000,0x42fe0000,0x42fe0000,0x42fe0000,0x42fe0000,0x42fe0000
PRE(log2_0xffffff):
.long 16777215,16777215,16777215,16777215,16777215,16777215,16777215,16777215
PRE(log2_ROUND):
.long 0x49800000,0x49800000,0x49800000,0x49800000,0x49800000,0x49800000,0x49800000,0x49800000
PRE(log2_BOUND):
.long 0x3fb80000,0x3fb80000,0x3fb80000,0x3fb80000,0x3fb80000,0x3fb80000,0x3fb80000,0x3fb80000
PRE(log2_f1):
.long 0x3f800000,0x3f800000,0x3f800000,0x3f800000,0x3f800000,0x3f800000,0x3f800000,0x3f800000
PRE(log2_f0p5):
.long 0x3f000000,0x3f000000,0x3f000000,0x3f000000,0x3f000000,0x3f000000,0x3f000000,0x3f000000
PRE(log2_A):
.long 0xbeffffe9,0xbeffffe9,0xbeffffe9,0xbeffffe9,0xbeffffe9,0xbeffffe9,0xbeffffe9,0xbeffffe9
PRE(log2_B):
.long 0x3eaaab5a,0x3eaaab5a,0x3eaaab5a,0x3eaaab5a,0x3eaaab5a,0x3eaaab5a,0x3eaaab5a,0x3eaaab5a
PRE(log2_C):
.long 0xbe80782a,0xbe80782a,0xbe80782a,0xbe80782a,0xbe80782a,0xbe80782a,0xbe80782a,0xbe80782a
PRE(log2_D):
.long 0x3e4bf6e6,0x3e4bf6e6,0x3e4bf6e6,0x3e4bf6e6,0x3e4bf6e6,0x3e4bf6e6,0x3e4bf6e6,0x3e4bf6e6
PRE(log2_log2):
.long 0x3f317218,0x3f317218,0x3f317218,0x3f317218,0x3f317218,0x3f317218,0x3f317218,0x3f317218
.balign 64
PRE(log2_tbl1):
.long 0x3f800000,0x3f63922c,0x3f4cccf3,0x3f3a2e8b,0x3faaae90,0x3f9d8ddc,0x3f924794,0x3f888537
PRE(log2_tbl2):
.long 0x0,0x3df114b0,0x3e647eff,0x3ea30c60,0xbe9356c0,0xbe54b980,0xbe08b180,0xbd83fafe
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
vbroadcastss PRE(log_A0)(%rip), %zmm7
vbroadcastss PRE(log_coef)+8(%rip), %zmm8
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
vgetexpps %zmm0, %zmm9
vgetexpps %zmm1, %zmm10
vgetexpps %zmm2, %zmm11
vgetexpps %zmm3, %zmm12
vgetmantps $0, %zmm0, %zmm0
vgetmantps $0, %zmm1, %zmm1
vgetmantps $0, %zmm2, %zmm2
vgetmantps $0, %zmm3, %zmm3
vmovaps %zmm0, %zmm13
vmovaps %zmm1, %zmm14
vmovaps %zmm2, %zmm15
vmovaps %zmm3, %zmm16
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm7, %zmm13
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm7, %zmm14
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm7, %zmm15
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm7, %zmm16
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm0, %k2
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm1, %k3
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm2, %k4
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm3, %k5
vaddps %zmm4, %zmm9, %zmm9{%k2}
vaddps %zmm4, %zmm10, %zmm10{%k3}
vaddps %zmm4, %zmm11, %zmm11{%k4}
vaddps %zmm4, %zmm12, %zmm12{%k5}
vmulps PRE(log_A3)(%rip){1to16}, %zmm0, %zmm0{%k2}
vmulps PRE(log_A3)(%rip){1to16}, %zmm1, %zmm1{%k3}
vmulps PRE(log_A3)(%rip){1to16}, %zmm2, %zmm2{%k4}
vmulps PRE(log_A3)(%rip){1to16}, %zmm3, %zmm3{%k5}
vpermps %zmm5, %zmm13, %zmm17
vpermps %zmm5, %zmm14, %zmm18
vpermps %zmm5, %zmm15, %zmm19
vpermps %zmm5, %zmm16, %zmm20
vfmsub213ps %zmm4, %zmm17, %zmm0
vfmsub213ps %zmm4, %zmm18, %zmm1
vfmsub213ps %zmm4, %zmm19, %zmm2
vfmsub213ps %zmm4, %zmm20, %zmm3
vpermps %zmm6, %zmm13, %zmm13
vpermps %zmm6, %zmm14, %zmm14
vpermps %zmm6, %zmm15, %zmm15
vpermps %zmm6, %zmm16, %zmm16
vmovaps %zmm8, %zmm17
vmovaps %zmm8, %zmm18
vmovaps %zmm8, %zmm19
vmovaps %zmm8, %zmm20
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm17
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm1, %zmm18
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm2, %zmm19
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm3, %zmm20
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm0, %zmm17
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm1, %zmm18
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm2, %zmm19
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm3, %zmm20
vfmadd213ps %zmm4, %zmm0, %zmm17
vfmadd213ps %zmm4, %zmm1, %zmm18
vfmadd213ps %zmm4, %zmm2, %zmm19
vfmadd213ps %zmm4, %zmm3, %zmm20
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm13, %zmm9
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm14, %zmm10
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm15, %zmm11
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm16, %zmm12
vfmadd213ps %zmm9, %zmm17, %zmm0
vfmadd213ps %zmm10, %zmm18, %zmm1
vfmadd213ps %zmm11, %zmm19, %zmm2
vfmadd213ps %zmm12, %zmm20, %zmm3
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
vgetexpps %zmm0, %zmm9
vgetmantps $0, %zmm0, %zmm0
vmovaps %zmm0, %zmm10
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm7, %zmm10
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm0, %k2
vaddps %zmm4, %zmm9, %zmm9{%k2}
vmulps PRE(log_A3)(%rip){1to16}, %zmm0, %zmm0{%k2}
vpermps %zmm5, %zmm10, %zmm11
vfmsub213ps %zmm4, %zmm11, %zmm0
vpermps %zmm6, %zmm10, %zmm10
vmovaps %zmm8, %zmm11
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm11
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm0, %zmm11
vfmadd213ps %zmm4, %zmm0, %zmm11
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm10, %zmm9
vfmadd213ps %zmm9, %zmm11, %zmm0
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
vgetexpps %zmm0, %zmm9
vgetmantps $0, %zmm0, %zmm0
vmovaps %zmm0, %zmm10
vfmadd213ps PRE(log_A1)(%rip){1to16}, %zmm7, %zmm10
vcmpgeps PRE(log_A2)(%rip){1to16}, %zmm0, %k2
vaddps %zmm4, %zmm9, %zmm9{%k2}
vmulps PRE(log_A3)(%rip){1to16}, %zmm0, %zmm0{%k2}
vpermps %zmm5, %zmm10, %zmm11
vfmsub213ps %zmm4, %zmm11, %zmm0
vpermps %zmm6, %zmm10, %zmm10
vmovaps %zmm8, %zmm11
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm11
vfmadd213ps PRE(log_coef)(%rip){1to16}, %zmm0, %zmm11
vfmadd213ps %zmm4, %zmm0, %zmm11
vfmadd132ps PRE(log_A4)(%rip){1to16}, %zmm10, %zmm9
vfmadd213ps %zmm9, %zmm11, %zmm0
vmovups %zmm0, (%rdi){%k1}
.L12:
vzeroupper
ret
SIZE(fmath_logf_v_avx512)
.balign 16
.global PRE(fmath_logf_v_avx512_tq)
PRE(fmath_logf_v_avx512_tq):
TYPE(fmath_logf_v_avx512_tq)
mov $1065353216, %eax
vpbroadcastd %eax, %zmm4
vbroadcastss PRE(log_A0_tq)(%rip), %zmm7
vbroadcastss PRE(log_coef_tq)+8(%rip), %zmm8
vmovups PRE(log_tbl1_tq)(%rip), %zmm5
vmovups PRE(log_tbl2_tq)(%rip), %zmm6
mov %rdx, %rcx
jmp .L14
.balign 32
.L13:
vmovups (%rsi), %zmm0
vmovups 64(%rsi), %zmm1
vmovups 128(%rsi), %zmm2
vmovups 192(%rsi), %zmm3
add $256, %rsi
vgetexpps %zmm0, %zmm9
vgetexpps %zmm1, %zmm10
vgetexpps %zmm2, %zmm11
vgetexpps %zmm3, %zmm12
vgetmantps $0, %zmm0, %zmm0
vgetmantps $0, %zmm1, %zmm1
vgetmantps $0, %zmm2, %zmm2
vgetmantps $0, %zmm3, %zmm3
vmovaps %zmm0, %zmm13
vmovaps %zmm1, %zmm14
vmovaps %zmm2, %zmm15
vmovaps %zmm3, %zmm16
vfmadd213ps PRE(log_A1_tq)(%rip){1to16}, %zmm7, %zmm13
vfmadd213ps PRE(log_A1_tq)(%rip){1to16}, %zmm7, %zmm14
vfmadd213ps PRE(log_A1_tq)(%rip){1to16}, %zmm7, %zmm15
vfmadd213ps PRE(log_A1_tq)(%rip){1to16}, %zmm7, %zmm16
vcmpgeps PRE(log_A2_tq)(%rip){1to16}, %zmm0, %k2
vcmpgeps PRE(log_A2_tq)(%rip){1to16}, %zmm1, %k3
vcmpgeps PRE(log_A2_tq)(%rip){1to16}, %zmm2, %k4
vcmpgeps PRE(log_A2_tq)(%rip){1to16}, %zmm3, %k5
vaddps %zmm4, %zmm9, %zmm9{%k2}
vaddps %zmm4, %zmm10, %zmm10{%k3}
vaddps %zmm4, %zmm11, %zmm11{%k4}
vaddps %zmm4, %zmm12, %zmm12{%k5}
vmulps PRE(log_A3_tq)(%rip){1to16}, %zmm0, %zmm0{%k2}
vmulps PRE(log_A3_tq)(%rip){1to16}, %zmm1, %zmm1{%k3}
vmulps PRE(log_A3_tq)(%rip){1to16}, %zmm2, %zmm2{%k4}
vmulps PRE(log_A3_tq)(%rip){1to16}, %zmm3, %zmm3{%k5}
vpermps %zmm5, %zmm13, %zmm17
vpermps %zmm5, %zmm14, %zmm18
vpermps %zmm5, %zmm15, %zmm19
vpermps %zmm5, %zmm16, %zmm20
vfmsub213ps %zmm4, %zmm17, %zmm0
vfmsub213ps %zmm4, %zmm18, %zmm1
vfmsub213ps %zmm4, %zmm19, %zmm2
vfmsub213ps %zmm4, %zmm20, %zmm3
vpermps %zmm6, %zmm13, %zmm13
vpermps %zmm6, %zmm14, %zmm14
vpermps %zmm6, %zmm15, %zmm15
vpermps %zmm6, %zmm16, %zmm16
vfmadd132ps PRE(log_A4_tq)(%rip){1to16}, %zmm13, %zmm9
vfmadd132ps PRE(log_A4_tq)(%rip){1to16}, %zmm14, %zmm10
vfmadd132ps PRE(log_A4_tq)(%rip){1to16}, %zmm15, %zmm11
vfmadd132ps PRE(log_A4_tq)(%rip){1to16}, %zmm16, %zmm12
vmovaps %zmm8, %zmm13
vmovaps %zmm8, %zmm14
vmovaps %zmm8, %zmm15
vmovaps %zmm8, %zmm16
vfmadd213ps PRE(log_coef_tq)+4(%rip){1to16}, %zmm0, %zmm13
vfmadd213ps PRE(log_coef_tq)+4(%rip){1to16}, %zmm1, %zmm14
vfmadd213ps PRE(log_coef_tq)+4(%rip){1to16}, %zmm2, %zmm15
vfmadd213ps PRE(log_coef_tq)+4(%rip){1to16}, %zmm3, %zmm16
vfmadd213ps PRE(log_coef_tq)(%rip){1to16}, %zmm0, %zmm13
vfmadd213ps PRE(log_coef_tq)(%rip){1to16}, %zmm1, %zmm14
vfmadd213ps PRE(log_coef_tq)(%rip){1to16}, %zmm2, %zmm15
vfmadd213ps PRE(log_coef_tq)(%rip){1to16}, %zmm3, %zmm16
vmulps %zmm0, %zmm0, %zmm17
vmulps %zmm1, %zmm1, %zmm18
vmulps %zmm2, %zmm2, %zmm19
vmulps %zmm3, %zmm3, %zmm20
vfmadd213ps %zmm0, %zmm13, %zmm17
vfmadd213ps %zmm1, %zmm14, %zmm18
vfmadd213ps %zmm2, %zmm15, %zmm19
vfmadd213ps %zmm3, %zmm16, %zmm20
vaddps %zmm9, %zmm17, %zmm0
vaddps %zmm10, %zmm18, %zmm1
vaddps %zmm11, %zmm19, %zmm2
vaddps %zmm12, %zmm20, %zmm3
vmovups %zmm0, (%rdi)
vmovups %zmm1, 64(%rdi)
vmovups %zmm2, 128(%rdi)
vmovups %zmm3, 192(%rdi)
add $256, %rdi
sub $64, %rdx
.L14:
cmp $64, %rdx
jae .L13
jmp .L16
.balign 32
.L15:
vmovups (%rsi), %zmm0
add $64, %rsi
vgetexpps %zmm0, %zmm9
vgetmantps $0, %zmm0, %zmm0
vmovaps %zmm0, %zmm10
vfmadd213ps PRE(log_A1_tq)(%rip){1to16}, %zmm7, %zmm10
vcmpgeps PRE(log_A2_tq)(%rip){1to16}, %zmm0, %k2
vaddps %zmm4, %zmm9, %zmm9{%k2}
vmulps PRE(log_A3_tq)(%rip){1to16}, %zmm0, %zmm0{%k2}
vpermps %zmm5, %zmm10, %zmm11
vfmsub213ps %zmm4, %zmm11, %zmm0
vpermps %zmm6, %zmm10, %zmm10
vfmadd132ps PRE(log_A4_tq)(%rip){1to16}, %zmm10, %zmm9
vmovaps %zmm8, %zmm10
vfmadd213ps PRE(log_coef_tq)+4(%rip){1to16}, %zmm0, %zmm10
vfmadd213ps PRE(log_coef_tq)(%rip){1to16}, %zmm0, %zmm10
vmulps %zmm0, %zmm0, %zmm11
vfmadd213ps %zmm0, %zmm10, %zmm11
vaddps %zmm9, %zmm11, %zmm0
vmovups %zmm0, (%rdi)
add $64, %rdi
sub $16, %rdx
.L16:
cmp $16, %rdx
jae .L15
.L17:
and $15, %ecx
jz .L18
mov $1, %eax
shl %cl, %eax
sub $1, %eax
kmovd %eax, %k1
vmovups (%rsi), %zmm0{%k1}{z}
vgetexpps %zmm0, %zmm9
vgetmantps $0, %zmm0, %zmm0
vmovaps %zmm0, %zmm10
vfmadd213ps PRE(log_A1_tq)(%rip){1to16}, %zmm7, %zmm10
vcmpgeps PRE(log_A2_tq)(%rip){1to16}, %zmm0, %k2
vaddps %zmm4, %zmm9, %zmm9{%k2}
vmulps PRE(log_A3_tq)(%rip){1to16}, %zmm0, %zmm0{%k2}
vpermps %zmm5, %zmm10, %zmm11
vfmsub213ps %zmm4, %zmm11, %zmm0
vpermps %zmm6, %zmm10, %zmm10
vfmadd132ps PRE(log_A4_tq)(%rip){1to16}, %zmm10, %zmm9
vmovaps %zmm8, %zmm10
vfmadd213ps PRE(log_coef_tq)+4(%rip){1to16}, %zmm0, %zmm10
vfmadd213ps PRE(log_coef_tq)(%rip){1to16}, %zmm0, %zmm10
vmulps %zmm0, %zmm0, %zmm11
vfmadd213ps %zmm0, %zmm10, %zmm11
vaddps %zmm9, %zmm11, %zmm0
vmovups %zmm0, (%rdi){%k1}
.L18:
vzeroupper
ret
SIZE(fmath_logf_v_avx512_tq)
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
jmp .L20
.balign 32
.L19:
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
.L20:
cmp $24, %r11
jae .L19
jmp .L22
.balign 32
.L21:
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
.L22:
cmp $8, %r11
jae .L21
.L23:
and $7, %ecx
jz .L26
xor %rdx, %rdx
.L24:
mov (%rsi,%rdx,4), %eax
mov %eax, (%rsp,%rdx,4)
add $1, %rdx
cmp %rcx, %rdx
jne .L24
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
.L25:
mov (%rsp,%rdx,4), %eax
mov %eax, (%rdi,%rdx,4)
add $1, %rdx
cmp %rcx, %rdx
jne .L25
.L26:
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
vmovaps PRE(log2_f1)(%rip), %ymm2
vmovaps PRE(log2_tbl1)(%rip), %ymm3
vmovaps PRE(log2_tbl2)(%rip), %ymm4
mov %r11, %rcx
jmp .L28
.balign 32
.L27:
vmovups (%rsi), %ymm0
vmovups 32(%rsi), %ymm1
add $64, %rsi
vandps PRE(log2_0x7fffffff)(%rip), %ymm0, %ymm5
vandps PRE(log2_0x7fffffff)(%rip), %ymm1, %ymm6
vpsrld $23, %ymm5, %ymm5
vpsrld $23, %ymm6, %ymm6
vcvtdq2ps %ymm5, %ymm5
vcvtdq2ps %ymm6, %ymm6
vsubps PRE(log2_f127)(%rip), %ymm5, %ymm5
vsubps PRE(log2_f127)(%rip), %ymm6, %ymm6
vandps PRE(log2_0xffffff)(%rip), %ymm0, %ymm0
vandps PRE(log2_0xffffff)(%rip), %ymm1, %ymm1
vorps %ymm2, %ymm0, %ymm0
vorps %ymm2, %ymm1, %ymm1
vaddps PRE(log2_ROUND)(%rip), %ymm0, %ymm7
vaddps PRE(log2_ROUND)(%rip), %ymm1, %ymm8
vcmpgeps PRE(log2_BOUND)(%rip), %ymm0, %ymm11
vandps %ymm11, %ymm2, %ymm12
vaddps %ymm12, %ymm5, %ymm5
vblendvps %ymm11, PRE(log2_f0p5)(%rip), %ymm2, %ymm12
vmulps %ymm12, %ymm0, %ymm0
vcmpgeps PRE(log2_BOUND)(%rip), %ymm1, %ymm11
vandps %ymm11, %ymm2, %ymm12
vaddps %ymm12, %ymm6, %ymm6
vblendvps %ymm11, PRE(log2_f0p5)(%rip), %ymm2, %ymm12
vmulps %ymm12, %ymm1, %ymm1
vpermps %ymm3, %ymm7, %ymm9
vpermps %ymm3, %ymm8, %ymm10
vpermps %ymm4, %ymm7, %ymm7
vpermps %ymm4, %ymm8, %ymm8
vfmsub213ps %ymm2, %ymm9, %ymm0
vfmsub213ps %ymm2, %ymm10, %ymm1
vmovaps PRE(log2_D)(%rip), %ymm9
vmovaps %ymm9, %ymm10
vfmadd213ps PRE(log2_C)(%rip), %ymm0, %ymm9
vfmadd213ps PRE(log2_C)(%rip), %ymm1, %ymm10
vfmadd213ps PRE(log2_B)(%rip), %ymm0, %ymm9
vfmadd213ps PRE(log2_B)(%rip), %ymm1, %ymm10
vfmadd213ps PRE(log2_A)(%rip), %ymm0, %ymm9
vfmadd213ps PRE(log2_A)(%rip), %ymm1, %ymm10
vfmadd213ps %ymm2, %ymm0, %ymm9
vfmadd213ps %ymm2, %ymm1, %ymm10
vfmadd132ps PRE(log2_log2)(%rip), %ymm7, %ymm5
vfmadd132ps PRE(log2_log2)(%rip), %ymm8, %ymm6
vfmadd213ps %ymm5, %ymm9, %ymm0
vfmadd213ps %ymm6, %ymm10, %ymm1
vmovups %ymm0, (%rdi)
vmovups %ymm1, 32(%rdi)
add $64, %rdi
sub $16, %r11
.L28:
cmp $16, %r11
jae .L27
jmp .L30
.balign 32
.L29:
vmovups (%rsi), %ymm0
add $32, %rsi
vandps PRE(log2_0x7fffffff)(%rip), %ymm0, %ymm5
vpsrld $23, %ymm5, %ymm5
vcvtdq2ps %ymm5, %ymm5
vsubps PRE(log2_f127)(%rip), %ymm5, %ymm5
vandps PRE(log2_0xffffff)(%rip), %ymm0, %ymm0
vorps %ymm2, %ymm0, %ymm0
vaddps PRE(log2_ROUND)(%rip), %ymm0, %ymm6
vcmpgeps PRE(log2_BOUND)(%rip), %ymm0, %ymm8
vandps %ymm8, %ymm2, %ymm9
vaddps %ymm9, %ymm5, %ymm5
vblendvps %ymm8, PRE(log2_f0p5)(%rip), %ymm2, %ymm9
vmulps %ymm9, %ymm0, %ymm0
vpermps %ymm3, %ymm6, %ymm7
vpermps %ymm4, %ymm6, %ymm6
vfmsub213ps %ymm2, %ymm7, %ymm0
vmovaps PRE(log2_D)(%rip), %ymm7
vfmadd213ps PRE(log2_C)(%rip), %ymm0, %ymm7
vfmadd213ps PRE(log2_B)(%rip), %ymm0, %ymm7
vfmadd213ps PRE(log2_A)(%rip), %ymm0, %ymm7
vfmadd213ps %ymm2, %ymm0, %ymm7
vfmadd132ps PRE(log2_log2)(%rip), %ymm6, %ymm5
vfmadd213ps %ymm5, %ymm7, %ymm0
vmovups %ymm0, (%rdi)
add $32, %rdi
sub $8, %r11
.L30:
cmp $8, %r11
jae .L29
.L31:
and $7, %ecx
jz .L34
xor %rdx, %rdx
.L32:
mov (%rsi,%rdx,4), %eax
mov %eax, (%rsp,%rdx,4)
add $1, %rdx
cmp %rcx, %rdx
jne .L32
vmovups (%rsp), %ymm0
vandps PRE(log2_0x7fffffff)(%rip), %ymm0, %ymm5
vpsrld $23, %ymm5, %ymm5
vcvtdq2ps %ymm5, %ymm5
vsubps PRE(log2_f127)(%rip), %ymm5, %ymm5
vandps PRE(log2_0xffffff)(%rip), %ymm0, %ymm0
vorps %ymm2, %ymm0, %ymm0
vaddps PRE(log2_ROUND)(%rip), %ymm0, %ymm6
vcmpgeps PRE(log2_BOUND)(%rip), %ymm0, %ymm8
vandps %ymm8, %ymm2, %ymm9
vaddps %ymm9, %ymm5, %ymm5
vblendvps %ymm8, PRE(log2_f0p5)(%rip), %ymm2, %ymm9
vmulps %ymm9, %ymm0, %ymm0
vpermps %ymm3, %ymm6, %ymm7
vpermps %ymm4, %ymm6, %ymm6
vfmsub213ps %ymm2, %ymm7, %ymm0
vmovaps PRE(log2_D)(%rip), %ymm7
vfmadd213ps PRE(log2_C)(%rip), %ymm0, %ymm7
vfmadd213ps PRE(log2_B)(%rip), %ymm0, %ymm7
vfmadd213ps PRE(log2_A)(%rip), %ymm0, %ymm7
vfmadd213ps %ymm2, %ymm0, %ymm7
vfmadd132ps PRE(log2_log2)(%rip), %ymm6, %ymm5
vfmadd213ps %ymm5, %ymm7, %ymm0
vmovups %ymm0, (%rsp)
xor %rdx, %rdx
.L33:
mov (%rsp,%rdx,4), %eax
mov %eax, (%rdi,%rdx,4)
add $1, %rdx
cmp %rcx, %rdx
jne .L33
.L34:
vzeroupper
add $40, %rsp
ret
SIZE(fmath_logf_v_avx2)
