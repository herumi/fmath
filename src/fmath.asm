; for masm (ml64.exe)
_data$x segment align(64)
log2_e:
dd 3fb8aa3bh
exp_coef:
dd 3f800000h,3f317218h,3e75fd0bh,3d63578ah,3c1e6362h,3aaf9319h
align 32
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
NaN:
dd 7fc00000h
minusInf:
dd 0ff800000h
log_tbl1:
dd 3f800000h,3f714349h,3f63937fh,3f579acch,3f4cd4afh,3f430d4fh,3f3a3632h,3f321ac1h,3faab27ah,3fa3d44bh,3f9d8e2fh,3f97b205h,3f924ac6h,3f8d409fh,3f888c06h,3f826cdah
log_tbl2:
dd 0h,3d72da9ch,3df108c5h,3e2fda3bh,3e645854h,3e8b37f6h,3ea2f755h,3eb9c1d5h,0be93627eh,0be7cb7b8h,0be54bb9bh,0be2deba5h,0be08c7deh,0bdc9c3f4h,0bd84611fh,0bc99c2c4h
_data$x ends
_text$x segment align(64) execute
align 16
fmath_expf_avx512 proc export
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
fmath_expf_avx512 endp
align 16
fmath_logf_avx512 proc export
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
vbroadcastss zmm8, dword ptr log_A0
vbroadcastss zmm9, dword ptr log_coef+8
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
vmovaps zmm22, zmm0
vmovaps zmm23, zmm1
vmovaps zmm24, zmm2
vmovaps zmm25, zmm3
vgetexpps zmm10, zmm0
vgetexpps zmm11, zmm1
vgetexpps zmm12, zmm2
vgetexpps zmm13, zmm3
vgetmantps zmm0, zmm0, 0
vgetmantps zmm1, zmm1, 0
vgetmantps zmm2, zmm2, 0
vgetmantps zmm3, zmm3, 0
vmovaps zmm14, zmm0
vmovaps zmm15, zmm1
vmovaps zmm16, zmm2
vmovaps zmm17, zmm3
vfmadd213ps zmm14, zmm8, dword bcst log_A1
vfmadd213ps zmm15, zmm8, dword bcst log_A1
vfmadd213ps zmm16, zmm8, dword bcst log_A1
vfmadd213ps zmm17, zmm8, dword bcst log_A1
vcmpgeps k2, zmm0, dword bcst log_A2
vcmpgeps k3, zmm1, dword bcst log_A2
vcmpgeps k4, zmm2, dword bcst log_A2
vcmpgeps k5, zmm3, dword bcst log_A2
vaddps zmm10{k2}, zmm10, zmm4
vaddps zmm11{k3}, zmm11, zmm4
vaddps zmm12{k4}, zmm12, zmm4
vaddps zmm13{k5}, zmm13, zmm4
vmulps zmm0{k2}, zmm0, dword bcst log_A3
vmulps zmm1{k3}, zmm1, dword bcst log_A3
vmulps zmm2{k4}, zmm2, dword bcst log_A3
vmulps zmm3{k5}, zmm3, dword bcst log_A3
vpermps zmm18, zmm14, zmm5
vpermps zmm19, zmm15, zmm5
vpermps zmm20, zmm16, zmm5
vpermps zmm21, zmm17, zmm5
vfmsub213ps zmm0, zmm18, zmm4
vfmsub213ps zmm1, zmm19, zmm4
vfmsub213ps zmm2, zmm20, zmm4
vfmsub213ps zmm3, zmm21, zmm4
vpermps zmm14, zmm14, zmm6
vpermps zmm15, zmm15, zmm6
vpermps zmm16, zmm16, zmm6
vpermps zmm17, zmm17, zmm6
vmovaps zmm18, zmm9
vmovaps zmm19, zmm9
vmovaps zmm20, zmm9
vmovaps zmm21, zmm9
vfmadd213ps zmm18, zmm0, dword bcst log_coef+4
vfmadd213ps zmm19, zmm1, dword bcst log_coef+4
vfmadd213ps zmm20, zmm2, dword bcst log_coef+4
vfmadd213ps zmm21, zmm3, dword bcst log_coef+4
vfmadd213ps zmm18, zmm0, dword bcst log_coef
vfmadd213ps zmm19, zmm1, dword bcst log_coef
vfmadd213ps zmm20, zmm2, dword bcst log_coef
vfmadd213ps zmm21, zmm3, dword bcst log_coef
vfmadd213ps zmm18, zmm0, zmm4
vfmadd213ps zmm19, zmm1, zmm4
vfmadd213ps zmm20, zmm2, zmm4
vfmadd213ps zmm21, zmm3, zmm4
vfmadd132ps zmm10, zmm14, dword bcst log_A4
vfmadd132ps zmm11, zmm15, dword bcst log_A4
vfmadd132ps zmm12, zmm16, dword bcst log_A4
vfmadd132ps zmm13, zmm17, dword bcst log_A4
vfmadd213ps zmm0, zmm18, zmm10
vfmadd213ps zmm1, zmm19, zmm11
vfmadd213ps zmm2, zmm20, zmm12
vfmadd213ps zmm3, zmm21, zmm13
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
vmovaps zmm13, zmm0
vgetexpps zmm10, zmm0
vgetmantps zmm0, zmm0, 0
vmovaps zmm11, zmm0
vfmadd213ps zmm11, zmm8, dword bcst log_A1
vcmpgeps k2, zmm0, dword bcst log_A2
vaddps zmm10{k2}, zmm10, zmm4
vmulps zmm0{k2}, zmm0, dword bcst log_A3
vpermps zmm12, zmm11, zmm5
vfmsub213ps zmm0, zmm12, zmm4
vpermps zmm11, zmm11, zmm6
vmovaps zmm12, zmm9
vfmadd213ps zmm12, zmm0, dword bcst log_coef+4
vfmadd213ps zmm12, zmm0, dword bcst log_coef
vfmadd213ps zmm12, zmm0, zmm4
vfmadd132ps zmm10, zmm11, dword bcst log_A4
vfmadd213ps zmm0, zmm12, zmm10
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
vmovaps zmm13, zmm0
vgetexpps zmm10, zmm0
vgetmantps zmm0, zmm0, 0
vmovaps zmm11, zmm0
vfmadd213ps zmm11, zmm8, dword bcst log_A1
vcmpgeps k2, zmm0, dword bcst log_A2
vaddps zmm10{k2}, zmm10, zmm4
vmulps zmm0{k2}, zmm0, dword bcst log_A3
vpermps zmm12, zmm11, zmm5
vfmsub213ps zmm0, zmm12, zmm4
vpermps zmm11, zmm11, zmm6
vmovaps zmm12, zmm9
vfmadd213ps zmm12, zmm0, dword bcst log_coef+4
vfmadd213ps zmm12, zmm0, dword bcst log_coef
vfmadd213ps zmm12, zmm0, zmm4
vfmadd132ps zmm10, zmm11, dword bcst log_A4
vfmadd213ps zmm0, zmm12, zmm10
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
fmath_logf_avx512 endp
_text$x ends
end
