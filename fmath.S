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
.align 32
PRE(exp_coef):
.long 0x3f800000
.long 0x3f317218
.long 0x3e75fd0b
.long 0x3d63578a
.long 0x3c1e6362
.long 0x3aaf9319
.align 32
PRE(log_coef):
.long 0x3f800000
.long 0xbf000000
.long 0x3eaab2d3
.long 0xbe800b20
PRE(log2):
.long 0x3f317218
PRE(abs_mask):
.long 0x7fffffff
PRE(log_boundary):
.long 0x3ca3d70a
PRE(log_nan):
.long 0x7fc00000
PRE(log_mInf):
.long 0xff800000
PRE(log_tbl1):
.long 0x3f783e10
.long 0x3f6a0ea1
.long 0x3f5d67c9
.long 0x3f520d21
.long 0x3f47ce0c
.long 0x3f3e82fa
.long 0x3f360b61
.long 0x3f2e4c41
.long 0x3f272f05
.long 0x3f20a0a1
.long 0x3f1a90e8
.long 0x3f14f209
.long 0x3f0fb824
.long 0x3f0ad8f3
.long 0x3f064b8a
.long 0x3f020821
PRE(log_tbl2):
.long 0xbcfc14c8
.long 0xbdb78694
.long 0xbe14aa96
.long 0xbe4a92d4
.long 0xbe7dc8c6
.long 0xbe974716
.long 0xbeae8ded
.long 0xbec4d19d
.long 0xbeda27bd
.long 0xbeeea34f
.long 0xbf012a95
.long 0xbf0aa61f
.long 0xbf13caf0
.long 0xbf1c9f07
.long 0xbf2527c4
.long 0xbf2d6a01
.text
.align 16
.global PRE(fmath_expf_avx512)
PRE(fmath_expf_avx512):
TYPE(fmath_expf_avx512)
sub $1352, %rsp
vmovups %zmm7, (%rsp)
vmovups %zmm8, 64(%rsp)
vmovups %zmm9, 128(%rsp)
vmovups %zmm10, 192(%rsp)
vmovups %zmm11, 256(%rsp)
vmovups %zmm12, 320(%rsp)
vmovups %zmm13, 384(%rsp)
vmovups %zmm14, 448(%rsp)
vmovups %zmm15, 512(%rsp)
vmovups %zmm16, 576(%rsp)
vmovups %zmm17, 640(%rsp)
vmovups %zmm18, 704(%rsp)
vmovups %zmm19, 768(%rsp)
vmovups %zmm20, 832(%rsp)
vmovups %zmm21, 896(%rsp)
vmovups %zmm22, 960(%rsp)
vmovups %zmm23, 1024(%rsp)
vmovups %zmm24, 1088(%rsp)
vmovups %zmm25, 1152(%rsp)
vmovups %zmm26, 1216(%rsp)
vmovups %zmm27, 1280(%rsp)
mov $1069066811, %eax
vpbroadcastd %eax, %zmm27
vbroadcastss PRE(exp_coef)(%rip), %zmm21
vbroadcastss PRE(exp_coef)+4(%rip), %zmm22
vbroadcastss PRE(exp_coef)+8(%rip), %zmm23
vbroadcastss PRE(exp_coef)+12(%rip), %zmm24
vbroadcastss PRE(exp_coef)+16(%rip), %zmm25
vbroadcastss PRE(exp_coef)+20(%rip), %zmm26
mov %rdx, %rcx
jmp .L2
.align 32
.L1:
vmovups (%rsi), %zmm0
vmovups 64(%rsi), %zmm1
vmovups 128(%rsi), %zmm2
vmovups 192(%rsi), %zmm3
vmovups 256(%rsi), %zmm4
vmovups 320(%rsi), %zmm5
vmovups 384(%rsi), %zmm6
add $448, %rsi
vmulps %zmm27, %zmm0, %zmm0
vmulps %zmm27, %zmm1, %zmm1
vmulps %zmm27, %zmm2, %zmm2
vmulps %zmm27, %zmm3, %zmm3
vmulps %zmm27, %zmm4, %zmm4
vmulps %zmm27, %zmm5, %zmm5
vmulps %zmm27, %zmm6, %zmm6
vreduceps $0, %zmm0, %zmm7
vreduceps $0, %zmm1, %zmm8
vreduceps $0, %zmm2, %zmm9
vreduceps $0, %zmm3, %zmm10
vreduceps $0, %zmm4, %zmm11
vreduceps $0, %zmm5, %zmm12
vreduceps $0, %zmm6, %zmm13
vsubps %zmm7, %zmm0, %zmm0
vsubps %zmm8, %zmm1, %zmm1
vsubps %zmm9, %zmm2, %zmm2
vsubps %zmm10, %zmm3, %zmm3
vsubps %zmm11, %zmm4, %zmm4
vsubps %zmm12, %zmm5, %zmm5
vsubps %zmm13, %zmm6, %zmm6
vmovaps %zmm26, %zmm14
vmovaps %zmm26, %zmm15
vmovaps %zmm26, %zmm16
vmovaps %zmm26, %zmm17
vmovaps %zmm26, %zmm18
vmovaps %zmm26, %zmm19
vmovaps %zmm26, %zmm20
vfmadd213ps %zmm25, %zmm7, %zmm14
vfmadd213ps %zmm25, %zmm8, %zmm15
vfmadd213ps %zmm25, %zmm9, %zmm16
vfmadd213ps %zmm25, %zmm10, %zmm17
vfmadd213ps %zmm25, %zmm11, %zmm18
vfmadd213ps %zmm25, %zmm12, %zmm19
vfmadd213ps %zmm25, %zmm13, %zmm20
vfmadd213ps %zmm24, %zmm7, %zmm14
vfmadd213ps %zmm24, %zmm8, %zmm15
vfmadd213ps %zmm24, %zmm9, %zmm16
vfmadd213ps %zmm24, %zmm10, %zmm17
vfmadd213ps %zmm24, %zmm11, %zmm18
vfmadd213ps %zmm24, %zmm12, %zmm19
vfmadd213ps %zmm24, %zmm13, %zmm20
vfmadd213ps %zmm23, %zmm7, %zmm14
vfmadd213ps %zmm23, %zmm8, %zmm15
vfmadd213ps %zmm23, %zmm9, %zmm16
vfmadd213ps %zmm23, %zmm10, %zmm17
vfmadd213ps %zmm23, %zmm11, %zmm18
vfmadd213ps %zmm23, %zmm12, %zmm19
vfmadd213ps %zmm23, %zmm13, %zmm20
vfmadd213ps %zmm22, %zmm7, %zmm14
vfmadd213ps %zmm22, %zmm8, %zmm15
vfmadd213ps %zmm22, %zmm9, %zmm16
vfmadd213ps %zmm22, %zmm10, %zmm17
vfmadd213ps %zmm22, %zmm11, %zmm18
vfmadd213ps %zmm22, %zmm12, %zmm19
vfmadd213ps %zmm22, %zmm13, %zmm20
vfmadd213ps %zmm21, %zmm7, %zmm14
vfmadd213ps %zmm21, %zmm8, %zmm15
vfmadd213ps %zmm21, %zmm9, %zmm16
vfmadd213ps %zmm21, %zmm10, %zmm17
vfmadd213ps %zmm21, %zmm11, %zmm18
vfmadd213ps %zmm21, %zmm12, %zmm19
vfmadd213ps %zmm21, %zmm13, %zmm20
vscalefps %zmm0, %zmm14, %zmm0
vscalefps %zmm1, %zmm15, %zmm1
vscalefps %zmm2, %zmm16, %zmm2
vscalefps %zmm3, %zmm17, %zmm3
vscalefps %zmm4, %zmm18, %zmm4
vscalefps %zmm5, %zmm19, %zmm5
vscalefps %zmm6, %zmm20, %zmm6
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
.align 32
.L3:
vmovups (%rsi), %zmm0
add $64, %rsi
vmulps %zmm27, %zmm0, %zmm0
vreduceps $0, %zmm0, %zmm7
vsubps %zmm7, %zmm0, %zmm0
vmovaps %zmm26, %zmm14
vfmadd213ps %zmm25, %zmm7, %zmm14
vfmadd213ps %zmm24, %zmm7, %zmm14
vfmadd213ps %zmm23, %zmm7, %zmm14
vfmadd213ps %zmm22, %zmm7, %zmm14
vfmadd213ps %zmm21, %zmm7, %zmm14
vscalefps %zmm0, %zmm14, %zmm0
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
vmulps %zmm27, %zmm0, %zmm0
vreduceps $0, %zmm0, %zmm7
vsubps %zmm7, %zmm0, %zmm0
vmovaps %zmm26, %zmm14
vfmadd213ps %zmm25, %zmm7, %zmm14
vfmadd213ps %zmm24, %zmm7, %zmm14
vfmadd213ps %zmm23, %zmm7, %zmm14
vfmadd213ps %zmm22, %zmm7, %zmm14
vfmadd213ps %zmm21, %zmm7, %zmm14
vscalefps %zmm0, %zmm14, %zmm0
vmovups %zmm0, (%rdi){%k1}
.L6:
vmovups (%rsp), %zmm7
vmovups 64(%rsp), %zmm8
vmovups 128(%rsp), %zmm9
vmovups 192(%rsp), %zmm10
vmovups 256(%rsp), %zmm11
vmovups 320(%rsp), %zmm12
vmovups 384(%rsp), %zmm13
vmovups 448(%rsp), %zmm14
vmovups 512(%rsp), %zmm15
vmovups 576(%rsp), %zmm16
vmovups 640(%rsp), %zmm17
vmovups 704(%rsp), %zmm18
vmovups 768(%rsp), %zmm19
vmovups 832(%rsp), %zmm20
vmovups 896(%rsp), %zmm21
vmovups 960(%rsp), %zmm22
vmovups 1024(%rsp), %zmm23
vmovups 1088(%rsp), %zmm24
vmovups 1152(%rsp), %zmm25
vmovups 1216(%rsp), %zmm26
vmovups 1280(%rsp), %zmm27
add $1352, %rsp
ret
SIZE(fmath_expf_avx512)
.align 16
.global PRE(fmath_logf_avx512)
PRE(fmath_logf_avx512):
TYPE(fmath_logf_avx512)
sub $1160, %rsp
vmovups %zmm7, (%rsp)
vmovups %zmm8, 64(%rsp)
vmovups %zmm9, 128(%rsp)
vmovups %zmm10, 192(%rsp)
vmovups %zmm11, 256(%rsp)
vmovups %zmm12, 320(%rsp)
vmovups %zmm13, 384(%rsp)
vmovups %zmm14, 448(%rsp)
vmovups %zmm15, 512(%rsp)
vmovups %zmm16, 576(%rsp)
vmovups %zmm17, 640(%rsp)
vmovups %zmm18, 704(%rsp)
vmovups %zmm19, 768(%rsp)
vmovups %zmm20, 832(%rsp)
vmovups %zmm21, 896(%rsp)
vmovups %zmm22, 960(%rsp)
vmovups %zmm23, 1024(%rsp)
vmovups %zmm24, 1088(%rsp)
mov $1065353216, %eax
vpbroadcastd %eax, %zmm20
mov $3196062496, %eax
vpbroadcastd %eax, %zmm24
vmovups PRE(log_tbl1)(%rip), %zmm21
vmovups PRE(log_tbl2)(%rip), %zmm22
mov %rdx, %rcx
jmp .L8
.align 32
.L7:
vmovups (%rsi), %zmm0
vmovups 64(%rsi), %zmm1
vmovups 128(%rsi), %zmm2
vmovups 192(%rsi), %zmm3
add $256, %rsi
vmovaps %zmm0, %zmm16
vmovaps %zmm1, %zmm17
vmovaps %zmm2, %zmm18
vmovaps %zmm3, %zmm19
vgetexpps %zmm0, %zmm4
vgetexpps %zmm1, %zmm5
vgetexpps %zmm2, %zmm6
vgetexpps %zmm3, %zmm7
vgetmantps $0, %zmm0, %zmm0
vgetmantps $0, %zmm1, %zmm1
vgetmantps $0, %zmm2, %zmm2
vgetmantps $0, %zmm3, %zmm3
vpsrad $19, %zmm0, %zmm8
vpsrad $19, %zmm1, %zmm9
vpsrad $19, %zmm2, %zmm10
vpsrad $19, %zmm3, %zmm11
vpermps %zmm21, %zmm8, %zmm12
vpermps %zmm21, %zmm9, %zmm13
vpermps %zmm21, %zmm10, %zmm14
vpermps %zmm21, %zmm11, %zmm15
vfmsub213ps %zmm20, %zmm12, %zmm0
vfmsub213ps %zmm20, %zmm13, %zmm1
vfmsub213ps %zmm20, %zmm14, %zmm2
vfmsub213ps %zmm20, %zmm15, %zmm3
vpermps %zmm22, %zmm8, %zmm12
vpermps %zmm22, %zmm9, %zmm13
vpermps %zmm22, %zmm10, %zmm14
vpermps %zmm22, %zmm11, %zmm15
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm12, %zmm4
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm13, %zmm5
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm14, %zmm6
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm15, %zmm7
vsubps %zmm20, %zmm16, %zmm8
vsubps %zmm20, %zmm17, %zmm9
vsubps %zmm20, %zmm18, %zmm10
vsubps %zmm20, %zmm19, %zmm11
vandps PRE(abs_mask)(%rip){1to16}, %zmm8, %zmm12
vandps PRE(abs_mask)(%rip){1to16}, %zmm9, %zmm13
vandps PRE(abs_mask)(%rip){1to16}, %zmm10, %zmm14
vandps PRE(abs_mask)(%rip){1to16}, %zmm11, %zmm15
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm12, %k2
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm13, %k3
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm14, %k4
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm15, %k5
vmovaps %zmm8, %zmm0{%k2}
vmovaps %zmm9, %zmm1{%k3}
vmovaps %zmm10, %zmm2{%k4}
vmovaps %zmm11, %zmm3{%k5}
vxorps %zmm4, %zmm4, %zmm4{%k2}
vxorps %zmm5, %zmm5, %zmm5{%k3}
vxorps %zmm6, %zmm6, %zmm6{%k4}
vxorps %zmm7, %zmm7, %zmm7{%k5}
vmovaps %zmm24, %zmm8
vmovaps %zmm24, %zmm9
vmovaps %zmm24, %zmm10
vmovaps %zmm24, %zmm11
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm0, %zmm8
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm1, %zmm9
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm2, %zmm10
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm3, %zmm11
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm8
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm1, %zmm9
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm2, %zmm10
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm3, %zmm11
vfmadd213ps %zmm20, %zmm0, %zmm8
vfmadd213ps %zmm20, %zmm1, %zmm9
vfmadd213ps %zmm20, %zmm2, %zmm10
vfmadd213ps %zmm20, %zmm3, %zmm11
vfmadd213ps %zmm4, %zmm8, %zmm0
vfmadd213ps %zmm5, %zmm9, %zmm1
vfmadd213ps %zmm6, %zmm10, %zmm2
vfmadd213ps %zmm7, %zmm11, %zmm3
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
.align 32
.L9:
vmovups (%rsi), %zmm0
add $64, %rsi
vmovaps %zmm0, %zmm16
vgetexpps %zmm0, %zmm4
vgetmantps $0, %zmm0, %zmm0
vpsrad $19, %zmm0, %zmm8
vpermps %zmm21, %zmm8, %zmm12
vfmsub213ps %zmm20, %zmm12, %zmm0
vpermps %zmm22, %zmm8, %zmm12
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm12, %zmm4
vsubps %zmm20, %zmm16, %zmm8
vandps PRE(abs_mask)(%rip){1to16}, %zmm8, %zmm12
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm12, %k2
vmovaps %zmm8, %zmm0{%k2}
vxorps %zmm4, %zmm4, %zmm4{%k2}
vmovaps %zmm24, %zmm8
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm0, %zmm8
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm8
vfmadd213ps %zmm20, %zmm0, %zmm8
vfmadd213ps %zmm4, %zmm8, %zmm0
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
vmovaps %zmm0, %zmm16
vgetexpps %zmm0, %zmm4
vgetmantps $0, %zmm0, %zmm0
vpsrad $19, %zmm0, %zmm8
vpermps %zmm21, %zmm8, %zmm12
vfmsub213ps %zmm20, %zmm12, %zmm0
vpermps %zmm22, %zmm8, %zmm12
vfmsub132ps PRE(log2)(%rip){1to16}, %zmm12, %zmm4
vsubps %zmm20, %zmm16, %zmm8
vandps PRE(abs_mask)(%rip){1to16}, %zmm8, %zmm12
vcmpltps PRE(log_boundary)(%rip){1to16}, %zmm12, %k2
vmovaps %zmm8, %zmm0{%k2}
vxorps %zmm4, %zmm4, %zmm4{%k2}
vmovaps %zmm24, %zmm8
vfmadd213ps PRE(log_coef)+8(%rip){1to16}, %zmm0, %zmm8
vfmadd213ps PRE(log_coef)+4(%rip){1to16}, %zmm0, %zmm8
vfmadd213ps %zmm20, %zmm0, %zmm8
vfmadd213ps %zmm4, %zmm8, %zmm0
vmovups %zmm0, (%rdi){%k1}
.L12:
vmovups (%rsp), %zmm7
vmovups 64(%rsp), %zmm8
vmovups 128(%rsp), %zmm9
vmovups 192(%rsp), %zmm10
vmovups 256(%rsp), %zmm11
vmovups 320(%rsp), %zmm12
vmovups 384(%rsp), %zmm13
vmovups 448(%rsp), %zmm14
vmovups 512(%rsp), %zmm15
vmovups 576(%rsp), %zmm16
vmovups 640(%rsp), %zmm17
vmovups 704(%rsp), %zmm18
vmovups 768(%rsp), %zmm19
vmovups 832(%rsp), %zmm20
vmovups 896(%rsp), %zmm21
vmovups 960(%rsp), %zmm22
vmovups 1024(%rsp), %zmm23
vmovups 1088(%rsp), %zmm24
add $1160, %rsp
ret
SIZE(fmath_logf_avx512)
