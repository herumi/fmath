; for masm (ml64.exe)
_data$x segment align(64)
log2_e:
dd 3fb8aa3bh
exp_coef:
dd 3f800000h,3f317218h,3e75fd0bh,3d63578ah,3c1e6362h,3aaf9319h
align 32
log_coef:
dd 3f800000h,0bf000000h,3eaab2d3h,0be800b20h
log2:
dd 3f317218h
_0x7fffffff:
dd 7fffffffh
log_boundary:
dd 3ca3d70ah
NaN:
dd 7fc00000h
minusInf:
dd 0ff800000h
log_tbl1:
dd 3f783e10h,3f6a0ea1h,3f5d67c9h,3f520d21h,3f47ce0ch,3f3e82fah,3f360b61h,3f2e4c41h,3f272f05h,3f20a0a1h,3f1a90e8h,3f14f209h,3f0fb824h,3f0ad8f3h,3f064b8ah,3f020821h
log_tbl2:
dd 0bcfc14c8h,0bdb78694h,0be14aa96h,0be4a92d4h,0be7dc8c6h,0be974716h,0beae8dedh,0bec4d19dh,0beda27bdh,0beeea34fh,0bf012a95h,0bf0aa61fh,0bf13caf0h,0bf1c9f07h,0bf2527c4h,0bf2d6a01h
_data$x ends
_text$x segment align(64) execute
align 16
fmath_expf_avx512 proc export
sub rsp, 1480
vmovups zmmword ptr [rsp], zmm5
vmovups zmmword ptr [rsp+64], zmm6
vmovups zmmword ptr [rsp+128], zmm7
vmovups zmmword ptr [rsp+192], zmm8
vmovups zmmword ptr [rsp+256], zmm9
vmovups zmmword ptr [rsp+320], zmm10
vmovups zmmword ptr [rsp+384], zmm11
vmovups zmmword ptr [rsp+448], zmm12
vmovups zmmword ptr [rsp+512], zmm13
vmovups zmmword ptr [rsp+576], zmm14
vmovups zmmword ptr [rsp+640], zmm15
vmovups zmmword ptr [rsp+704], zmm16
vmovups zmmword ptr [rsp+768], zmm17
vmovups zmmword ptr [rsp+832], zmm18
vmovups zmmword ptr [rsp+896], zmm19
vmovups zmmword ptr [rsp+960], zmm20
vmovups zmmword ptr [rsp+1024], zmm21
vmovups zmmword ptr [rsp+1088], zmm22
vmovups zmmword ptr [rsp+1152], zmm23
vmovups zmmword ptr [rsp+1216], zmm24
vmovups zmmword ptr [rsp+1280], zmm25
vmovups zmmword ptr [rsp+1344], zmm26
vmovups zmmword ptr [rsp+1408], zmm27
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
vmovups zmm5, zmmword ptr [rsp]
vmovups zmm6, zmmword ptr [rsp+64]
vmovups zmm7, zmmword ptr [rsp+128]
vmovups zmm8, zmmword ptr [rsp+192]
vmovups zmm9, zmmword ptr [rsp+256]
vmovups zmm10, zmmword ptr [rsp+320]
vmovups zmm11, zmmword ptr [rsp+384]
vmovups zmm12, zmmword ptr [rsp+448]
vmovups zmm13, zmmword ptr [rsp+512]
vmovups zmm14, zmmword ptr [rsp+576]
vmovups zmm15, zmmword ptr [rsp+640]
vmovups zmm16, zmmword ptr [rsp+704]
vmovups zmm17, zmmword ptr [rsp+768]
vmovups zmm18, zmmword ptr [rsp+832]
vmovups zmm19, zmmword ptr [rsp+896]
vmovups zmm20, zmmword ptr [rsp+960]
vmovups zmm21, zmmword ptr [rsp+1024]
vmovups zmm22, zmmword ptr [rsp+1088]
vmovups zmm23, zmmword ptr [rsp+1152]
vmovups zmm24, zmmword ptr [rsp+1216]
vmovups zmm25, zmmword ptr [rsp+1280]
vmovups zmm26, zmmword ptr [rsp+1344]
vmovups zmm27, zmmword ptr [rsp+1408]
add rsp, 1480
ret
fmath_expf_avx512 endp
align 16
fmath_logf_avx512 proc export
sub rsp, 1288
vmovups zmmword ptr [rsp], zmm5
vmovups zmmword ptr [rsp+64], zmm6
vmovups zmmword ptr [rsp+128], zmm7
vmovups zmmword ptr [rsp+192], zmm8
vmovups zmmword ptr [rsp+256], zmm9
vmovups zmmword ptr [rsp+320], zmm10
vmovups zmmword ptr [rsp+384], zmm11
vmovups zmmword ptr [rsp+448], zmm12
vmovups zmmword ptr [rsp+512], zmm13
vmovups zmmword ptr [rsp+576], zmm14
vmovups zmmword ptr [rsp+640], zmm15
vmovups zmmword ptr [rsp+704], zmm16
vmovups zmmword ptr [rsp+768], zmm17
vmovups zmmword ptr [rsp+832], zmm18
vmovups zmmword ptr [rsp+896], zmm19
vmovups zmmword ptr [rsp+960], zmm20
vmovups zmmword ptr [rsp+1024], zmm21
vmovups zmmword ptr [rsp+1088], zmm22
vmovups zmmword ptr [rsp+1152], zmm23
vmovups zmmword ptr [rsp+1216], zmm24
mov r10, rcx
mov eax, 1065353216
vpbroadcastd zmm4, eax
vbroadcastss zmm8, dword ptr log_coef+12
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
vmovaps zmm21, zmm0
vmovaps zmm22, zmm1
vmovaps zmm23, zmm2
vmovaps zmm24, zmm3
vgetexpps zmm9, zmm0
vgetexpps zmm10, zmm1
vgetexpps zmm11, zmm2
vgetexpps zmm12, zmm3
vgetmantps zmm0, zmm0, 0
vgetmantps zmm1, zmm1, 0
vgetmantps zmm2, zmm2, 0
vgetmantps zmm3, zmm3, 0
vpsrad zmm13, zmm0, 19
vpsrad zmm14, zmm1, 19
vpsrad zmm15, zmm2, 19
vpsrad zmm16, zmm3, 19
vpermps zmm17, zmm13, zmm5
vpermps zmm18, zmm14, zmm5
vpermps zmm19, zmm15, zmm5
vpermps zmm20, zmm16, zmm5
vfmsub213ps zmm0, zmm17, zmm4
vfmsub213ps zmm1, zmm18, zmm4
vfmsub213ps zmm2, zmm19, zmm4
vfmsub213ps zmm3, zmm20, zmm4
vpermps zmm17, zmm13, zmm6
vpermps zmm18, zmm14, zmm6
vpermps zmm19, zmm15, zmm6
vpermps zmm20, zmm16, zmm6
vfmsub132ps zmm9, zmm17, dword bcst log2
vfmsub132ps zmm10, zmm18, dword bcst log2
vfmsub132ps zmm11, zmm19, dword bcst log2
vfmsub132ps zmm12, zmm20, dword bcst log2
vsubps zmm13, zmm21, zmm4
vsubps zmm14, zmm22, zmm4
vsubps zmm15, zmm23, zmm4
vsubps zmm16, zmm24, zmm4
vandps zmm17, zmm13, dword bcst _0x7fffffff
vandps zmm18, zmm14, dword bcst _0x7fffffff
vandps zmm19, zmm15, dword bcst _0x7fffffff
vandps zmm20, zmm16, dword bcst _0x7fffffff
vcmpltps k2, zmm17, dword bcst log_boundary
vcmpltps k3, zmm18, dword bcst log_boundary
vcmpltps k4, zmm19, dword bcst log_boundary
vcmpltps k5, zmm20, dword bcst log_boundary
vmovaps zmm0{k2}, zmm13
vmovaps zmm1{k3}, zmm14
vmovaps zmm2{k4}, zmm15
vmovaps zmm3{k5}, zmm16
vxorps zmm9{k2}, zmm9, zmm9
vxorps zmm10{k3}, zmm10, zmm10
vxorps zmm11{k4}, zmm11, zmm11
vxorps zmm12{k5}, zmm12, zmm12
vmovaps zmm13, zmm8
vmovaps zmm14, zmm8
vmovaps zmm15, zmm8
vmovaps zmm16, zmm8
vfmadd213ps zmm13, zmm0, dword bcst log_coef+8
vfmadd213ps zmm14, zmm1, dword bcst log_coef+8
vfmadd213ps zmm15, zmm2, dword bcst log_coef+8
vfmadd213ps zmm16, zmm3, dword bcst log_coef+8
vfmadd213ps zmm13, zmm0, dword bcst log_coef+4
vfmadd213ps zmm14, zmm1, dword bcst log_coef+4
vfmadd213ps zmm15, zmm2, dword bcst log_coef+4
vfmadd213ps zmm16, zmm3, dword bcst log_coef+4
vfmadd213ps zmm13, zmm0, zmm4
vfmadd213ps zmm14, zmm1, zmm4
vfmadd213ps zmm15, zmm2, zmm4
vfmadd213ps zmm16, zmm3, zmm4
vfmadd213ps zmm0, zmm13, zmm9
vfmadd213ps zmm1, zmm14, zmm10
vfmadd213ps zmm2, zmm15, zmm11
vfmadd213ps zmm3, zmm16, zmm12
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
vmovaps zmm12, zmm0
vgetexpps zmm9, zmm0
vgetmantps zmm0, zmm0, 0
vpsrad zmm10, zmm0, 19
vpermps zmm11, zmm10, zmm5
vfmsub213ps zmm0, zmm11, zmm4
vpermps zmm11, zmm10, zmm6
vfmsub132ps zmm9, zmm11, dword bcst log2
vsubps zmm10, zmm12, zmm4
vandps zmm11, zmm10, dword bcst _0x7fffffff
vcmpltps k2, zmm11, dword bcst log_boundary
vmovaps zmm0{k2}, zmm10
vxorps zmm9{k2}, zmm9, zmm9
vmovaps zmm10, zmm8
vfmadd213ps zmm10, zmm0, dword bcst log_coef+8
vfmadd213ps zmm10, zmm0, dword bcst log_coef+4
vfmadd213ps zmm10, zmm0, zmm4
vfmadd213ps zmm0, zmm10, zmm9
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
vmovaps zmm12, zmm0
vgetexpps zmm9, zmm0
vgetmantps zmm0, zmm0, 0
vpsrad zmm10, zmm0, 19
vpermps zmm11, zmm10, zmm5
vfmsub213ps zmm0, zmm11, zmm4
vpermps zmm11, zmm10, zmm6
vfmsub132ps zmm9, zmm11, dword bcst log2
vsubps zmm10, zmm12, zmm4
vandps zmm11, zmm10, dword bcst _0x7fffffff
vcmpltps k2, zmm11, dword bcst log_boundary
vmovaps zmm0{k2}, zmm10
vxorps zmm9{k2}, zmm9, zmm9
vmovaps zmm10, zmm8
vfmadd213ps zmm10, zmm0, dword bcst log_coef+8
vfmadd213ps zmm10, zmm0, dword bcst log_coef+4
vfmadd213ps zmm10, zmm0, zmm4
vfmadd213ps zmm0, zmm10, zmm9
vmovups zmmword ptr [r10]{k1}, zmm0
@L12:
vmovups zmm5, zmmword ptr [rsp]
vmovups zmm6, zmmword ptr [rsp+64]
vmovups zmm7, zmmword ptr [rsp+128]
vmovups zmm8, zmmword ptr [rsp+192]
vmovups zmm9, zmmword ptr [rsp+256]
vmovups zmm10, zmmword ptr [rsp+320]
vmovups zmm11, zmmword ptr [rsp+384]
vmovups zmm12, zmmword ptr [rsp+448]
vmovups zmm13, zmmword ptr [rsp+512]
vmovups zmm14, zmmword ptr [rsp+576]
vmovups zmm15, zmmword ptr [rsp+640]
vmovups zmm16, zmmword ptr [rsp+704]
vmovups zmm17, zmmword ptr [rsp+768]
vmovups zmm18, zmmword ptr [rsp+832]
vmovups zmm19, zmmword ptr [rsp+896]
vmovups zmm20, zmmword ptr [rsp+960]
vmovups zmm21, zmmword ptr [rsp+1024]
vmovups zmm22, zmmword ptr [rsp+1088]
vmovups zmm23, zmmword ptr [rsp+1152]
vmovups zmm24, zmmword ptr [rsp+1216]
add rsp, 1288
ret
fmath_logf_avx512 endp
_text$x ends
end
