; for masm (ml64.exe)
_data$x segment align(64)
align 32
exp_coef:
dd 3f800000h
dd 3f317218h
dd 3e75fd0bh
dd 3d63578ah
dd 3c1e6362h
dd 3aaf9319h
align 32
log_coef:
dd 3f800000h
dd 0bf000000h
dd 3eaab2d3h
dd 0be800b20h
log2:
dd 3f317218h
abs_mask:
dd 7fffffffh
log_boundary:
dd 3ca3d70ah
log_nan:
dd 7fc00000h
log_mInf:
dd 0ff800000h
log_tbl1:
dd 3f783e10h
dd 3f6a0ea1h
dd 3f5d67c9h
dd 3f520d21h
dd 3f47ce0ch
dd 3f3e82fah
dd 3f360b61h
dd 3f2e4c41h
dd 3f272f05h
dd 3f20a0a1h
dd 3f1a90e8h
dd 3f14f209h
dd 3f0fb824h
dd 3f0ad8f3h
dd 3f064b8ah
dd 3f020821h
log_tbl2:
dd 0bcfc14c8h
dd 0bdb78694h
dd 0be14aa96h
dd 0be4a92d4h
dd 0be7dc8c6h
dd 0be974716h
dd 0beae8dedh
dd 0bec4d19dh
dd 0beda27bdh
dd 0beeea34fh
dd 0bf012a95h
dd 0bf0aa61fh
dd 0bf13caf0h
dd 0bf1c9f07h
dd 0bf2527c4h
dd 0bf2d6a01h
_data$x ends
_text$x segment align(64) execute
align 16
fmath_expf_avx512 proc export
sub rsp, 904
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
mov r10, rcx
mov eax, 1069066811
vpbroadcastd zmm18, eax
vbroadcastss zmm12, dword ptr exp_coef
vbroadcastss zmm13, dword ptr exp_coef+4
vbroadcastss zmm14, dword ptr exp_coef+8
vbroadcastss zmm15, dword ptr exp_coef+12
vbroadcastss zmm16, dword ptr exp_coef+16
vbroadcastss zmm17, dword ptr exp_coef+20
mov rcx, r8
jmp @L2
align 32
@L1:
vmovups zmm0, zmmword ptr [rdx]
vmovups zmm1, zmmword ptr [rdx+64]
vmovups zmm2, zmmword ptr [rdx+128]
vmovups zmm3, zmmword ptr [rdx+192]
add rdx, 256
vmulps zmm0, zmm0, zmm18
vmulps zmm1, zmm1, zmm18
vmulps zmm2, zmm2, zmm18
vmulps zmm3, zmm3, zmm18
vreduceps zmm4, zmm0, 0
vreduceps zmm5, zmm1, 0
vreduceps zmm6, zmm2, 0
vreduceps zmm7, zmm3, 0
vsubps zmm0, zmm0, zmm4
vsubps zmm1, zmm1, zmm5
vsubps zmm2, zmm2, zmm6
vsubps zmm3, zmm3, zmm7
vmovaps zmm8, zmm17
vmovaps zmm9, zmm17
vmovaps zmm10, zmm17
vmovaps zmm11, zmm17
vfmadd213ps zmm8, zmm4, zmm16
vfmadd213ps zmm9, zmm5, zmm16
vfmadd213ps zmm10, zmm6, zmm16
vfmadd213ps zmm11, zmm7, zmm16
vfmadd213ps zmm8, zmm4, zmm15
vfmadd213ps zmm9, zmm5, zmm15
vfmadd213ps zmm10, zmm6, zmm15
vfmadd213ps zmm11, zmm7, zmm15
vfmadd213ps zmm8, zmm4, zmm14
vfmadd213ps zmm9, zmm5, zmm14
vfmadd213ps zmm10, zmm6, zmm14
vfmadd213ps zmm11, zmm7, zmm14
vfmadd213ps zmm8, zmm4, zmm13
vfmadd213ps zmm9, zmm5, zmm13
vfmadd213ps zmm10, zmm6, zmm13
vfmadd213ps zmm11, zmm7, zmm13
vfmadd213ps zmm8, zmm4, zmm12
vfmadd213ps zmm9, zmm5, zmm12
vfmadd213ps zmm10, zmm6, zmm12
vfmadd213ps zmm11, zmm7, zmm12
vscalefps zmm0, zmm8, zmm0
vscalefps zmm1, zmm9, zmm1
vscalefps zmm2, zmm10, zmm2
vscalefps zmm3, zmm11, zmm3
vmovups zmmword ptr [r10], zmm0
vmovups zmmword ptr [r10+64], zmm1
vmovups zmmword ptr [r10+128], zmm2
vmovups zmmword ptr [r10+192], zmm3
add r10, 256
sub r8, 64
@L2:
cmp r8, 64
jae @L1
jmp @L4
align 32
@L3:
vmovups zmm0, zmmword ptr [rdx]
add rdx, 64
vmulps zmm0, zmm0, zmm18
vreduceps zmm4, zmm0, 0
vsubps zmm0, zmm0, zmm4
vmovaps zmm8, zmm17
vfmadd213ps zmm8, zmm4, zmm16
vfmadd213ps zmm8, zmm4, zmm15
vfmadd213ps zmm8, zmm4, zmm14
vfmadd213ps zmm8, zmm4, zmm13
vfmadd213ps zmm8, zmm4, zmm12
vscalefps zmm0, zmm8, zmm0
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
vmulps zmm0, zmm0, zmm18
vreduceps zmm4, zmm0, 0
vsubps zmm0, zmm0, zmm4
vmovaps zmm8, zmm17
vfmadd213ps zmm8, zmm4, zmm16
vfmadd213ps zmm8, zmm4, zmm15
vfmadd213ps zmm8, zmm4, zmm14
vfmadd213ps zmm8, zmm4, zmm13
vfmadd213ps zmm8, zmm4, zmm12
vscalefps zmm0, zmm8, zmm0
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
add rsp, 904
ret
fmath_expf_avx512 endp
align 16
fmath_logf_avx512 proc export
sub rsp, 1224
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
mov r10, rcx
mov eax, 1065353216
vpbroadcastd zmm20, eax
vmovups zmm21, zmmword ptr log_tbl1
vmovups zmm22, zmmword ptr log_tbl2
mov rcx, r8
jmp @L8
align 32
@L7:
vmovups zmm0, zmmword ptr [rdx]
vmovups zmm1, zmmword ptr [rdx+64]
vmovups zmm2, zmmword ptr [rdx+128]
vmovups zmm3, zmmword ptr [rdx+192]
add rdx, 256
vmovaps zmm16, zmm0
vmovaps zmm17, zmm1
vmovaps zmm18, zmm2
vmovaps zmm19, zmm3
vgetexpps zmm4, zmm0
vgetexpps zmm5, zmm1
vgetexpps zmm6, zmm2
vgetexpps zmm7, zmm3
vgetmantps zmm0, zmm0, 0
vgetmantps zmm1, zmm1, 0
vgetmantps zmm2, zmm2, 0
vgetmantps zmm3, zmm3, 0
vpsrad zmm8, zmm0, 19
vpsrad zmm9, zmm1, 19
vpsrad zmm10, zmm2, 19
vpsrad zmm11, zmm3, 19
vpermps zmm12, zmm8, zmm21
vpermps zmm13, zmm9, zmm21
vpermps zmm14, zmm10, zmm21
vpermps zmm15, zmm11, zmm21
vfmsub213ps zmm0, zmm12, zmm20
vfmsub213ps zmm1, zmm13, zmm20
vfmsub213ps zmm2, zmm14, zmm20
vfmsub213ps zmm3, zmm15, zmm20
vpermps zmm12, zmm8, zmm22
vpermps zmm13, zmm9, zmm22
vpermps zmm14, zmm10, zmm22
vpermps zmm15, zmm11, zmm22
vfmsub132ps zmm4, zmm12, dword bcst log2
vfmsub132ps zmm5, zmm13, dword bcst log2
vfmsub132ps zmm6, zmm14, dword bcst log2
vfmsub132ps zmm7, zmm15, dword bcst log2
vsubps zmm8, zmm16, zmm20
vsubps zmm9, zmm17, zmm20
vsubps zmm10, zmm18, zmm20
vsubps zmm11, zmm19, zmm20
vandps zmm8, zmm8, dword bcst abs_mask
vandps zmm9, zmm9, dword bcst abs_mask
vandps zmm10, zmm10, dword bcst abs_mask
vandps zmm11, zmm11, dword bcst abs_mask
vcmpltps k2, zmm8, dword bcst log_boundary
vcmpltps k3, zmm9, dword bcst log_boundary
vcmpltps k4, zmm10, dword bcst log_boundary
vcmpltps k5, zmm11, dword bcst log_boundary
vsubps zmm0{k2}, zmm16, zmm20
vsubps zmm1{k3}, zmm17, zmm20
vsubps zmm2{k4}, zmm18, zmm20
vsubps zmm3{k5}, zmm19, zmm20
vxorps zmm4{k2}, zmm4, zmm4
vxorps zmm5{k3}, zmm5, zmm5
vxorps zmm6{k4}, zmm6, zmm6
vxorps zmm7{k5}, zmm7, zmm7
vpbroadcastd zmm8, dword ptr log_coef+12
vmovaps zmm9, zmm8
vmovaps zmm10, zmm8
vmovaps zmm11, zmm8
vfmadd213ps zmm8, zmm0, dword bcst log_coef+8
vfmadd213ps zmm9, zmm1, dword bcst log_coef+8
vfmadd213ps zmm10, zmm2, dword bcst log_coef+8
vfmadd213ps zmm11, zmm3, dword bcst log_coef+8
vfmadd213ps zmm8, zmm0, dword bcst log_coef+4
vfmadd213ps zmm9, zmm1, dword bcst log_coef+4
vfmadd213ps zmm10, zmm2, dword bcst log_coef+4
vfmadd213ps zmm11, zmm3, dword bcst log_coef+4
vfmadd213ps zmm8, zmm0, zmm20
vfmadd213ps zmm9, zmm1, zmm20
vfmadd213ps zmm10, zmm2, zmm20
vfmadd213ps zmm11, zmm3, zmm20
vfmadd213ps zmm0, zmm8, zmm4
vfmadd213ps zmm1, zmm9, zmm5
vfmadd213ps zmm2, zmm10, zmm6
vfmadd213ps zmm3, zmm11, zmm7
vfpclassps k2, zmm16, 64
vfpclassps k3, zmm17, 64
vfpclassps k4, zmm18, 64
vfpclassps k5, zmm19, 64
vblendmps zmm0{k2}, zmm0, dword bcst log_nan
vblendmps zmm1{k3}, zmm1, dword bcst log_nan
vblendmps zmm2{k4}, zmm2, dword bcst log_nan
vblendmps zmm3{k5}, zmm3, dword bcst log_nan
vfpclassps k2, zmm16, 6
vfpclassps k3, zmm17, 6
vfpclassps k4, zmm18, 6
vfpclassps k5, zmm19, 6
vblendmps zmm0{k2}, zmm0, dword bcst log_mInf
vblendmps zmm1{k3}, zmm1, dword bcst log_mInf
vblendmps zmm2{k4}, zmm2, dword bcst log_mInf
vblendmps zmm3{k5}, zmm3, dword bcst log_mInf
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
vmovaps zmm16, zmm0
vgetexpps zmm4, zmm0
vgetmantps zmm0, zmm0, 0
vpsrad zmm8, zmm0, 19
vpermps zmm12, zmm8, zmm21
vfmsub213ps zmm0, zmm12, zmm20
vpermps zmm12, zmm8, zmm22
vfmsub132ps zmm4, zmm12, dword bcst log2
vsubps zmm8, zmm16, zmm20
vandps zmm8, zmm8, dword bcst abs_mask
vcmpltps k2, zmm8, dword bcst log_boundary
vsubps zmm0{k2}, zmm16, zmm20
vxorps zmm4{k2}, zmm4, zmm4
vpbroadcastd zmm8, dword ptr log_coef+12
vfmadd213ps zmm8, zmm0, dword bcst log_coef+8
vfmadd213ps zmm8, zmm0, dword bcst log_coef+4
vfmadd213ps zmm8, zmm0, zmm20
vfmadd213ps zmm0, zmm8, zmm4
vfpclassps k2, zmm16, 64
vblendmps zmm0{k2}, zmm0, dword bcst log_nan
vfpclassps k2, zmm16, 6
vblendmps zmm0{k2}, zmm0, dword bcst log_mInf
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
vmovaps zmm16, zmm0
vgetexpps zmm4, zmm0
vgetmantps zmm0, zmm0, 0
vpsrad zmm8, zmm0, 19
vpermps zmm12, zmm8, zmm21
vfmsub213ps zmm0, zmm12, zmm20
vpermps zmm12, zmm8, zmm22
vfmsub132ps zmm4, zmm12, dword bcst log2
vsubps zmm8, zmm16, zmm20
vandps zmm8, zmm8, dword bcst abs_mask
vcmpltps k2, zmm8, dword bcst log_boundary
vsubps zmm0{k2}, zmm16, zmm20
vxorps zmm4{k2}, zmm4, zmm4
vpbroadcastd zmm8, dword ptr log_coef+12
vfmadd213ps zmm8, zmm0, dword bcst log_coef+8
vfmadd213ps zmm8, zmm0, dword bcst log_coef+4
vfmadd213ps zmm8, zmm0, zmm20
vfmadd213ps zmm0, zmm8, zmm4
vfpclassps k2, zmm16, 64
vblendmps zmm0{k2}, zmm0, dword bcst log_nan
vfpclassps k2, zmm16, 6
vblendmps zmm0{k2}, zmm0, dword bcst log_mInf
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
add rsp, 1224
ret
fmath_logf_avx512 endp
_text$x ends
end
