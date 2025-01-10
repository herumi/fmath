; for masm (ml64.exe)
_data$x segment align(64)
log2_e:
dd 3fb8aa3bh
exp_coef:
dd 3f800000h,3f317218h,3e75fd0bh,3d63578ah,3c1e6362h,3aaf9319h
align 64
log_coef:
dd 0befffff1h,3eaab78ah,0be7d89b8h
log_A0:
dd 3f7ece44h
log_A1:
dd 49000000h
log_A2:
dd 3fbce194h
log_A3:
dd 3f000000h
log_A4:
dd 3f317218h
log_f1:
dd 3f800000h
log_tbl1:
dd 3f800000h,3f714349h,3f63937fh,3f579acch,3f4cd4afh,3f430d4fh,3f3a3632h,3f321ac1h,3faab27ah,3fa3d44bh,3f9d8e2fh,3f97b205h,3f924ac6h,3f8d409fh,3f888c06h,3f826cdah
log_tbl2:
dd 0h,3d72da9ch,3df108c5h,3e2fda3bh,3e645854h,3e8b37f6h,3ea2f755h,3eb9c1d5h,0be93627eh,0be7cb7b8h,0be54bb9bh,0be2deba5h,0be08c7deh,0bdc9c3f4h,0bd84611fh,0bc99c2c4h
i127:
dd 127
log_x_min:
dd 0c2b0c0a5h
Inf:
dd 7f800000h
align 64
log2_0x7fffffff:
dd 2147483647,2147483647,2147483647,2147483647,2147483647,2147483647,2147483647,2147483647
log2_f127:
dd 42fe0000h,42fe0000h,42fe0000h,42fe0000h,42fe0000h,42fe0000h,42fe0000h,42fe0000h
log2_0xffffff:
dd 16777215,16777215,16777215,16777215,16777215,16777215,16777215,16777215
log2_ROUND:
dd 49800000h,49800000h,49800000h,49800000h,49800000h,49800000h,49800000h,49800000h
log2_BOUND:
dd 3fb80000h,3fb80000h,3fb80000h,3fb80000h,3fb80000h,3fb80000h,3fb80000h,3fb80000h
log2_f1:
dd 3f800000h,3f800000h,3f800000h,3f800000h,3f800000h,3f800000h,3f800000h,3f800000h
log2_f0p5:
dd 3f000000h,3f000000h,3f000000h,3f000000h,3f000000h,3f000000h,3f000000h,3f000000h
log2_A:
dd 0beffffe9h,0beffffe9h,0beffffe9h,0beffffe9h,0beffffe9h,0beffffe9h,0beffffe9h,0beffffe9h
log2_B:
dd 3eaaab3eh,3eaaab3eh,3eaaab3eh,3eaaab3eh,3eaaab3eh,3eaaab3eh,3eaaab3eh,3eaaab3eh
log2_C:
dd 0be805e53h,0be805e53h,0be805e53h,0be805e53h,0be805e53h,0be805e53h,0be805e53h,0be805e53h
log2_D:
dd 3e4b1a33h,3e4b1a33h,3e4b1a33h,3e4b1a33h,3e4b1a33h,3e4b1a33h,3e4b1a33h,3e4b1a33h
log2_log2:
dd 3f317218h,3f317218h,3f317218h,3f317218h,3f317218h,3f317218h,3f317218h,3f317218h
align 64
log2_tbl1:
dd 3f800000h,3f639220h,3f4ccccdh,3f3a2e8ch,3faaae92h,3f9d8dbfh,3f924777h,3f888507h
log2_tbl2:
dd 0h,3df1151ch,3e647fbdh,3ea30c5dh,0be9356c6h,0be54b8c3h,0be08b0b5h,0bd83f82eh
_data$x ends
_text$x segment align(64) execute
align 16
fmath_expf_v_avx512 proc export
sub rsp, 184
vmovups xmmword ptr [rsp], xmm5
vmovups xmmword ptr [rsp+16], xmm6
vmovups xmmword ptr [rsp+32], xmm7
vmovups xmmword ptr [rsp+48], xmm8
vmovups xmmword ptr [rsp+64], xmm9
vmovups xmmword ptr [rsp+80], xmm10
vmovups xmmword ptr [rsp+96], xmm11
vmovups xmmword ptr [rsp+112], xmm12
vmovups xmmword ptr [rsp+128], xmm13
vmovups xmmword ptr [rsp+144], xmm14
vmovups xmmword ptr [rsp+160], xmm15
mov r10, rcx
vbroadcastss zmm13, dword ptr log2_e
vbroadcastss zmm7, dword ptr exp_coef
vbroadcastss zmm8, dword ptr exp_coef+4
vbroadcastss zmm9, dword ptr exp_coef+8
vbroadcastss zmm10, dword ptr exp_coef+12
vbroadcastss zmm11, dword ptr exp_coef+16
vbroadcastss zmm12, dword ptr exp_coef+20
mov rcx, r8
jmp @L2
align 32
@L1:
vmovups zmm0, zmmword ptr [rdx]
vmovups zmm1, zmmword ptr [rdx+64]
vmovups zmm2, zmmword ptr [rdx+128]
vmovups zmm3, zmmword ptr [rdx+192]
vmovups zmm4, zmmword ptr [rdx+256]
vmovups zmm5, zmmword ptr [rdx+320]
vmovups zmm6, zmmword ptr [rdx+384]
add rdx, 448
vmulps zmm0, zmm0, zmm13
vmulps zmm1, zmm1, zmm13
vmulps zmm2, zmm2, zmm13
vmulps zmm3, zmm3, zmm13
vmulps zmm4, zmm4, zmm13
vmulps zmm5, zmm5, zmm13
vmulps zmm6, zmm6, zmm13
vreduceps zmm14, zmm0, 0
vreduceps zmm15, zmm1, 0
vreduceps zmm16, zmm2, 0
vreduceps zmm17, zmm3, 0
vreduceps zmm18, zmm4, 0
vreduceps zmm19, zmm5, 0
vreduceps zmm20, zmm6, 0
vsubps zmm0, zmm0, zmm14
vsubps zmm1, zmm1, zmm15
vsubps zmm2, zmm2, zmm16
vsubps zmm3, zmm3, zmm17
vsubps zmm4, zmm4, zmm18
vsubps zmm5, zmm5, zmm19
vsubps zmm6, zmm6, zmm20
vmovaps zmm21, zmm12
vmovaps zmm22, zmm12
vmovaps zmm23, zmm12
vmovaps zmm24, zmm12
vmovaps zmm25, zmm12
vmovaps zmm26, zmm12
vmovaps zmm27, zmm12
vfmadd213ps zmm21, zmm14, zmm11
vfmadd213ps zmm22, zmm15, zmm11
vfmadd213ps zmm23, zmm16, zmm11
vfmadd213ps zmm24, zmm17, zmm11
vfmadd213ps zmm25, zmm18, zmm11
vfmadd213ps zmm26, zmm19, zmm11
vfmadd213ps zmm27, zmm20, zmm11
vfmadd213ps zmm21, zmm14, zmm10
vfmadd213ps zmm22, zmm15, zmm10
vfmadd213ps zmm23, zmm16, zmm10
vfmadd213ps zmm24, zmm17, zmm10
vfmadd213ps zmm25, zmm18, zmm10
vfmadd213ps zmm26, zmm19, zmm10
vfmadd213ps zmm27, zmm20, zmm10
vfmadd213ps zmm21, zmm14, zmm9
vfmadd213ps zmm22, zmm15, zmm9
vfmadd213ps zmm23, zmm16, zmm9
vfmadd213ps zmm24, zmm17, zmm9
vfmadd213ps zmm25, zmm18, zmm9
vfmadd213ps zmm26, zmm19, zmm9
vfmadd213ps zmm27, zmm20, zmm9
vfmadd213ps zmm21, zmm14, zmm8
vfmadd213ps zmm22, zmm15, zmm8
vfmadd213ps zmm23, zmm16, zmm8
vfmadd213ps zmm24, zmm17, zmm8
vfmadd213ps zmm25, zmm18, zmm8
vfmadd213ps zmm26, zmm19, zmm8
vfmadd213ps zmm27, zmm20, zmm8
vfmadd213ps zmm21, zmm14, zmm7
vfmadd213ps zmm22, zmm15, zmm7
vfmadd213ps zmm23, zmm16, zmm7
vfmadd213ps zmm24, zmm17, zmm7
vfmadd213ps zmm25, zmm18, zmm7
vfmadd213ps zmm26, zmm19, zmm7
vfmadd213ps zmm27, zmm20, zmm7
vscalefps zmm0, zmm21, zmm0
vscalefps zmm1, zmm22, zmm1
vscalefps zmm2, zmm23, zmm2
vscalefps zmm3, zmm24, zmm3
vscalefps zmm4, zmm25, zmm4
vscalefps zmm5, zmm26, zmm5
vscalefps zmm6, zmm27, zmm6
vmovups zmmword ptr [r10], zmm0
vmovups zmmword ptr [r10+64], zmm1
vmovups zmmword ptr [r10+128], zmm2
vmovups zmmword ptr [r10+192], zmm3
vmovups zmmword ptr [r10+256], zmm4
vmovups zmmword ptr [r10+320], zmm5
vmovups zmmword ptr [r10+384], zmm6
add r10, 448
sub r8, 112
@L2:
cmp r8, 112
jae @L1
jmp @L4
align 32
@L3:
vmovups zmm0, zmmword ptr [rdx]
add rdx, 64
vmulps zmm0, zmm0, zmm13
vreduceps zmm14, zmm0, 0
vsubps zmm0, zmm0, zmm14
vmovaps zmm15, zmm12
vfmadd213ps zmm15, zmm14, zmm11
vfmadd213ps zmm15, zmm14, zmm10
vfmadd213ps zmm15, zmm14, zmm9
vfmadd213ps zmm15, zmm14, zmm8
vfmadd213ps zmm15, zmm14, zmm7
vscalefps zmm0, zmm15, zmm0
vmovups zmmword ptr [r10], zmm0
add r10, 64
sub r8, 16
@L4:
cmp r8, 16
jae @L3
@L5:
and ecx, 15
jz @L6
mov eax, 1
shl eax, cl
sub eax, 1
kmovd k1, eax
vmovups zmm0{k1}{z}, zmmword ptr [rdx]
vmulps zmm0, zmm0, zmm13
vreduceps zmm14, zmm0, 0
vsubps zmm0, zmm0, zmm14
vmovaps zmm15, zmm12
vfmadd213ps zmm15, zmm14, zmm11
vfmadd213ps zmm15, zmm14, zmm10
vfmadd213ps zmm15, zmm14, zmm9
vfmadd213ps zmm15, zmm14, zmm8
vfmadd213ps zmm15, zmm14, zmm7
vscalefps zmm0, zmm15, zmm0
vmovups zmmword ptr [r10]{k1}, zmm0
@L6:
vmovups xmm5, xmmword ptr [rsp]
vmovups xmm6, xmmword ptr [rsp+16]
vmovups xmm7, xmmword ptr [rsp+32]
vmovups xmm8, xmmword ptr [rsp+48]
vmovups xmm9, xmmword ptr [rsp+64]
vmovups xmm10, xmmword ptr [rsp+80]
vmovups xmm11, xmmword ptr [rsp+96]
vmovups xmm12, xmmword ptr [rsp+112]
vmovups xmm13, xmmword ptr [rsp+128]
vmovups xmm14, xmmword ptr [rsp+144]
vmovups xmm15, xmmword ptr [rsp+160]
vzeroupper
add rsp, 184
ret
fmath_expf_v_avx512 endp
align 16
fmath_logf_v_avx512 proc export
sub rsp, 184
vmovups xmmword ptr [rsp], xmm5
vmovups xmmword ptr [rsp+16], xmm6
vmovups xmmword ptr [rsp+32], xmm7
vmovups xmmword ptr [rsp+48], xmm8
vmovups xmmword ptr [rsp+64], xmm9
vmovups xmmword ptr [rsp+80], xmm10
vmovups xmmword ptr [rsp+96], xmm11
vmovups xmmword ptr [rsp+112], xmm12
vmovups xmmword ptr [rsp+128], xmm13
vmovups xmmword ptr [rsp+144], xmm14
vmovups xmmword ptr [rsp+160], xmm15
mov r10, rcx
mov eax, 1065353216
vpbroadcastd zmm4, eax
vbroadcastss zmm7, dword ptr log_A0
vbroadcastss zmm8, dword ptr log_coef+8
vmovups zmm5, zmmword ptr log_tbl1
vmovups zmm6, zmmword ptr log_tbl2
mov rcx, r8
jmp @L8
align 32
@L7:
vmovups zmm0, zmmword ptr [rdx]
vmovups zmm1, zmmword ptr [rdx+64]
vmovups zmm2, zmmword ptr [rdx+128]
vmovups zmm3, zmmword ptr [rdx+192]
add rdx, 256
vgetexpps zmm9, zmm0
vgetexpps zmm10, zmm1
vgetexpps zmm11, zmm2
vgetexpps zmm12, zmm3
vgetmantps zmm0, zmm0, 0
vgetmantps zmm1, zmm1, 0
vgetmantps zmm2, zmm2, 0
vgetmantps zmm3, zmm3, 0
vmovaps zmm13, zmm0
vmovaps zmm14, zmm1
vmovaps zmm15, zmm2
vmovaps zmm16, zmm3
vfmadd213ps zmm13, zmm7, dword bcst log_A1
vfmadd213ps zmm14, zmm7, dword bcst log_A1
vfmadd213ps zmm15, zmm7, dword bcst log_A1
vfmadd213ps zmm16, zmm7, dword bcst log_A1
vcmpgeps k2, zmm0, dword bcst log_A2
vcmpgeps k3, zmm1, dword bcst log_A2
vcmpgeps k4, zmm2, dword bcst log_A2
vcmpgeps k5, zmm3, dword bcst log_A2
vaddps zmm9{k2}, zmm9, zmm4
vaddps zmm10{k3}, zmm10, zmm4
vaddps zmm11{k4}, zmm11, zmm4
vaddps zmm12{k5}, zmm12, zmm4
vmulps zmm0{k2}, zmm0, dword bcst log_A3
vmulps zmm1{k3}, zmm1, dword bcst log_A3
vmulps zmm2{k4}, zmm2, dword bcst log_A3
vmulps zmm3{k5}, zmm3, dword bcst log_A3
vpermps zmm17, zmm13, zmm5
vpermps zmm18, zmm14, zmm5
vpermps zmm19, zmm15, zmm5
vpermps zmm20, zmm16, zmm5
vfmsub213ps zmm0, zmm17, zmm4
vfmsub213ps zmm1, zmm18, zmm4
vfmsub213ps zmm2, zmm19, zmm4
vfmsub213ps zmm3, zmm20, zmm4
vpermps zmm13, zmm13, zmm6
vpermps zmm14, zmm14, zmm6
vpermps zmm15, zmm15, zmm6
vpermps zmm16, zmm16, zmm6
vmovaps zmm17, zmm8
vmovaps zmm18, zmm8
vmovaps zmm19, zmm8
vmovaps zmm20, zmm8
vfmadd213ps zmm17, zmm0, dword bcst log_coef+4
vfmadd213ps zmm18, zmm1, dword bcst log_coef+4
vfmadd213ps zmm19, zmm2, dword bcst log_coef+4
vfmadd213ps zmm20, zmm3, dword bcst log_coef+4
vfmadd213ps zmm17, zmm0, dword bcst log_coef
vfmadd213ps zmm18, zmm1, dword bcst log_coef
vfmadd213ps zmm19, zmm2, dword bcst log_coef
vfmadd213ps zmm20, zmm3, dword bcst log_coef
vfmadd213ps zmm17, zmm0, zmm4
vfmadd213ps zmm18, zmm1, zmm4
vfmadd213ps zmm19, zmm2, zmm4
vfmadd213ps zmm20, zmm3, zmm4
vfmadd132ps zmm9, zmm13, dword bcst log_A4
vfmadd132ps zmm10, zmm14, dword bcst log_A4
vfmadd132ps zmm11, zmm15, dword bcst log_A4
vfmadd132ps zmm12, zmm16, dword bcst log_A4
vfmadd213ps zmm0, zmm17, zmm9
vfmadd213ps zmm1, zmm18, zmm10
vfmadd213ps zmm2, zmm19, zmm11
vfmadd213ps zmm3, zmm20, zmm12
vmovups zmmword ptr [r10], zmm0
vmovups zmmword ptr [r10+64], zmm1
vmovups zmmword ptr [r10+128], zmm2
vmovups zmmword ptr [r10+192], zmm3
add r10, 256
sub r8, 64
@L8:
cmp r8, 64
jae @L7
jmp @L10
align 32
@L9:
vmovups zmm0, zmmword ptr [rdx]
add rdx, 64
vgetexpps zmm9, zmm0
vgetmantps zmm0, zmm0, 0
vmovaps zmm10, zmm0
vfmadd213ps zmm10, zmm7, dword bcst log_A1
vcmpgeps k2, zmm0, dword bcst log_A2
vaddps zmm9{k2}, zmm9, zmm4
vmulps zmm0{k2}, zmm0, dword bcst log_A3
vpermps zmm11, zmm10, zmm5
vfmsub213ps zmm0, zmm11, zmm4
vpermps zmm10, zmm10, zmm6
vmovaps zmm11, zmm8
vfmadd213ps zmm11, zmm0, dword bcst log_coef+4
vfmadd213ps zmm11, zmm0, dword bcst log_coef
vfmadd213ps zmm11, zmm0, zmm4
vfmadd132ps zmm9, zmm10, dword bcst log_A4
vfmadd213ps zmm0, zmm11, zmm9
vmovups zmmword ptr [r10], zmm0
add r10, 64
sub r8, 16
@L10:
cmp r8, 16
jae @L9
@L11:
and ecx, 15
jz @L12
mov eax, 1
shl eax, cl
sub eax, 1
kmovd k1, eax
vmovups zmm0{k1}{z}, zmmword ptr [rdx]
vgetexpps zmm9, zmm0
vgetmantps zmm0, zmm0, 0
vmovaps zmm10, zmm0
vfmadd213ps zmm10, zmm7, dword bcst log_A1
vcmpgeps k2, zmm0, dword bcst log_A2
vaddps zmm9{k2}, zmm9, zmm4
vmulps zmm0{k2}, zmm0, dword bcst log_A3
vpermps zmm11, zmm10, zmm5
vfmsub213ps zmm0, zmm11, zmm4
vpermps zmm10, zmm10, zmm6
vmovaps zmm11, zmm8
vfmadd213ps zmm11, zmm0, dword bcst log_coef+4
vfmadd213ps zmm11, zmm0, dword bcst log_coef
vfmadd213ps zmm11, zmm0, zmm4
vfmadd132ps zmm9, zmm10, dword bcst log_A4
vfmadd213ps zmm0, zmm11, zmm9
vmovups zmmword ptr [r10]{k1}, zmm0
@L12:
vmovups xmm5, xmmword ptr [rsp]
vmovups xmm6, xmmword ptr [rsp+16]
vmovups xmm7, xmmword ptr [rsp+32]
vmovups xmm8, xmmword ptr [rsp+48]
vmovups xmm9, xmmword ptr [rsp+64]
vmovups xmm10, xmmword ptr [rsp+80]
vmovups xmm11, xmmword ptr [rsp+96]
vmovups xmm12, xmmword ptr [rsp+112]
vmovups xmm13, xmmword ptr [rsp+128]
vmovups xmm14, xmmword ptr [rsp+144]
vmovups xmm15, xmmword ptr [rsp+160]
vzeroupper
add rsp, 184
ret
fmath_logf_v_avx512 endp
align 16
fmath_expf_v_avx2 proc export
sub rsp, 216
vmovups xmmword ptr [rsp+32], xmm5
vmovups xmmword ptr [rsp+48], xmm6
vmovups xmmword ptr [rsp+64], xmm7
vmovups xmmword ptr [rsp+80], xmm8
vmovups xmmword ptr [rsp+96], xmm9
vmovups xmmword ptr [rsp+112], xmm10
vmovups xmmword ptr [rsp+128], xmm11
vmovups xmmword ptr [rsp+144], xmm12
vmovups xmmword ptr [rsp+160], xmm13
vmovups xmmword ptr [rsp+176], xmm14
vmovups xmmword ptr [rsp+192], xmm15
mov r10, rcx
mov r11, rdx
vbroadcastss ymm9, dword ptr log_x_min
vbroadcastss ymm3, dword ptr exp_coef
vbroadcastss ymm4, dword ptr exp_coef+4
vbroadcastss ymm5, dword ptr exp_coef+8
vbroadcastss ymm6, dword ptr exp_coef+12
vbroadcastss ymm7, dword ptr exp_coef+16
vbroadcastss ymm8, dword ptr exp_coef+20
mov rcx, r8
jmp @L14
align 32
@L13:
vmovups ymm0, ymmword ptr [r11]
vmovups ymm1, ymmword ptr [r11+32]
vmovups ymm2, ymmword ptr [r11+64]
add r11, 96
vmaxps ymm0, ymm0, ymm9
vmaxps ymm1, ymm1, ymm9
vmaxps ymm2, ymm2, ymm9
vbroadcastss ymm13, dword ptr log2_e
vmulps ymm10, ymm0, ymm13
vmulps ymm11, ymm1, ymm13
vmulps ymm12, ymm2, ymm13
vcvtps2dq ymm0, ymm10
vcvtps2dq ymm1, ymm11
vcvtps2dq ymm2, ymm12
vcvtdq2ps ymm13, ymm0
vcvtdq2ps ymm14, ymm1
vcvtdq2ps ymm15, ymm2
vsubps ymm10, ymm10, ymm13
vsubps ymm11, ymm11, ymm14
vsubps ymm12, ymm12, ymm15
vpbroadcastd ymm13, dword ptr i127
vpaddd ymm0, ymm0, ymm13
vpaddd ymm1, ymm1, ymm13
vpaddd ymm2, ymm2, ymm13
vpslld ymm0, ymm0, 23
vpslld ymm1, ymm1, 23
vpslld ymm2, ymm2, 23
vmovaps ymm13, ymm8
vmovaps ymm14, ymm8
vmovaps ymm15, ymm8
vfmadd213ps ymm13, ymm10, ymm7
vfmadd213ps ymm14, ymm11, ymm7
vfmadd213ps ymm15, ymm12, ymm7
vfmadd213ps ymm13, ymm10, ymm6
vfmadd213ps ymm14, ymm11, ymm6
vfmadd213ps ymm15, ymm12, ymm6
vfmadd213ps ymm13, ymm10, ymm5
vfmadd213ps ymm14, ymm11, ymm5
vfmadd213ps ymm15, ymm12, ymm5
vfmadd213ps ymm13, ymm10, ymm4
vfmadd213ps ymm14, ymm11, ymm4
vfmadd213ps ymm15, ymm12, ymm4
vfmadd213ps ymm13, ymm10, ymm3
vfmadd213ps ymm14, ymm11, ymm3
vfmadd213ps ymm15, ymm12, ymm3
vmulps ymm0, ymm0, ymm13
vmulps ymm1, ymm1, ymm14
vmulps ymm2, ymm2, ymm15
vmovups ymmword ptr [r10], ymm0
vmovups ymmword ptr [r10+32], ymm1
vmovups ymmword ptr [r10+64], ymm2
add r10, 96
sub r8, 24
@L14:
cmp r8, 24
jae @L13
jmp @L16
align 32
@L15:
vmovups ymm0, ymmword ptr [r11]
add r11, 32
vmaxps ymm0, ymm0, ymm9
vbroadcastss ymm11, dword ptr log2_e
vmulps ymm10, ymm0, ymm11
vcvtps2dq ymm0, ymm10
vcvtdq2ps ymm11, ymm0
vsubps ymm10, ymm10, ymm11
vpbroadcastd ymm11, dword ptr i127
vpaddd ymm0, ymm0, ymm11
vpslld ymm0, ymm0, 23
vmovaps ymm11, ymm8
vfmadd213ps ymm11, ymm10, ymm7
vfmadd213ps ymm11, ymm10, ymm6
vfmadd213ps ymm11, ymm10, ymm5
vfmadd213ps ymm11, ymm10, ymm4
vfmadd213ps ymm11, ymm10, ymm3
vmulps ymm0, ymm0, ymm11
vmovups ymmword ptr [r10], ymm0
add r10, 32
sub r8, 8
@L16:
cmp r8, 8
jae @L15
@L17:
and ecx, 7
jz @L20
xor rdx, rdx
@L18:
mov eax, [r11+rdx*4]
mov [rsp+rdx*4], eax
add rdx, 1
cmp rdx, rcx
jne @L18
vmovups ymm0, ymmword ptr [rsp]
vmaxps ymm0, ymm0, ymm9
vbroadcastss ymm11, dword ptr log2_e
vmulps ymm10, ymm0, ymm11
vcvtps2dq ymm0, ymm10
vcvtdq2ps ymm11, ymm0
vsubps ymm10, ymm10, ymm11
vpbroadcastd ymm11, dword ptr i127
vpaddd ymm0, ymm0, ymm11
vpslld ymm0, ymm0, 23
vmovaps ymm11, ymm8
vfmadd213ps ymm11, ymm10, ymm7
vfmadd213ps ymm11, ymm10, ymm6
vfmadd213ps ymm11, ymm10, ymm5
vfmadd213ps ymm11, ymm10, ymm4
vfmadd213ps ymm11, ymm10, ymm3
vmulps ymm0, ymm0, ymm11
vmovups ymmword ptr [rsp], ymm0
xor rdx, rdx
@L19:
mov eax, [rsp+rdx*4]
mov [r10+rdx*4], eax
add rdx, 1
cmp rdx, rcx
jne @L19
@L20:
vmovups xmm5, xmmword ptr [rsp+32]
vmovups xmm6, xmmword ptr [rsp+48]
vmovups xmm7, xmmword ptr [rsp+64]
vmovups xmm8, xmmword ptr [rsp+80]
vmovups xmm9, xmmword ptr [rsp+96]
vmovups xmm10, xmmword ptr [rsp+112]
vmovups xmm11, xmmword ptr [rsp+128]
vmovups xmm12, xmmword ptr [rsp+144]
vmovups xmm13, xmmword ptr [rsp+160]
vmovups xmm14, xmmword ptr [rsp+176]
vmovups xmm15, xmmword ptr [rsp+192]
vzeroupper
add rsp, 216
ret
fmath_expf_v_avx2 endp
align 16
fmath_logf_v_avx2 proc export
sub rsp, 168
vmovups xmmword ptr [rsp+32], xmm5
vmovups xmmword ptr [rsp+48], xmm6
vmovups xmmword ptr [rsp+64], xmm7
vmovups xmmword ptr [rsp+80], xmm8
vmovups xmmword ptr [rsp+96], xmm9
vmovups xmmword ptr [rsp+112], xmm10
vmovups xmmword ptr [rsp+128], xmm11
vmovups xmmword ptr [rsp+144], xmm12
mov r10, rcx
mov r11, rdx
vmovaps ymm2, ymmword ptr log2_f1
vmovaps ymm3, ymmword ptr log2_tbl1
vmovaps ymm4, ymmword ptr log2_tbl2
mov rcx, r8
jmp @L22
align 32
@L21:
vmovups ymm0, ymmword ptr [r11]
vmovups ymm1, ymmword ptr [r11+32]
add r11, 64
vandps ymm5, ymm0, ymmword ptr log2_0x7fffffff
vandps ymm6, ymm1, ymmword ptr log2_0x7fffffff
vpsrld ymm5, ymm5, 23
vpsrld ymm6, ymm6, 23
vcvtdq2ps ymm5, ymm5
vcvtdq2ps ymm6, ymm6
vsubps ymm5, ymm5, ymmword ptr log2_f127
vsubps ymm6, ymm6, ymmword ptr log2_f127
vandps ymm0, ymm0, ymmword ptr log2_0xffffff
vandps ymm1, ymm1, ymmword ptr log2_0xffffff
vorps ymm0, ymm0, ymm2
vorps ymm1, ymm1, ymm2
vaddps ymm7, ymm0, ymmword ptr log2_ROUND
vaddps ymm8, ymm1, ymmword ptr log2_ROUND
vcmpgeps ymm11, ymm0, ymmword ptr log2_BOUND
vandps ymm12, ymm2, ymm11
vaddps ymm5, ymm5, ymm12
vblendvps ymm12, ymm2, ymmword ptr log2_f0p5, ymm11
vmulps ymm0, ymm0, ymm12
vcmpgeps ymm11, ymm1, ymmword ptr log2_BOUND
vandps ymm12, ymm2, ymm11
vaddps ymm6, ymm6, ymm12
vblendvps ymm12, ymm2, ymmword ptr log2_f0p5, ymm11
vmulps ymm1, ymm1, ymm12
vpermps ymm9, ymm7, ymm3
vpermps ymm10, ymm8, ymm3
vfmsub213ps ymm0, ymm9, ymm2
vfmsub213ps ymm1, ymm10, ymm2
vpermps ymm7, ymm7, ymm4
vpermps ymm8, ymm8, ymm4
vmovaps ymm9, ymmword ptr log2_D
vmovaps ymm10, ymm9
vfmadd213ps ymm9, ymm0, ymmword ptr log2_C
vfmadd213ps ymm10, ymm1, ymmword ptr log2_C
vfmadd213ps ymm9, ymm0, ymmword ptr log2_B
vfmadd213ps ymm10, ymm1, ymmword ptr log2_B
vfmadd213ps ymm9, ymm0, ymmword ptr log2_A
vfmadd213ps ymm10, ymm1, ymmword ptr log2_A
vfmadd213ps ymm9, ymm0, ymm2
vfmadd213ps ymm10, ymm1, ymm2
vfmadd132ps ymm5, ymm7, ymmword ptr log2_log2
vfmadd132ps ymm6, ymm8, ymmword ptr log2_log2
vfmadd213ps ymm0, ymm9, ymm5
vfmadd213ps ymm1, ymm10, ymm6
vmovups ymmword ptr [r10], ymm0
vmovups ymmword ptr [r10+32], ymm1
add r10, 64
sub r8, 16
@L22:
cmp r8, 16
jae @L21
jmp @L24
align 32
@L23:
vmovups ymm0, ymmword ptr [r11]
add r11, 32
vandps ymm5, ymm0, ymmword ptr log2_0x7fffffff
vpsrld ymm5, ymm5, 23
vcvtdq2ps ymm5, ymm5
vsubps ymm5, ymm5, ymmword ptr log2_f127
vandps ymm0, ymm0, ymmword ptr log2_0xffffff
vorps ymm0, ymm0, ymm2
vaddps ymm6, ymm0, ymmword ptr log2_ROUND
vcmpgeps ymm8, ymm0, ymmword ptr log2_BOUND
vandps ymm9, ymm2, ymm8
vaddps ymm5, ymm5, ymm9
vblendvps ymm9, ymm2, ymmword ptr log2_f0p5, ymm8
vmulps ymm0, ymm0, ymm9
vpermps ymm7, ymm6, ymm3
vfmsub213ps ymm0, ymm7, ymm2
vpermps ymm6, ymm6, ymm4
vmovaps ymm7, ymmword ptr log2_D
vfmadd213ps ymm7, ymm0, ymmword ptr log2_C
vfmadd213ps ymm7, ymm0, ymmword ptr log2_B
vfmadd213ps ymm7, ymm0, ymmword ptr log2_A
vfmadd213ps ymm7, ymm0, ymm2
vfmadd132ps ymm5, ymm6, ymmword ptr log2_log2
vfmadd213ps ymm0, ymm7, ymm5
vmovups ymmword ptr [r10], ymm0
add r10, 32
sub r8, 8
@L24:
cmp r8, 8
jae @L23
@L25:
and ecx, 7
jz @L28
xor rdx, rdx
@L26:
mov eax, [r11+rdx*4]
mov [rsp+rdx*4], eax
add rdx, 1
cmp rdx, rcx
jne @L26
vmovups ymm0, ymmword ptr [rsp]
vandps ymm5, ymm0, ymmword ptr log2_0x7fffffff
vpsrld ymm5, ymm5, 23
vcvtdq2ps ymm5, ymm5
vsubps ymm5, ymm5, ymmword ptr log2_f127
vandps ymm0, ymm0, ymmword ptr log2_0xffffff
vorps ymm0, ymm0, ymm2
vaddps ymm6, ymm0, ymmword ptr log2_ROUND
vcmpgeps ymm8, ymm0, ymmword ptr log2_BOUND
vandps ymm9, ymm2, ymm8
vaddps ymm5, ymm5, ymm9
vblendvps ymm9, ymm2, ymmword ptr log2_f0p5, ymm8
vmulps ymm0, ymm0, ymm9
vpermps ymm7, ymm6, ymm3
vfmsub213ps ymm0, ymm7, ymm2
vpermps ymm6, ymm6, ymm4
vmovaps ymm7, ymmword ptr log2_D
vfmadd213ps ymm7, ymm0, ymmword ptr log2_C
vfmadd213ps ymm7, ymm0, ymmword ptr log2_B
vfmadd213ps ymm7, ymm0, ymmword ptr log2_A
vfmadd213ps ymm7, ymm0, ymm2
vfmadd132ps ymm5, ymm6, ymmword ptr log2_log2
vfmadd213ps ymm0, ymm7, ymm5
vmovups ymmword ptr [rsp], ymm0
xor rdx, rdx
@L27:
mov eax, [rsp+rdx*4]
mov [r10+rdx*4], eax
add rdx, 1
cmp rdx, rcx
jne @L27
@L28:
vmovups xmm5, xmmword ptr [rsp+32]
vmovups xmm6, xmmword ptr [rsp+48]
vmovups xmm7, xmmword ptr [rsp+64]
vmovups xmm8, xmmword ptr [rsp+80]
vmovups xmm9, xmmword ptr [rsp+96]
vmovups xmm10, xmmword ptr [rsp+112]
vmovups xmm11, xmmword ptr [rsp+128]
vmovups xmm12, xmmword ptr [rsp+144]
vzeroupper
add rsp, 168
ret
fmath_logf_v_avx2 endp
_text$x ends
end
