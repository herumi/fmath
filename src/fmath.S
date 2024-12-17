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
.balign 32
PRE(log_coef):
.long 0x3f800000,0xbf000000,0x3eaab2d3,0xbe800b20
PRE(log2):
.long 0x3f317218
PRE(_0x7fffffff):
.long 0x7fffffff
PRE(log_boundary):
.long 0x3ca3d70a
PRE(NaN):
.long 0x7fc00000
PRE(minusInf):
.long 0xff800000
PRE(log_tbl1):
.long 0x3f783e10,0x3f6a0ea1,0x3f5d67c9,0x3f520d21,0x3f47ce0c,0x3f3e82fa,0x3f360b61,0x3f2e4c41,0x3f272f05,0x3f20a0a1,0x3f1a90e8,0x3f14f209,0x3f0fb824,0x3f0ad8f3,0x3f064b8a,0x3f020821
PRE(log_tbl2):
.long 0xbcfc14c8,0xbdb78694,0xbe14aa96,0xbe4a92d4,0xbe7dc8c6,0xbe974716,0xbeae8ded,0xbec4d19d,0xbeda27bd,0xbeeea34f,0xbf012a95,0xbf0aa61f,0xbf13caf0,0xbf1c9f07,0xbf2527c4,0xbf2d6a01
.text
.balign 16
.global PRE(fmath_expf_avx512)
PRE(fmath_expf_avx512):
TYPE(fmath_expf_avx512)
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
SIZE(fmath_expf_avx512)
.balign 16
.global PRE(fmath_logf_avx512)
PRE(fmath_logf_avx512):
TYPE(fmath_logf_avx512)
mov $1065353216, %eax
vpbroadcastd %eax, %zmm4
vbroadcastss PRE(log_coef)+12(%rip), %zmm8
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
vmovaps %zmm0, %zmm21
vmovaps %zmm1, %zmm22
vmovaps %zmm2, %zmm23
vmovaps %zmm3, %zmm24
vgetexpps %zmm0, %zmm9
vgetexpps %zmm1, %zmm10
vgetexpps %zmm2, %zmm11
vgetexpps %zmm3, %zmm12
vgetmantps $0, %zmm0, %zmm0
vgetmantps $0, %zmm1, %zmm1
vgetmantps $0, %zmm2, %zmm2
vgetmantps $0, %zmm3, %zmm3
vpsrad $19, %zmm0, %zmm13
vpsrad $19, %zmm1, %zmm14
vpsrad $19, %zmm2, %zmm15
vpsrad $19, %zmm3, %zmm16
vpermps %zmm5, %zmm13, %zmm17
vpermps %zmm5, %zmm14, %zmm18
vpermps %zmm5, %zmm15, %zmm19
vpermps %zmm5, %zmm16, %zmm20
vfmsub213ps %zmm4, %zmm17, %zmm0
vfmsub213ps %zmm4, %zmm18, %zmm1
vfmsub213ps %zmm4, %zmm19, %zmm2
vfmsub213ps %zmm4, %zmm20, %zmm3
vpermps %zmm6, %zmm13, %zmm17
vpermps %zmm6, %zmm14, %zmm18
vpermps %zmm6, %zmm15, %zmm19
vpermps %zmm6, %zmm16, %zmm20
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm17, %zmm9
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm18, %zmm10
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm19, %zmm11
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm20, %zmm12
vsubps %zmm4, %zmm21, %zmm13
vsubps %zmm4, %zmm22, %zmm14
vsubps %zmm4, %zmm23, %zmm15
vsubps %zmm4, %zmm24, %zmm16
vandps PRE(_0x7fffffff)(%rip){1to16}, %zmm13, %zmm17
vandps PRE(_0x7fffffff)(%rip){1to16}, %zmm14, %zmm18
vandps PRE(_0x7fffffff)(%rip){1to16}, %zmm15, %zmm19
vandps PRE(_0x7fffffff)(%rip){1to16}, %zmm16, %zmm20
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm17, %k2
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm18, %k3
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm19, %k4
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm20, %k5
vmovaps %zmm13, %zmm0{%k2}
vmovaps %zmm14, %zmm1{%k3}
vmovaps %zmm15, %zmm2{%k4}
vmovaps %zmm16, %zmm3{%k5}
vxorps %zmm9, %zmm9, %zmm9{%k2}
vxorps %zmm10, %zmm10, %zmm10{%k3}
vxorps %zmm11, %zmm11, %zmm11{%k4}
vxorps %zmm12, %zmm12, %zmm12{%k5}
vmovaps %zmm8, %zmm13
vmovaps %zmm8, %zmm14
vmovaps %zmm8, %zmm15
vmovaps %zmm8, %zmm16
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm0, %zmm13
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm1, %zmm14
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm2, %zmm15
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm3, %zmm16
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm13
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm1, %zmm14
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm2, %zmm15
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm3, %zmm16
vfmadd213ps %zmm4, %zmm0, %zmm13
vfmadd213ps %zmm4, %zmm1, %zmm14
vfmadd213ps %zmm4, %zmm2, %zmm15
vfmadd213ps %zmm4, %zmm3, %zmm16
vfmadd213ps %zmm9, %zmm13, %zmm0
vfmadd213ps %zmm10, %zmm14, %zmm1
vfmadd213ps %zmm11, %zmm15, %zmm2
vfmadd213ps %zmm12, %zmm16, %zmm3
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
vmovaps %zmm0, %zmm12
vgetexpps %zmm0, %zmm9
vgetmantps $0, %zmm0, %zmm0
vpsrad $19, %zmm0, %zmm10
vpermps %zmm5, %zmm10, %zmm11
vfmsub213ps %zmm4, %zmm11, %zmm0
vpermps %zmm6, %zmm10, %zmm11
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm11, %zmm9
vsubps %zmm4, %zmm12, %zmm10
vandps PRE(_0x7fffffff)(%rip){1to16}, %zmm10, %zmm11
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm11, %k2
vmovaps %zmm10, %zmm0{%k2}
vxorps %zmm9, %zmm9, %zmm9{%k2}
vmovaps %zmm8, %zmm10
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm0, %zmm10
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm10
vfmadd213ps %zmm4, %zmm0, %zmm10
vfmadd213ps %zmm9, %zmm10, %zmm0
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
vmovaps %zmm0, %zmm12
vgetexpps %zmm0, %zmm9
vgetmantps $0, %zmm0, %zmm0
vpsrad $19, %zmm0, %zmm10
vpermps %zmm5, %zmm10, %zmm11
vfmsub213ps %zmm4, %zmm11, %zmm0
vpermps %zmm6, %zmm10, %zmm11
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm11, %zmm9
vsubps %zmm4, %zmm12, %zmm10
vandps PRE(_0x7fffffff)(%rip){1to16}, %zmm10, %zmm11
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm11, %k2
vmovaps %zmm10, %zmm0{%k2}
vxorps %zmm9, %zmm9, %zmm9{%k2}
vmovaps %zmm8, %zmm10
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm0, %zmm10
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm10
vfmadd213ps %zmm4, %zmm0, %zmm10
vfmadd213ps %zmm9, %zmm10, %zmm0
vmovups %zmm0, (%rdi){%k1}
.L12:
vzeroupper
ret
SIZE(fmath_logf_avx512)
