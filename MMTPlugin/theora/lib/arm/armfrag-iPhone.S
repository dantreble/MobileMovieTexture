#import "TargetConditionals.h"

#if !defined(__arm64__) && !defined(TARGET_IPHONE_SIMULATOR)

@********************************************************************
@*                                                                  *
@* THIS FILE IS PART OF THE OggTheora SOFTWARE CODEC SOURCE CODE.   *
@* USE, DISTRIBUTION and REPRODUCTION OF THIS LIBRARY SOURCE IS     *
@* GOVERNED BY A BSD-STYLE SOURCE LICENSE INCLUDED WITH THIS SOURCE *
@* IN 'COPYING'. PLEASE READ THESE TERMS BEFORE DISTRIBUTING.       *
@*                                                                  *
@* THE Theora SOURCE CODE IS COPYRIGHT (C) 2002-2010                *
@* by the Xiph.Org Foundation and contributors http://www.xiph.org/ *
@*                                                                  *
@********************************************************************
@ Original implementation:
@  Copyright (C) 2009 Robin Watts for Pinknoise Productions Ltd
@ last mod: $Id: armfrag.s 17874 2011-02-24 14:49:11Z tterribe $
@********************************************************************

    .text

    .align 2

	@.include "theora/lib/arm/armopts-gnu.S"

@ Set the following to 1 if we have EDSP instructions
@  (ldrd/strd, etc., ARMv5E and later).
.set OC_ARM_ASM_EDSP,	1

@ Set the following to 1 if we have ARMv6 media instructions.
.set OC_ARM_ASM_MEDIA,	0

@ Set the following to 1 if we have NEON (some ARMv7)
@.set OC_ARM_ASM_NEON,	1

@ Set the following to 1 if ldr/str can work on unaligned addresses
@ This is assumed to be true for ARMv6 and later code
.set OC_ARM_CAN_UNALIGN,	1

@ Large unaligned loads and stores are often configured to cause an exception.
@ They cause an 8 cycle stall when they cross a 128-bit (load) or 64-bit (store)
@  boundary, so it's usually a bad idea to use them anyway if they can be
@  avoided.

@ Set the following to 1 if ldrd/strd can work on unaligned addresses
.set OC_ARM_CAN_UNALIGN_LDRD,	1

@ Vanilla ARM v4 versions
	.globl	_oc_frag_copy_list_arm
	.globl	_oc_frag_recon_intra_arm
	.globl	_oc_frag_recon_inter_arm
	.globl	_oc_frag_recon_inter2_arm

	@.type	_oc_frag_copy_list_arm, %function; 
_oc_frag_copy_list_arm: @ PROC
	@ r0 = _dst_frame
	@ r1 = _src_frame
	@ r2 = _ystride
	@ r3 = _fragis
	@ <> = _nfragis
	@ <> = _frag_buf_offs
	ldr	r12,[r13]		@ r12 = _nfragis
	stmfd	r13!,{r4-r6,r11,r14}
	subs	r12, r12, #1
	ldr	r4,[r3],#4		@ r4 = _fragis[fragii]
	ldrge	r14,[r13,#4*6]		@ r14 = _frag_buf_offs
	blt	ofcl_arm_end
	sub	r2, r2, #4
ofcl_arm_lp:
	ldr	r11,[r14,r4,LSL #2]	@ r11 = _frag_buf_offs[_fragis[fragii]]
	subs	r12, r12, #1
	@ Stall (on XScale)
	add	r4, r1, r11		@ r4 = _src_frame+frag_buf_off
	ldr	r6, [r4], #4
	add	r11,r0, r11		@ r11 = _dst_frame+frag_buf_off
	ldr	r5, [r4], r2
	str	r6, [r11],#4
	ldr	r6, [r4], #4
	str	r5, [r11],r2
	ldr	r5, [r4], r2
	str	r6, [r11],#4
	ldr	r6, [r4], #4
	str	r5, [r11],r2
	ldr	r5, [r4], r2
	str	r6, [r11],#4
	ldr	r6, [r4], #4
	str	r5, [r11],r2
	ldr	r5, [r4], r2
	str	r6, [r11],#4
	ldr	r6, [r4], #4
	str	r5, [r11],r2
	ldr	r5, [r4], r2
	str	r6, [r11],#4
	ldr	r6, [r4], #4
	str	r5, [r11],r2
	ldr	r5, [r4], r2
	str	r6, [r11],#4
	ldr	r6, [r4], #4
	str	r5, [r11],r2
	ldr	r5, [r4], r2
	str	r6, [r11],#4
	ldr	r6, [r4], #4
	str	r5, [r11],r2
	ldr	r5, [r4]
	ldrge	r4,[r3],#4		@ r4 = _fragis[fragii]
	str	r6, [r11],#4
	str	r5, [r11]
	bge	ofcl_arm_lp
ofcl_arm_end:
	ldmfd	r13!,{r4-r6,r11,PC}
_oc_frag_recon_intra_arm:
	@ r0 =       unsigned char *_dst
	@ r1 =       int            _ystride
	@ r2 = const ogg_int16_t    _residue[64]
	stmfd	r13!,{r4,r5,r14}
	mov	r14,#8
	mov	r5, #255
	sub	r1, r1, #7
ofrintra_lp_arm:
	ldrsh	r3, [r2], #2
	ldrsh	r4, [r2], #2
	ldrsh	r12,[r2], #2
	adds	r3, r3, #128
	cmpgt	r5, r3
	eorlt	r3, r5, r3, ASR #32
	strb	r3, [r0], #1
	adds	r4, r4, #128
	cmpgt	r5, r4
	eorlt	r4, r5, r4, ASR #32
	ldrsh	r3, [r2], #2
	strb	r4, [r0], #1
	adds	r12,r12,#128
	cmpgt	r5, r12
	eorlt	r12,r5, r12,ASR #32
	ldrsh	r4, [r2], #2
	strb	r12,[r0], #1
	adds	r3, r3, #128
	cmpgt	r5, r3
	eorlt	r3, r5, r3, ASR #32
	ldrsh	r12,[r2], #2
	strb	r3, [r0], #1
	adds	r4, r4, #128
	cmpgt	r5, r4
	eorlt	r4, r5, r4, ASR #32
	ldrsh	r3, [r2], #2
	strb	r4, [r0], #1
	adds	r12,r12,#128
	cmpgt	r5, r12
	eorlt	r12,r5, r12,ASR #32
	ldrsh	r4, [r2], #2
	strb	r12,[r0], #1
	adds	r3, r3, #128
	cmpgt	r5, r3
	eorlt	r3, r5, r3, ASR #32
	strb	r3, [r0], #1
	adds	r4, r4, #128
	cmpgt	r5, r4
	eorlt	r4, r5, r4, ASR #32
	strb	r4, [r0], r1
	subs	r14,r14,#1
	bgt	ofrintra_lp_arm
	ldmfd	r13!,{r4,r5,PC}
	@.size _oc_frag_copy_list_arm, .-_oc_frag_copy_list_arm	@ ENDP

	@.type	_oc_frag_recon_inter_arm, %function; 
_oc_frag_recon_inter_arm: @ PROC
	@ r0 =       unsigned char *dst
	@ r1 = const unsigned char *src
	@ r2 =       int            ystride
	@ r3 = const ogg_int16_t    residue[64]
	stmfd	r13!,{r5,r9-r11,r14}
	mov	r9, #8
	mov	r5, #255
	sub	r2, r2, #7
ofrinter_lp_arm:
	ldrsh	r12,[r3], #2
	ldrb	r14,[r1], #1
	ldrsh	r11,[r3], #2
	ldrb	r10,[r1], #1
	adds	r12,r12,r14
	cmpgt	r5, r12
	eorlt	r12,r5, r12,ASR #32
	strb	r12,[r0], #1
	adds	r11,r11,r10
	cmpgt	r5, r11
	ldrsh	r12,[r3], #2
	ldrb	r14,[r1], #1
	eorlt	r11,r5, r11,ASR #32
	strb	r11,[r0], #1
	adds	r12,r12,r14
	cmpgt	r5, r12
	ldrsh	r11,[r3], #2
	ldrb	r10,[r1], #1
	eorlt	r12,r5, r12,ASR #32
	strb	r12,[r0], #1
	adds	r11,r11,r10
	cmpgt	r5, r11
	ldrsh	r12,[r3], #2
	ldrb	r14,[r1], #1
	eorlt	r11,r5, r11,ASR #32
	strb	r11,[r0], #1
	adds	r12,r12,r14
	cmpgt	r5, r12
	ldrsh	r11,[r3], #2
	ldrb	r10,[r1], #1
	eorlt	r12,r5, r12,ASR #32
	strb	r12,[r0], #1
	adds	r11,r11,r10
	cmpgt	r5, r11
	ldrsh	r12,[r3], #2
	ldrb	r14,[r1], #1
	eorlt	r11,r5, r11,ASR #32
	strb	r11,[r0], #1
	adds	r12,r12,r14
	cmpgt	r5, r12
	ldrsh	r11,[r3], #2
	ldrb	r10,[r1], r2
	eorlt	r12,r5, r12,ASR #32
	strb	r12,[r0], #1
	adds	r11,r11,r10
	cmpgt	r5, r11
	eorlt	r11,r5, r11,ASR #32
	strb	r11,[r0], r2
	subs	r9, r9, #1
	bgt	ofrinter_lp_arm
	ldmfd	r13!,{r5,r9-r11,PC}
	@.size _oc_frag_recon_inter_arm, .-_oc_frag_recon_inter_arm	@ ENDP

	@.type	_oc_frag_recon_inter2_arm, %function; 
_oc_frag_recon_inter2_arm: @ PROC
	@ r0 =       unsigned char *dst
	@ r1 = const unsigned char *src1
	@ r2 = const unsigned char *src2
	@ r3 =       int            ystride
	ldr	r12,[r13]
	@ r12= const ogg_int16_t    residue[64]
	stmfd	r13!,{r4-r8,r14}
	mov	r14,#8
	mov	r8, #255
	sub	r3, r3, #7
ofrinter2_lp_arm:
	ldrb	r5, [r1], #1
	ldrb	r6, [r2], #1
	ldrsh	r4, [r12],#2
	ldrb	r7, [r1], #1
	add	r5, r5, r6
	adds	r5, r4, r5, LSR #1
	cmpgt	r8, r5
	ldrb	r6, [r2], #1
	ldrsh	r4, [r12],#2
	eorlt	r5, r8, r5, ASR #32
	strb	r5, [r0], #1
	add	r7, r7, r6
	adds	r7, r4, r7, LSR #1
	cmpgt	r8, r7
	ldrb	r5, [r1], #1
	ldrb	r6, [r2], #1
	ldrsh	r4, [r12],#2
	eorlt	r7, r8, r7, ASR #32
	strb	r7, [r0], #1
	add	r5, r5, r6
	adds	r5, r4, r5, LSR #1
	cmpgt	r8, r5
	ldrb	r7, [r1], #1
	ldrb	r6, [r2], #1
	ldrsh	r4, [r12],#2
	eorlt	r5, r8, r5, ASR #32
	strb	r5, [r0], #1
	add	r7, r7, r6
	adds	r7, r4, r7, LSR #1
	cmpgt	r8, r7
	ldrb	r5, [r1], #1
	ldrb	r6, [r2], #1
	ldrsh	r4, [r12],#2
	eorlt	r7, r8, r7, ASR #32
	strb	r7, [r0], #1
	add	r5, r5, r6
	adds	r5, r4, r5, LSR #1
	cmpgt	r8, r5
	ldrb	r7, [r1], #1
	ldrb	r6, [r2], #1
	ldrsh	r4, [r12],#2
	eorlt	r5, r8, r5, ASR #32
	strb	r5, [r0], #1
	add	r7, r7, r6
	adds	r7, r4, r7, LSR #1
	cmpgt	r8, r7
	ldrb	r5, [r1], #1
	ldrb	r6, [r2], #1
	ldrsh	r4, [r12],#2
	eorlt	r7, r8, r7, ASR #32
	strb	r7, [r0], #1
	add	r5, r5, r6
	adds	r5, r4, r5, LSR #1
	cmpgt	r8, r5
	ldrb	r7, [r1], r3
	ldrb	r6, [r2], r3
	ldrsh	r4, [r12],#2
	eorlt	r5, r8, r5, ASR #32
	strb	r5, [r0], #1
	add	r7, r7, r6
	adds	r7, r4, r7, LSR #1
	cmpgt	r8, r7
	eorlt	r7, r8, r7, ASR #32
	strb	r7, [r0], r3
	subs	r14,r14,#1
	bgt	ofrinter2_lp_arm
	ldmfd	r13!,{r4-r8,PC}
	@.size _oc_frag_recon_inter2_arm, .-_oc_frag_recon_inter2_arm	@ ENDP

  .if OC_ARM_ASM_EDSP
	.globl	_oc_frag_copy_list_edsp

	@.type	_oc_frag_copy_list_edsp, %function; 
_oc_frag_copy_list_edsp: @ PROC
	@ r0 = _dst_frame
	@ r1 = _src_frame
	@ r2 = _ystride
	@ r3 = _fragis
	@ <> = _nfragis
	@ <> = _frag_buf_offs
	ldr	r12,[r13]		@ r12 = _nfragis
	stmfd	r13!,{r4-r11,r14}
	subs	r12, r12, #1
	ldrge	r5, [r3],#4		@ r5 = _fragis[fragii]
	ldrge	r14,[r13,#4*10]		@ r14 = _frag_buf_offs
	blt	ofcl_edsp_end
ofcl_edsp_lp:
	mov	r4, r1
	ldr	r5, [r14,r5, LSL #2]	@ r5 = _frag_buf_offs[_fragis[fragii]]
	subs	r12, r12, #1
	@ Stall (on XScale)
	ldrd	r6, r7, [r4, r5]!		@ r4 = _src_frame+frag_buf_off
	ldrd	r8, r9, [r4, r2]!
	@ Stall
	strd	r6, r7, [r5, r0]!		@ r5 = _dst_frame+frag_buf_off
	strd	r8, r9, [r5, r2]!
	@ Stall
	ldrd	r6, r7, [r4, r2]!	@ On Xscale at least, doing 3 consecutive
	ldrd	r8, r9, [r4, r2]!	@ loads causes a stall, but thats no worse
	ldrd	r10,r11,[r4, r2]!	@ than us only doing 2, and having to do
				@ another pair of ldrd/strd later on.
	@ Stall
	strd	r6, r7, [r5, r2]!
	strd	r8, r9, [r5, r2]!
	strd	r10,r11,[r5, r2]!
	ldrd	r6, r7, [r4, r2]!
	ldrd	r8, r9, [r4, r2]!
	ldrd	r10,r11,[r4, r2]!
	strd	r6, r7,[r5, r2]!
	strd	r8, r9,[r5, r2]!
	strd	r10,r11,[r5, r2]!
	ldrge	r5, [r3],#4		@ r5 = _fragis[fragii]
	bge	ofcl_edsp_lp
ofcl_edsp_end:
	ldmfd	r13!,{r4-r11,PC}
	@.size _oc_frag_copy_list_edsp, .-_oc_frag_copy_list_edsp	@ ENDP
  .endif

  .if OC_ARM_ASM_MEDIA
	.globl	_oc_frag_recon_intra_v6
	.globl	_oc_frag_recon_inter_v6
	.globl	_oc_frag_recon_inter2_v6

	@.type	_oc_frag_recon_intra_v6, %function; 
_oc_frag_recon_intra_v6: @ PROC
	@ r0 =       unsigned char *_dst
	@ r1 =       int            _ystride
	@ r2 = const ogg_int16_t    _residue[64]
	stmfd	r13!,{r4-r6,r14}
	mov	r14,#8
	mov	r12,r2
	ldr	r6, =0x00800080
ofrintra_v6_lp:
	ldrd	r2, [r12],#8	@ r2 = 11110000 r3 = 33332222
	ldrd	r4, [r12],#8	@ r4 = 55554444 r5 = 77776666
	subs	r14,r14,#1
	qadd16	r2, r2, r6
	qadd16	r3, r3, r6
	qadd16	r4, r4, r6
	qadd16	r5, r5, r6
	usat16	r2, #8, r2		@ r2 = __11__00
	usat16	r3, #8, r3		@ r3 = __33__22
	usat16	r4, #8, r4		@ r4 = __55__44
	usat16	r5, #8, r5		@ r5 = __77__66
	orr	r2, r2, r2, LSR #8	@ r2 = __111100
	orr	r3, r3, r3, LSR #8	@ r3 = __333322
	orr	r4, r4, r4, LSR #8	@ r4 = __555544
	orr	r5, r5, r5, LSR #8	@ r5 = __777766
	pkhbt   r2, r2, r3, LSL #16     @ r2 = 33221100
	pkhbt   r3, r4, r5, LSL #16     @ r3 = 77665544
	strd	r2, [r0], r1
	bgt	ofrintra_v6_lp
	ldmfd	r13!,{r4-r6,PC}
	@.size _oc_frag_recon_intra_v6, .-_oc_frag_recon_intra_v6	@ ENDP

	@.type	_oc_frag_recon_inter_v6, %function; 
_oc_frag_recon_inter_v6: @ PROC
	@ r0 =       unsigned char *_dst
	@ r1 = const unsigned char *_src
	@ r2 =       int            _ystride
	@ r3 = const ogg_int16_t    _residue[64]
	stmfd	r13!,{r4-r7,r14}
	mov	r14,#8
ofrinter_v6_lp:
	ldrd	r6, [r3], #8		@ r6 = 11110000 r7 = 33332222
	subs	r14,r14,#1
  .if OC_ARM_CAN_UNALIGN_LDRD
	ldrd	r4, [r1], r2	@ Unaligned ; r4 = 33221100 r5 = 77665544
  .else
	ldr	r5, [r1, #4]
	ldr	r4, [r1], r2
  .endif
	pkhbt	r12,r6, r7, LSL #16	@ r12= 22220000
	pkhtb	r7, r7, r6, ASR #16	@ r7 = 33331111
	uxtb16	r6,r4			@ r6 = __22__00
	uxtb16	r4,r4, ROR #8		@ r4 = __33__11
	qadd16	r12,r12,r6		@ r12= xx22xx00
	qadd16	r4, r7, r4		@ r4 = xx33xx11
	ldrd	r6, [r3], #8		@ r6 = 55554444 r7 = 77776666
	usat16	r4, #8, r4		@ r4 = __33__11
	usat16	r12,#8,r12		@ r12= __22__00
	orr	r4, r12,r4, LSL #8	@ r4 = 33221100
	pkhbt	r12,r6, r7, LSL #16	@ r12= 66664444
	pkhtb	r7, r7, r6, ASR #16	@ r7 = 77775555
	uxtb16	r6,r5			@ r6 = __66__44
	uxtb16	r5,r5, ROR #8		@ r5 = __77__55
	qadd16	r12,r12,r6		@ r12= xx66xx44
	qadd16	r5, r7, r5		@ r5 = xx77xx55
	usat16	r12,#8, r12		@ r12= __66__44
	usat16	r5, #8, r5		@ r4 = __77__55
	orr	r5, r12,r5, LSL #8	@ r5 = 33221100
	strd	r4, [r0], r2
	bgt	ofrinter_v6_lp
	ldmfd	r13!,{r4-r7,PC}
	@.size _oc_frag_recon_inter_v6, .-_oc_frag_recon_inter_v6	@ ENDP

	@.type	_oc_frag_recon_inter2_v6, %function; 
_oc_frag_recon_inter2_v6: @ PROC
	@ r0 =       unsigned char *_dst
	@ r1 = const unsigned char *_src1
	@ r2 = const unsigned char *_src2
	@ r3 =       int            _ystride
	ldr	r12,[r13]
	@ r12= const ogg_int16_t    _residue[64]
	stmfd	r13!,{r4-r9,r14}
	mov	r14,#8
ofrinter2_v6_lp:
	ldrd	r6, [r12,#8]	@ r6 = 55554444 r7 = 77776666
	subs	r14,r14,#1
	ldr	r4, [r1, #4]	@ Unaligned	; r4 = src1[1] = 77665544
	ldr	r5, [r2, #4]	@ Unaligned	; r5 = src2[1] = 77665544
	pkhbt	r8, r6, r7, LSL #16	@ r8 = 66664444
	pkhtb	r9, r7, r6, ASR #16	@ r9 = 77775555
	uhadd8	r4, r4, r5	@ r4 = (src1[7,6,5,4] + src2[7,6,5,4])>>1
	uxtb16	r5, r4			@ r5 = __66__44
	uxtb16	r4, r4, ROR #8		@ r4 = __77__55
	qadd16	r8, r8, r5		@ r8 = xx66xx44
	qadd16	r9, r9, r4		@ r9 = xx77xx55
	ldrd	r6,[r12],#16	@ r6 = 33332222 r7 = 11110000
	usat16	r8, #8, r8		@ r8 = __66__44
	ldr	r4, [r1], r3	@ Unaligned	; r4 = src1[0] = 33221100
	usat16	r9, #8, r9		@ r9 = __77__55
	ldr	r5, [r2], r3	@ Unaligned	; r5 = src2[0] = 33221100
	orr	r9, r8, r9, LSL #8	@ r9 = 77665544
	pkhbt	r8, r6, r7, LSL #16	@ r8 = 22220000
	uhadd8	r4, r4, r5	@ r4 = (src1[3,2,1,0] + src2[3,2,1,0])>>1
	pkhtb	r7, r7, r6, ASR #16	@ r7 = 33331111
	uxtb16	r5, r4			@ r5 = __22__00
	uxtb16	r4, r4, ROR #8		@ r4 = __33__11
	qadd16	r8, r8, r5		@ r8 = xx22xx00
	qadd16	r7, r7, r4		@ r7 = xx33xx11
	usat16	r8, #8, r8		@ r8 = __22__00
	usat16	r7, #8, r7		@ r7 = __33__11
	orr	r8, r8, r7, LSL #8	@ r8 = 33221100
	strd	r8, [r0], r3
	bgt	ofrinter2_v6_lp
	ldmfd	r13!,{r4-r9,PC}
	@.size _oc_frag_recon_inter2_v6, .-_oc_frag_recon_inter2_v6	@ ENDP
  .endif

  .if OC_ARM_ASM_NEON
	.globl	_oc_frag_copy_list_neon
	.globl	_oc_frag_recon_intra_neon
	.globl	_oc_frag_recon_inter_neon
	.globl	_oc_frag_recon_inter2_neon

	@.type	_oc_frag_copy_list_neon, %function; 
_oc_frag_copy_list_neon: @ PROC
	@ r0 = _dst_frame
	@ r1 = _src_frame
	@ r2 = _ystride
	@ r3 = _fragis
	@ <> = _nfragis
	@ <> = _frag_buf_offs
	ldr	r12,[r13]		@ r12 = _nfragis
	stmfd	r13!,{r4-r7,r14}
	cmp	r12, #1
	ldrge	r6, [r3]		@ r6 = _fragis[fragii]
	ldrge	r14,[r13,#4*6]		@ r14 = _frag_buf_offs
	blt	ofcl_neon_end
	@ Stall (2 on Xscale)
	ldr	r6, [r14,r6, LSL #2]	@ r6 = _frag_buf_offs[_fragis[fragii]]
	@ Stall (on XScale)
	mov	r7, r6			@ Guarantee pld points somewhere valid.
ofcl_neon_lp:
	add	r4, r1, r6
	vld1.64	{D0}, [r4,:64], r2
	add	r5, r0, r6
	vld1.64	{D1}, [r4,:64], r2
	subs	r12, r12, #1
	vld1.64	{D2}, [r4,:64], r2
	ldrgt	r6, [r3,#4]!		@ r6 = _fragis[fragii]
	vld1.64	{D3}, [r4,:64], r2
	ldrgt	r6, [r14,r6, LSL #2]	@ r6 = _frag_buf_offs[_fragis[fragii]]
	vld1.64	{D4}, [r4,:64], r2
	addgt	r7, r1, r6
	vld1.64	{D5}, [r4,:64], r2
	pld	[r7]
	vld1.64	{D6}, [r4,:64], r2
	pld	[r7, r2]
	vld1.64	{D7}, [r4,:64]
	pld	[r7, r2, LSL #1]
	vst1.64	{D0}, [r5,:64], r2
	addgt	r7, r7, r2, LSL #2
	vst1.64	{D1}, [r5,:64], r2
	pld	[r7, -r2]
	vst1.64	{D2}, [r5,:64], r2
	pld	[r7]
	vst1.64	{D3}, [r5,:64], r2
	pld	[r7, r2]
	vst1.64	{D4}, [r5,:64], r2
	pld	[r7, r2, LSL #1]
	vst1.64	{D5}, [r5,:64], r2
	addgt	r7, r7, r2, LSL #2
	vst1.64	{D6}, [r5,:64], r2
	pld	[r7, -r2]
	vst1.64	{D7}, [r5,:64]
	bgt	ofcl_neon_lp
ofcl_neon_end:
	ldmfd	r13!,{r4-r7,PC}
	@.size _oc_frag_copy_list_neon, .-_oc_frag_copy_list_neon	@ ENDP

	@.type	_oc_frag_recon_intra_neon, %function; 
_oc_frag_recon_intra_neon: @ PROC
	@ r0 =       unsigned char *_dst
	@ r1 =       int            _ystride
	@ r2 = const ogg_int16_t    _residue[64]
	vmov.I16	Q0, #128
	vldmia	r2,  {D16-D31}	@ D16= 3333222211110000 etc	; 9(8) cycles
	vqadd.S16	Q8, Q8, Q0
	vqadd.S16	Q9, Q9, Q0
	vqadd.S16	Q10,Q10,Q0
	vqadd.S16	Q11,Q11,Q0
	vqadd.S16	Q12,Q12,Q0
	vqadd.S16	Q13,Q13,Q0
	vqadd.S16	Q14,Q14,Q0
	vqadd.S16	Q15,Q15,Q0
	vqmovun.S16	D16,Q8	@ D16= 7766554433221100		; 1 cycle
	vqmovun.S16	D17,Q9	@ D17= FFEEDDCCBBAA9988		; 1 cycle
	vqmovun.S16	D18,Q10	@ D18= NNMMLLKKJJIIHHGG		; 1 cycle
	vst1.64	{D16},[r0,:64], r1
	vqmovun.S16	D19,Q11	@ D19= VVUUTTSSRRQQPPOO		; 1 cycle
	vst1.64	{D17},[r0,:64], r1
	vqmovun.S16	D20,Q12	@ D20= ddccbbaaZZYYXXWW		; 1 cycle
	vst1.64	{D18},[r0,:64], r1
	vqmovun.S16	D21,Q13	@ D21= llkkjjiihhggffee		; 1 cycle
	vst1.64	{D19},[r0,:64], r1
	vqmovun.S16	D22,Q14	@ D22= ttssrrqqppoonnmm		; 1 cycle
	vst1.64	{D20},[r0,:64], r1
	vqmovun.S16	D23,Q15	@ D23= !!,:@zzyyxxwwvvuu		; 1 cycle
	vst1.64	{D21},[r0,:64], r1
	vst1.64	{D22},[r0,:64], r1
	vst1.64	{D23},[r0,:64], r1
	mov	PC,R14
	@.size _oc_frag_recon_intra_neon, .-_oc_frag_recon_intra_neon	@ ENDP

	@.type	_oc_frag_recon_inter_neon, %function; 
_oc_frag_recon_inter_neon: @ PROC
	@ r0 =       unsigned char *_dst
	@ r1 = const unsigned char *_src
	@ r2 =       int            _ystride
	@ r3 = const ogg_int16_t    _residue[64]
	vldmia	r3, {D16-D31}	@ D16= 3333222211110000 etc	; 9(8) cycles
	vld1.64	{D0}, [r1], r2
	vld1.64	{D2}, [r1], r2
	vmovl.U8	Q0, D0	@ Q0 = __77__66__55__44__33__22__11__00
	vld1.64	{D4}, [r1], r2
	vmovl.U8	Q1, D2	@ etc
	vld1.64	{D6}, [r1], r2
	vmovl.U8	Q2, D4
	vmovl.U8	Q3, D6
	vqadd.S16	Q8, Q8, Q0
	vld1.64	{D0}, [r1], r2
	vqadd.S16	Q9, Q9, Q1
	vld1.64	{D2}, [r1], r2
	vqadd.S16	Q10,Q10,Q2
	vld1.64	{D4}, [r1], r2
	vqadd.S16	Q11,Q11,Q3
	vld1.64	{D6}, [r1], r2
	vmovl.U8	Q0, D0
	vmovl.U8	Q1, D2
	vmovl.U8	Q2, D4
	vmovl.U8	Q3, D6
	vqadd.S16	Q12,Q12,Q0
	vqadd.S16	Q13,Q13,Q1
	vqadd.S16	Q14,Q14,Q2
	vqadd.S16	Q15,Q15,Q3
	vqmovun.S16	D16,Q8
	vqmovun.S16	D17,Q9
	vqmovun.S16	D18,Q10
	vst1.64	{D16},[r0,:64], r2
	vqmovun.S16	D19,Q11
	vst1.64	{D17},[r0,:64], r2
	vqmovun.S16	D20,Q12
	vst1.64	{D18},[r0,:64], r2
	vqmovun.S16	D21,Q13
	vst1.64	{D19},[r0,:64], r2
	vqmovun.S16	D22,Q14
	vst1.64	{D20},[r0,:64], r2
	vqmovun.S16	D23,Q15
	vst1.64	{D21},[r0,:64], r2
	vst1.64	{D22},[r0,:64], r2
	vst1.64	{D23},[r0,:64], r2
	mov	PC,R14
	@.size _oc_frag_recon_inter_neon, .-_oc_frag_recon_inter_neon	@ ENDP

	@.type	_oc_frag_recon_inter2_neon, %function; 
_oc_frag_recon_inter2_neon: @ PROC
	@ r0 =       unsigned char *_dst
	@ r1 = const unsigned char *_src1
	@ r2 = const unsigned char *_src2
	@ r3 =       int            _ystride
	ldr	r12,[r13]
	@ r12= const ogg_int16_t    _residue[64]
	vldmia	r12,{D16-D31}
	vld1.64	{D0}, [r1], r3
	vld1.64	{D4}, [r2], r3
	vld1.64	{D1}, [r1], r3
	vld1.64	{D5}, [r2], r3
	vhadd.U8	Q2, Q0, Q2	@ Q2 = FFEEDDCCBBAA99887766554433221100
	vld1.64	{D2}, [r1], r3
	vld1.64	{D6}, [r2], r3
	vmovl.U8	Q0, D4		@ Q0 = __77__66__55__44__33__22__11__00
	vld1.64	{D3}, [r1], r3
	vmovl.U8	Q2, D5		@ etc
	vld1.64	{D7}, [r2], r3
	vhadd.U8	Q3, Q1, Q3
	vqadd.S16	Q8, Q8, Q0
	vqadd.S16	Q9, Q9, Q2
	vld1.64	{D0}, [r1], r3
	vmovl.U8	Q1, D6
	vld1.64	{D4}, [r2], r3
	vmovl.U8	Q3, D7
	vld1.64	{D1}, [r1], r3
	vqadd.S16	Q10,Q10,Q1
	vld1.64	{D5}, [r2], r3
	vqadd.S16	Q11,Q11,Q3
	vld1.64	{D2}, [r1], r3
	vhadd.U8	Q2, Q0, Q2
	vld1.64	{D6}, [r2], r3
	vld1.64	{D3}, [r1], r3
	vmovl.U8	Q0, D4
	vld1.64	{D7}, [r2], r3
	vmovl.U8	Q2, D5
	vhadd.U8	Q3, Q1, Q3
	vqadd.S16	Q12,Q12,Q0
	vqadd.S16	Q13,Q13,Q2
	vmovl.U8	Q1, D6
	vmovl.U8	Q3, D7
	vqadd.S16	Q14,Q14,Q1
	vqadd.S16	Q15,Q15,Q3
	vqmovun.S16	D16,Q8
	vqmovun.S16	D17,Q9
	vqmovun.S16	D18,Q10
	vst1.64	{D16},[r0,:64], r3
	vqmovun.S16	D19,Q11
	vst1.64	{D17},[r0,:64], r3
	vqmovun.S16	D20,Q12
	vst1.64	{D18},[r0,:64], r3
	vqmovun.S16	D21,Q13
	vst1.64	{D19},[r0,:64], r3
	vqmovun.S16	D22,Q14
	vst1.64	{D20},[r0,:64], r3
	vqmovun.S16	D23,Q15
	vst1.64	{D21},[r0,:64], r3
	vst1.64	{D22},[r0,:64], r3
	vst1.64	{D23},[r0,:64], r3
	mov	PC,R14
	@.size _oc_frag_recon_inter2_neon, .-_oc_frag_recon_inter2_neon	@ ENDP
  .endif

	@ END

    #endif
