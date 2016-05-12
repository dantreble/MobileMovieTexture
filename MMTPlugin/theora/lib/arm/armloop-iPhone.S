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
@ last mod: $Id: armloop.s 17481 2010-10-03 22:49:42Z tterribe $
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

	.globl	_oc_loop_filter_frag_rows_arm

@ Which bit this is depends on the order of packing within a bitfield.
@ Hopefully that doesn't change among any of the relevant compilers.
 .set OC_FRAG_CODED_FLAG,	1

	@ Vanilla ARM v4 version
	@.type	loop_filter_h_arm, %function; 
loop_filter_h_arm: @ PROC
	@ r0 = unsigned char *_pix
	@ r1 = int            _ystride
	@ r2 = int           *_bv
	@ preserves r0-r3
	stmfd	r13!,{r3-r6,r14}
	mov	r14,#8
	mov	r6, #255
lfh_arm_lp:
	ldrb	r3, [r0, #-2]		@ r3 = _pix[0]
	ldrb	r12,[r0, #1]		@ r12= _pix[3]
	ldrb	r4, [r0, #-1]		@ r4 = _pix[1]
	ldrb	r5, [r0]		@ r5 = _pix[2]
	sub	r3, r3, r12		@ r3 = _pix[0]-_pix[3]+4
	add	r3, r3, #4
	sub	r12,r5, r4		@ r12= _pix[2]-_pix[1]
	add	r12,r12,r12,LSL #1	@ r12= 3*(_pix[2]-_pix[1])
	add	r12,r12,r3	@ r12= _pix[0]-_pix[3]+3*(_pix[2]-_pix[1])+4
	mov	r12,r12,ASR #3
	ldrsb	r12,[r2, r12]
	@ Stall (2 on Xscale)
	adds	r4, r4, r12
	cmpgt	r6, r4
	eorlt	r4, r6, r4, ASR #32
	subs	r5, r5, r12
	cmpgt	r6, r5
	eorlt	r5, r6, r5, ASR #32
	strb	r4, [r0, #-1]
	strb	r5, [r0], r1
	subs	r14,r14,#1
	bgt	lfh_arm_lp
	sub	r0, r0, r1, LSL #3
	ldmfd	r13!,{r3-r6,PC}
	@.size loop_filter_h_arm, .-loop_filter_h_arm	@ ENDP

	@.type	loop_filter_v_arm, %function; 
loop_filter_v_arm: @ PROC
	@ r0 = unsigned char *_pix
	@ r1 = int            _ystride
	@ r2 = int           *_bv
	@ preserves r0-r3
	stmfd	r13!,{r3-r6,r14}
	mov	r14,#8
	mov	r6, #255
lfv_arm_lp:
	ldrb	r3, [r0, -r1, LSL #1]	@ r3 = _pix[0]
	ldrb	r12,[r0, r1]		@ r12= _pix[3]
	ldrb	r4, [r0, -r1]		@ r4 = _pix[1]
	ldrb	r5, [r0]		@ r5 = _pix[2]
	sub	r3, r3, r12		@ r3 = _pix[0]-_pix[3]+4
	add	r3, r3, #4
	sub	r12,r5, r4		@ r12= _pix[2]-_pix[1]
	add	r12,r12,r12,LSL #1	@ r12= 3*(_pix[2]-_pix[1])
	add	r12,r12,r3	@ r12= _pix[0]-_pix[3]+3*(_pix[2]-_pix[1])+4
	mov	r12,r12,ASR #3
	ldrsb	r12,[r2, r12]
	@ Stall (2 on Xscale)
	adds	r4, r4, r12
	cmpgt	r6, r4
	eorlt	r4, r6, r4, ASR #32
	subs	r5, r5, r12
	cmpgt	r6, r5
	eorlt	r5, r6, r5, ASR #32
	strb	r4, [r0, -r1]
	strb	r5, [r0], #1
	subs	r14,r14,#1
	bgt	lfv_arm_lp
	sub	r0, r0, #8
	ldmfd	r13!,{r3-r6,PC}
	@.size loop_filter_v_arm, .-loop_filter_v_arm	@ ENDP

	@.type	_oc_loop_filter_frag_rows_arm, %function; 
_oc_loop_filter_frag_rows_arm: @ PROC
	@ r0 = _ref_frame_data
	@ r1 = _ystride
	@ r2 = _bv
	@ r3 = _frags
	@ r4 = _fragi0
	@ r5 = _fragi0_end
	@ r6 = _fragi_top
	@ r7 = _fragi_bot
	@ r8 = _frag_buf_offs
	@ r9 = _nhfrags
	mov	r12,r13
	stmfd	r13!,{r0,r4-r11,r14}
	ldmfd	r12,{r4-r9}
	add	r2, r2, #127	@ _bv += 127
	cmp	r4, r5		@ if(_fragi0>=_fragi0_end)
	bge	oslffri_arm_end	@   bail
	subs	r9, r9, #1	@ r9 = _nhfrags-1	if (r9<=0)
	ble	oslffri_arm_end	@			  bail
	add	r3, r3, r4, LSL #2	@ r3 = &_frags[fragi]
	add	r8, r8, r4, LSL #2	@ r8 = &_frag_buf_offs[fragi]
	sub	r7, r7, r9	@ _fragi_bot -= _nhfrags;
oslffri_arm_lp1:
	mov	r10,r4		@ r10= fragi = _fragi0
	add	r11,r4, r9	@ r11= fragi_end-1=fragi+_nhfrags-1
oslffri_arm_lp2:
	ldr	r14,[r3], #4	@ r14= _frags[fragi]	_frags++
	ldr	r0, [r13]	@ r0 = _ref_frame_data
	ldr	r12,[r8], #4	@ r12= _frag_buf_offs[fragi]   _frag_buf_offs++
	tst	r14,#OC_FRAG_CODED_FLAG
	beq	oslffri_arm_uncoded
	cmp	r10,r4		@ if (fragi>_fragi0)
	add	r0, r0, r12	@ r0 = _ref_frame_data + _frag_buf_offs[fragi]
	blgt	loop_filter_h_arm
	cmp	r4, r6		@ if (_fragi0>_fragi_top)
	blgt	loop_filter_v_arm
	cmp	r10,r11		@ if(fragi+1<fragi_end)===(fragi<fragi_end-1)
	ldrlt	r12,[r3]	@ r12 = _frags[fragi+1]
	add	r0, r0, #8
	add	r10,r10,#1	@ r10 = fragi+1;
	andlt	r12,r12,#OC_FRAG_CODED_FLAG
	cmplt	r12,#OC_FRAG_CODED_FLAG	@ && _frags[fragi+1].coded==0
	bllt	loop_filter_h_arm
	cmp	r10,r7		@ if (fragi<_fragi_bot)
	ldrlt	r12,[r3, r9, LSL #2]	@ r12 = _frags[fragi+1+_nhfrags-1]
	sub	r0, r0, #8
	add	r0, r0, r1, LSL #3
	andlt	r12,r12,#OC_FRAG_CODED_FLAG
	cmplt	r12,#OC_FRAG_CODED_FLAG
	bllt	loop_filter_v_arm
	cmp	r10,r11		@ while(fragi<=fragi_end-1)
	ble	oslffri_arm_lp2
	mov	r4, r10		@ r4 = fragi0 += _nhfrags
	cmp	r4, r5
	blt	oslffri_arm_lp1
oslffri_arm_end:
	ldmfd	r13!,{r0,r4-r11,PC}
oslffri_arm_uncoded:
	add	r10,r10,#1
	cmp	r10,r11
	ble	oslffri_arm_lp2
	mov	r4, r10		@ r4 = _fragi0 += _nhfrags
	cmp	r4, r5
	blt	oslffri_arm_lp1
	ldmfd	r13!,{r0,r4-r11,PC}
	@.size _oc_loop_filter_frag_rows_arm, .-_oc_loop_filter_frag_rows_arm	@ ENDP

  .if OC_ARM_ASM_MEDIA
	.globl	_oc_loop_filter_init_v6
	.globl	_oc_loop_filter_frag_rows_v6

	@.type	_oc_loop_filter_init_v6, %function; _oc_loop_filter_init_v6: @ PROC
	@ r0 = _bv
	@ r1 = _flimit (=L from the spec)
	mvn	r1, r1, LSL #1		@ r1 = <0xFFFFFF|255-2*L>
	and	r1, r1, #255		@ r1 = ll=r10x0xFF
	orr	r1, r1, r1, LSL #8	@ r1 = <ll|ll>
	pkhbt	r1, r1, r1, LSL #16	@ r1 = <ll|ll|ll|ll>
	str	r1, [r0]
	mov	PC,r14
	@.size _oc_loop_filter_init_v6, .-_oc_loop_filter_init_v6	@ ENDP

@ We could use the same strategy as the v filter below, but that would require
@  40 instructions to load the data and transpose it into columns and another
@  32 to write out the results at the end, plus the 52 instructions to do the
@  filtering itself.
@ This is slightly less, and less code, even assuming we could have shared the
@  52 instructions in the middle with the other function.
@ It executes slightly fewer instructions than the ARMv6 approach David Conrad
@  proposed for FFmpeg, but not by much:
@  http://lists.mplayerhq.hu/pipermail/ffmpeg-devel/2010-February/083141.html
@ His is a lot less code, though, because it only does two rows at once instead
@  of four.
	@.type	loop_filter_h_v6, %function; loop_filter_h_v6: @ PROC
	@ r0 = unsigned char *_pix
	@ r1 = int            _ystride
	@ r2 = int            _ll
	@ preserves r0-r3
	stmfd	r13!,{r4-r11,r14}
	ldr	r12,=0x10003
	bl loop_filter_h_core_v6
	add	r0, r0, r1, LSL #2
	bl loop_filter_h_core_v6
	sub	r0, r0, r1, LSL #2
	ldmfd	r13!,{r4-r11,PC}
	@.size loop_filter_h_v6, .-loop_filter_h_v6	@ ENDP

	@.type	loop_filter_h_core_v6, %function; loop_filter_h_core_v6: @ PROC
	@ r0 = unsigned char *_pix
	@ r1 = int            _ystride
	@ r2 = int            _ll
	@ r12= 0x10003
	@ Preserves r0-r3, r12; Clobbers r4-r11.
	ldr	r4,[r0, #-2]!		@ r4 = <p3|p2|p1|p0>
	@ Single issue
	ldr	r5,[r0, r1]!		@ r5 = <q3|q2|q1|q0>
	uxtb16	r6, r4, ROR #16		@ r6 = <p0|p2>
	uxtb16	r4, r4, ROR #8		@ r4 = <p3|p1>
	uxtb16	r7, r5, ROR #16		@ r7 = <q0|q2>
	uxtb16	r5, r5, ROR #8		@ r5 = <q3|q1>
	pkhbt	r8, r4, r5, LSL #16	@ r8 = <__|q1|__|p1>
	pkhbt	r9, r6, r7, LSL #16	@ r9 = <__|q2|__|p2>
	ssub16	r6, r4, r6		@ r6 = <p3-p0|p1-p2>
	smlad	r6, r6, r12,r12		@ r6 = <????|(p3-p0)+3*(p1-p2)+3>
	ssub16	r7, r5, r7		@ r7 = <q3-q0|q1-q2>
	smlad	r7, r7, r12,r12		@ r7 = <????|(q0-q3)+3*(q2-q1)+4>
	ldr	r4,[r0, r1]!		@ r4 = <r3|r2|r1|r0>
	mov	r6, r6, ASR #3		@ r6 = <??????|(p3-p0)+3*(p1-p2)+3>>3>
	ldr	r5,[r0, r1]!		@ r5 = <s3|s2|s1|s0>
	pkhbt	r11,r6, r7, LSL #13	@ r11= <??|-R_q|??|-R_p>
	uxtb16	r6, r4, ROR #16		@ r6 = <r0|r2>
	uxtb16	r11,r11			@ r11= <__|-R_q|__|-R_p>
	uxtb16	r4, r4, ROR #8		@ r4 = <r3|r1>
	uxtb16	r7, r5, ROR #16		@ r7 = <s0|s2>
	pkhbt	r10,r6, r7, LSL #16	@ r10= <__|s2|__|r2>
	ssub16	r6, r4, r6		@ r6 = <r3-r0|r1-r2>
	uxtb16	r5, r5, ROR #8		@ r5 = <s3|s1>
	smlad	r6, r6, r12,r12		@ r6 = <????|(r3-r0)+3*(r2-r1)+3>
	ssub16	r7, r5, r7		@ r7 = <r3-r0|r1-r2>
	smlad	r7, r7, r12,r12		@ r7 = <????|(s0-s3)+3*(s2-s1)+4>
	orr	r9, r9, r10, LSL #8	@ r9 = <s2|q2|r2|p2>
	mov	r6, r6, ASR #3		@ r6 = <??????|(r0-r3)+3*(r2-r1)+4>>3>
	pkhbt	r10,r4, r5, LSL #16	@ r10= <__|s1|__|r1>
	pkhbt	r6, r6, r7, LSL #13	@ r6 = <??|-R_s|??|-R_r>
	orr	r8, r8, r10, LSL #8	@ r8 = <s1|q1|r1|p1>
	uxtb16	r6, r6			@ r6 = <__|-R_s|__|-R_r>
	mov	r10,#0
	orr	r6, r11,r6, LSL #8	@ r6 = <-R_s|-R_q|-R_r|-R_p>
	@ Single issue
	@ There's no min, max or abs instruction.
	@ ssub8 and sel will work for abs, and we can do all the rest with
	@  unsigned saturated adds, which means the GE flags are still all
	@  set when we're done computing lflim(abs(R_i),L).
	@ This allows us to both add and subtract, and split the results by
	@  the original sign of R_i.
	ssub8	r7, r10,r6
	@ Single issue
	sel	r7, r7, r6		@ r7 = abs(R_i)
	@ Single issue
	uqadd8	r4, r7, r2		@ r4 = 255-max(2*L-abs(R_i),0)
	@ Single issue
	uqadd8	r7, r7, r4
	@ Single issue
	uqsub8	r7, r7, r4		@ r7 = min(abs(R_i),max(2*L-abs(R_i),0))
	@ Single issue
	uqsub8	r4, r8, r7
	uqadd8	r5, r9, r7
	uqadd8	r8, r8, r7
	uqsub8	r9, r9, r7
	sel	r8, r8, r4		@ r8 = p1+lflim(R_i,L)
	sel	r9, r9, r5		@ r9 = p2-lflim(R_i,L)
	mov	r5, r9, LSR #24		@ r5 = s2
	strb	r5, [r0,#2]!
	mov	r4, r8, LSR #24		@ r4 = s1
	strb	r4, [r0,#-1]
	mov	r5, r9, LSR #8		@ r5 = r2
	strb	r5, [r0,-r1]!
	mov	r4, r8, LSR #8		@ r4 = r1
	strb	r4, [r0,#-1]
	mov	r5, r9, LSR #16		@ r5 = q2
	strb	r5, [r0,-r1]!
	mov	r4, r8, LSR #16		@ r4 = q1
	strb	r4, [r0,#-1]
	@ Single issue
	strb	r9, [r0,-r1]!
	@ Single issue
	strb	r8, [r0,#-1]
	mov	PC,r14
	@.size loop_filter_h_core_v6, .-loop_filter_h_core_v6	@ ENDP

@ This uses the same strategy as the MMXEXT version for x86, except that uhadd8
@  computes (a+b>>1) instead of (a+b+1>>1) like PAVGB.
@ This works just as well, with the following procedure for computing the
@  filter value, f:
@   u = ~uhadd8(p1,~p2);
@   v = uhadd8(~p1,p2);
@   m = v-u;
@   a = m^uhadd8(m^p0,m^~p3);
@   f = uhadd8(uhadd8(a,u1),v1);
@  where f = 127+R, with R in [-127,128] defined as in the spec.
@ This is exactly the same amount of arithmetic as the version that uses PAVGB
@  as the basic operator.
@ It executes about 2/3 the number of instructions of David Conrad's approach,
@  but requires more code, because it does all eight columns at once, instead
@  of four at a time.
	@.type	loop_filter_v_v6, %function; loop_filter_v_v6: @ PROC
	@ r0 = unsigned char *_pix
	@ r1 = int            _ystride
	@ r2 = int            _ll
	@ preserves r0-r11
	stmfd	r13!,{r4-r11,r14}
	ldrd	r6, [r0, -r1]!		@ r7, r6 = <p5|p1>
	ldrd	r4, [r0, -r1]		@ r5, r4 = <p4|p0>
	ldrd	r8, [r0, r1]!		@ r9, r8 = <p6|p2>
	mvn	r14,r6			@ r14= ~p1
	ldrd	r10,[r0, r1]		@ r11,r10= <p7|p3>
	@ Filter the first four columns.
	mvn	r12,r8			@ r12= ~p2
	uhadd8	r14,r14,r8		@ r14= v1=~p1+p2>>1
	uhadd8	r12,r12,r6		@ r12= p1+~p2>>1
	mvn	r10, r10		@ r10=~p3
	mvn	r12,r12			@ r12= u1=~p1+p2+1>>1
	ssub8	r14,r14,r12		@ r14= m1=v1-u1
	@ Single issue
	eor	r4, r4, r14		@ r4 = m1^p0
	eor	r10,r10,r14		@ r10= m1^~p3
	uhadd8	r4, r4, r10		@ r4 = (m1^p0)+(m1^~p3)>>1
	@ Single issue
	eor	r4, r4, r14		@ r4 = a1=m1^((m1^p0)+(m1^~p3)>>1)
	sadd8	r14,r14,r12		@ r14= v1=m1+u1
	uhadd8	r4, r4, r12		@ r4 = a1+u1>>1
	mvn	r12,r9			@ r12= ~p6
	uhadd8	r4, r4, r14		@ r4 = f1=(a1+u1>>1)+v1>>1
	@ Filter the second four columns.
	mvn	r14,r7			@ r14= ~p5
	uhadd8	r12,r12,r7		@ r12= p5+~p6>>1
	uhadd8	r14,r14,r9		@ r14= v2=~p5+p6>>1
	mvn	r12,r12			@ r12= u2=~p5+p6+1>>1
	mvn	r11,r11			@ r11=~p7
	ssub8	r10,r14,r12		@ r10= m2=v2-u2
	@ Single issue
	eor	r5, r5, r10		@ r5 = m2^p4
	eor	r11,r11,r10		@ r11= m2^~p7
	uhadd8	r5, r5, r11		@ r5 = (m2^p4)+(m2^~p7)>>1
	@ Single issue
	eor	r5, r5, r10		@ r5 = a2=m2^((m2^p4)+(m2^~p7)>>1)
	@ Single issue
	uhadd8	r5, r5, r12		@ r5 = a2+u2>>1
	ldr	r12,=0x7F7F7F7F		@ r12 = {127}x4
	uhadd8	r5, r5, r14		@ r5 = f2=(a2+u2>>1)+v2>>1
	@ Now split f[i] by sign.
	@ There's no min or max instruction.
	@ We could use ssub8 and sel, but this is just as many instructions and
	@  dual issues more (for v7 without NEON).
	uqsub8	r10,r4, r12		@ r10= R_i>0?R_i:0
	uqsub8	r4, r12,r4		@ r4 = R_i<0?-R_i:0
	uqadd8	r11,r10,r2		@ r11= 255-max(2*L-abs(R_i<0),0)
	uqadd8	r14,r4, r2		@ r14= 255-max(2*L-abs(R_i>0),0)
	uqadd8	r10,r10,r11
	uqadd8	r4, r4, r14
	uqsub8	r10,r10,r11		@ r10= min(abs(R_i<0),max(2*L-abs(R_i<0),0))
	uqsub8	r4, r4, r14		@ r4 = min(abs(R_i>0),max(2*L-abs(R_i>0),0))
	uqsub8	r11,r5, r12		@ r11= R_i>0?R_i:0
	uqadd8	r6, r6, r10
	uqsub8	r8, r8, r10
	uqsub8	r5, r12,r5		@ r5 = R_i<0?-R_i:0
	uqsub8	r6, r6, r4		@ r6 = p1+lflim(R_i,L)
	uqadd8	r8, r8, r4		@ r8 = p2-lflim(R_i,L)
	uqadd8	r10,r11,r2		@ r10= 255-max(2*L-abs(R_i<0),0)
	uqadd8	r14,r5, r2		@ r14= 255-max(2*L-abs(R_i>0),0)
	uqadd8	r11,r11,r10
	uqadd8	r5, r5, r14
	uqsub8	r11,r11,r10		@ r11= min(abs(R_i<0),max(2*L-abs(R_i<0),0))
	uqsub8	r5, r5, r14		@ r5 = min(abs(R_i>0),max(2*L-abs(R_i>0),0))
	uqadd8	r7, r7, r11
	uqsub8	r9, r9, r11
	uqsub8	r7, r7, r5		@ r7 = p5+lflim(R_i,L)
	strd	r6, [r0, -r1]		@ [p5:p1] = [r7: r6]
	uqadd8	r9, r9, r5		@ r9 = p6-lflim(R_i,L)
	strd	r8, [r0]		@ [p6:p2] = [r9: r8]
	ldmfd	r13!,{r4-r11,PC}
	@.size loop_filter_v_v6, .-loop_filter_v_v6	@ ENDP

	@.type	_oc_loop_filter_frag_rows_v6, %function; _oc_loop_filter_frag_rows_v6: @ PROC
	@ r0 = _ref_frame_data
	@ r1 = _ystride
	@ r2 = _bv
	@ r3 = _frags
	@ r4 = _fragi0
	@ r5 = _fragi0_end
	@ r6 = _fragi_top
	@ r7 = _fragi_bot
	@ r8 = _frag_buf_offs
	@ r9 = _nhfrags
	mov	r12,r13
	stmfd	r13!,{r0,r4-r11,r14}
	ldmfd	r12,{r4-r9}
	ldr	r2, [r2]	@ ll = *(int *)_bv
	cmp	r4, r5		@ if(_fragi0>=_fragi0_end)
	bge	oslffri_v6_end	@   bail
	subs	r9, r9, #1	@ r9 = _nhfrags-1	if (r9<=0)
	ble	oslffri_v6_end	@			  bail
	add	r3, r3, r4, LSL #2	@ r3 = &_frags[fragi]
	add	r8, r8, r4, LSL #2	@ r8 = &_frag_buf_offs[fragi]
	sub	r7, r7, r9	@ _fragi_bot -= _nhfrags;
oslffri_v6_lp1:
	mov	r10,r4		@ r10= fragi = _fragi0
	add	r11,r4, r9	@ r11= fragi_end-1=fragi+_nhfrags-1
oslffri_v6_lp2:
	ldr	r14,[r3], #4	@ r14= _frags[fragi]	_frags++
	ldr	r0, [r13]	@ r0 = _ref_frame_data
	ldr	r12,[r8], #4	@ r12= _frag_buf_offs[fragi]   _frag_buf_offs++
	tst	r14,#OC_FRAG_CODED_FLAG
	beq	oslffri_v6_uncoded
	cmp	r10,r4		@ if (fragi>_fragi0)
	add	r0, r0, r12	@ r0 = _ref_frame_data + _frag_buf_offs[fragi]
	blgt	loop_filter_h_v6
	cmp	r4, r6		@ if (fragi0>_fragi_top)
	blgt	loop_filter_v_v6
	cmp	r10,r11		@ if(fragi+1<fragi_end)===(fragi<fragi_end-1)
	ldrlt	r12,[r3]	@ r12 = _frags[fragi+1]
	add	r0, r0, #8
	add	r10,r10,#1	@ r10 = fragi+1;
	andlt	r12,r12,#OC_FRAG_CODED_FLAG
	cmplt	r12,#OC_FRAG_CODED_FLAG	@ && _frags[fragi+1].coded==0
	bllt	loop_filter_h_v6
	cmp	r10,r7		@ if (fragi<_fragi_bot)
	ldrlt	r12,[r3, r9, LSL #2]	@ r12 = _frags[fragi+1+_nhfrags-1]
	sub	r0, r0, #8
	add	r0, r0, r1, LSL #3
	andlt	r12,r12,#OC_FRAG_CODED_FLAG
	cmplt	r12,#OC_FRAG_CODED_FLAG
	bllt	loop_filter_v_v6
	cmp	r10,r11		@ while(fragi<=fragi_end-1)
	ble	oslffri_v6_lp2
	mov	r4, r10		@ r4 = fragi0 += nhfrags
	cmp	r4, r5
	blt	oslffri_v6_lp1
oslffri_v6_end:
	ldmfd	r13!,{r0,r4-r11,PC}
oslffri_v6_uncoded:
	add	r10,r10,#1
	cmp	r10,r11
	ble	oslffri_v6_lp2
	mov	r4, r10		@ r4 = fragi0 += nhfrags
	cmp	r4, r5
	blt	oslffri_v6_lp1
	ldmfd	r13!,{r0,r4-r11,PC}
	@.size _oc_loop_filter_frag_rows_v6, .-_oc_loop_filter_frag_rows_v6	@ ENDP
  .endif

  .if OC_ARM_ASM_NEON
	.globl	_oc_loop_filter_init_neon
	.globl	_oc_loop_filter_frag_rows_neon

	@.type	_oc_loop_filter_init_neon, %function; 
_oc_loop_filter_init_neon: @ PROC
	@ r0 = _bv
	@ r1 = _flimit (=L from the spec)
	mov		r1, r1, LSL #1  @ r1 = 2*L
	vdup.S16	Q15, r1		@ Q15= 2L in U16s
	vst1.64		{D30,D31}, [r0,:128]
	mov	PC,r14
	@.size _oc_loop_filter_init_neon, .-_oc_loop_filter_init_neon	@ ENDP

	@.type	loop_filter_h_neon, %function; 
loop_filter_h_neon: @ PROC
	@ r0 = unsigned char *_pix
	@ r1 = int            _ystride
	@ r2 = int           *_bv
	@ preserves r0-r3
	@ We assume Q15= 2*L in U16s
	@                    My best guesses at cycle counts (and latency)--vvv
	sub	r12,r0, #2
	@ Doing a 2-element structure load saves doing two vtrn's below, at the
	@  cost of using two more slower single-lane loads vs. the faster
	@  all-lane loads.
	@ It's less code this way, though, and benches a hair faster, but it
	@  leaves D2 and D4 swapped.
	vld2.16	{D0[],D2[]},  [r12], r1		@ D0 = ____________1100     2,1
						@ D2 = ____________3322
	vld2.16	{D4[],D6[]},  [r12], r1		@ D4 = ____________5544     2,1
						@ D6 = ____________7766
	vld2.16	{D0[1],D2[1]},[r12], r1		@ D0 = ________99881100     3,1
						@ D2 = ________BBAA3322
	vld2.16	{D4[1],D6[1]},[r12], r1		@ D4 = ________DDCC5544     3,1
						@ D6 = ________FFEE7766
	vld2.16	{D0[2],D2[2]},[r12], r1		@ D0 = ____GGHH99881100     3,1
						@ D2 = ____JJIIBBAA3322
	vld2.16	{D4[2],D6[2]},[r12], r1		@ D4 = ____KKLLDDCC5544     3,1
						@ D6 = ____NNMMFFEE7766
	vld2.16	{D0[3],D2[3]},[r12], r1		@ D0 = PPOOGGHH99881100     3,1
						@ D2 = RRQQJJIIBBAA3322
	vld2.16	{D4[3],D6[3]},[r12], r1		@ D4 = TTSSKKLLDDCC5544     3,1
						@ D6 = VVUUNNMMFFEE7766
	vtrn.8	D0, D4	@ D0 = SSOOKKGGCC884400 D4 = TTPPLLHHDD995511       1,1
	vtrn.8	D2, D6	@ D2 = UUQQMMIIEEAA6622 D6 = VVRRNNJJFFBB7733       1,1
	vsubl.U8	Q0, D0, D6	@ Q0 = 00 - 33 in S16s              1,3
	vsubl.U8	Q8, D2, D4	@ Q8 = 22 - 11 in S16s              1,3
	add	r12,r0, #8
	vadd.S16	Q0, Q0, Q8	@                                   1,3
	pld	[r12]
	vadd.S16	Q0, Q0, Q8	@                                   1,3
	pld	[r12,r1]
	vadd.S16	Q0, Q0, Q8	@ Q0 = [0-3]+3*[2-1]                1,3
	pld	[r12,r1, LSL #1]
	vrshr.S16	Q0, Q0, #3	@ Q0 = f = ([0-3]+3*[2-1]+4)>>3     1,4
	add	r12,r12,r1, LSL #2
	@  We want to do
	@ f =             CLAMP(MIN(-2L-f,0), f, MAX(2L-f,0))
	@   = ((f >= 0) ? MIN( f ,MAX(2L- f ,0)) : MAX(  f , MIN(-2L- f ,0)))
	@   = ((f >= 0) ? MIN(|f|,MAX(2L-|f|,0)) : MAX(-|f|, MIN(-2L+|f|,0)))
	@   = ((f >= 0) ? MIN(|f|,MAX(2L-|f|,0)) :-MIN( |f|,-MIN(-2L+|f|,0)))
	@   = ((f >= 0) ? MIN(|f|,MAX(2L-|f|,0)) :-MIN( |f|, MAX( 2L-|f|,0)))
	@ So we've reduced the left and right hand terms to be the same, except
	@ for a negation.
	@ Stall x3
	vabs.S16	Q9, Q0		@ Q9 = |f| in U16s                  1,4
	pld	[r12,-r1]
	vshr.S16	Q0, Q0, #15	@ Q0 = -1 or 0 according to sign    1,3
	pld	[r12]
	vqsub.U16	Q10,Q15,Q9	@ Q10= MAX(2L-|f|,0) in U16s        1,4
	pld	[r12,r1]
	vmovl.U8	Q1, D2	   @ Q2 = __UU__QQ__MM__II__EE__AA__66__22  2,3
	pld	[r12,r1,LSL #1]
	vmin.U16	Q9, Q10,Q9	@ Q9 = MIN(|f|,MAX(2L-|f|))         1,4
	add	r12,r12,r1, LSL #2
	@ Now we need to correct for the sign of f.
	@ For negative elements of Q0, we want to subtract the appropriate
	@ element of Q9. For positive elements we want to add them. No NEON
	@ instruction exists to do this, so we need to negate the negative
	@ elements, and we can then just add them. a-b = a-(1+!b) = a-1+!b
	vadd.S16	Q9, Q9, Q0	@				    1,3
	pld	[r12,-r1]
	veor.S16	Q9, Q9, Q0	@ Q9 = real value of f              1,3
	@ Bah. No VRSBW.U8
	@ Stall (just 1 as Q9 not needed to second pipeline stage. I think.)
	vaddw.U8	Q2, Q9, D4 @ Q1 = xxTTxxPPxxLLxxHHxxDDxx99xx55xx11  1,3
	vsub.S16	Q1, Q1, Q9 @ Q2 = xxUUxxQQxxMMxxIIxxEExxAAxx66xx22  1,3
	vqmovun.S16	D4, Q2		@ D4 = TTPPLLHHDD995511		    1,1
	vqmovun.S16	D2, Q1		@ D2 = UUQQMMIIEEAA6622		    1,1
	sub	r12,r0, #1
	vtrn.8	D4, D2		@ D4 = QQPPIIHHAA992211	D2 = MMLLEEDD6655   1,1
	vst1.16	{D4[0]}, [r12], r1
	vst1.16	{D2[0]}, [r12], r1
	vst1.16	{D4[1]}, [r12], r1
	vst1.16	{D2[1]}, [r12], r1
	vst1.16	{D4[2]}, [r12], r1
	vst1.16	{D2[2]}, [r12], r1
	vst1.16	{D4[3]}, [r12], r1
	vst1.16	{D2[3]}, [r12], r1
	mov	PC,r14
	@.size loop_filter_h_neon, .-loop_filter_h_neon	@ ENDP

	@.type	loop_filter_v_neon, %function; 
loop_filter_v_neon: @ PROC
	@ r0 = unsigned char *_pix
	@ r1 = int            _ystride
	@ r2 = int           *_bv
	@ preserves r0-r3
	@ We assume Q15= 2*L in U16s
	@                    My best guesses at cycle counts (and latency)--vvv
	sub	r12,r0, r1, LSL #1
	vld1.64	{D0}, [r12,:64], r1		@ D0 = SSOOKKGGCC884400     2,1
	vld1.64	{D2}, [r12,:64], r1		@ D2 = TTPPLLHHDD995511     2,1
	vld1.64	{D4}, [r12,:64], r1		@ D4 = UUQQMMIIEEAA6622     2,1
	vld1.64	{D6}, [r12,:64]			@ D6 = VVRRNNJJFFBB7733     2,1
	vsubl.U8	Q8, D4, D2	@ Q8 = 22 - 11 in S16s              1,3
	vsubl.U8	Q0, D0, D6	@ Q0 = 00 - 33 in S16s              1,3
	add	r12, #8
	vadd.S16	Q0, Q0, Q8	@                                   1,3
	pld	[r12]
	vadd.S16	Q0, Q0, Q8	@                                   1,3
	pld	[r12,r1]
	vadd.S16	Q0, Q0, Q8	@ Q0 = [0-3]+3*[2-1]                1,3
	sub	r12, r0, r1
	vrshr.S16	Q0, Q0, #3	@ Q0 = f = ([0-3]+3*[2-1]+4)>>3     1,4
	@  We want to do
	@ f =             CLAMP(MIN(-2L-f,0), f, MAX(2L-f,0))
	@   = ((f >= 0) ? MIN( f ,MAX(2L- f ,0)) : MAX(  f , MIN(-2L- f ,0)))
	@   = ((f >= 0) ? MIN(|f|,MAX(2L-|f|,0)) : MAX(-|f|, MIN(-2L+|f|,0)))
	@   = ((f >= 0) ? MIN(|f|,MAX(2L-|f|,0)) :-MIN( |f|,-MIN(-2L+|f|,0)))
	@   = ((f >= 0) ? MIN(|f|,MAX(2L-|f|,0)) :-MIN( |f|, MAX( 2L-|f|,0)))
	@ So we've reduced the left and right hand terms to be the same, except
	@ for a negation.
	@ Stall x3
	vabs.S16	Q9, Q0		@ Q9 = |f| in U16s                  1,4
	vshr.S16	Q0, Q0, #15	@ Q0 = -1 or 0 according to sign    1,3
	@ Stall x2
	vqsub.U16	Q10,Q15,Q9	@ Q10= MAX(2L-|f|,0) in U16s        1,4
	vmovl.U8	Q2, D4	   @ Q2 = __UU__QQ__MM__II__EE__AA__66__22  2,3
	@ Stall x2
	vmin.U16	Q9, Q10,Q9	@ Q9 = MIN(|f|,MAX(2L-|f|))         1,4
	@ Now we need to correct for the sign of f.
	@ For negative elements of Q0, we want to subtract the appropriate
	@ element of Q9. For positive elements we want to add them. No NEON
	@ instruction exists to do this, so we need to negate the negative
	@ elements, and we can then just add them. a-b = a-(1+!b) = a-1+!b
	@ Stall x3
	vadd.S16	Q9, Q9, Q0	@				    1,3
	@ Stall x2
	veor.S16	Q9, Q9, Q0	@ Q9 = real value of f              1,3
	@ Bah. No VRSBW.U8
	@ Stall (just 1 as Q9 not needed to second pipeline stage. I think.)
	vaddw.U8	Q1, Q9, D2 @ Q1 = xxTTxxPPxxLLxxHHxxDDxx99xx55xx11  1,3
	vsub.S16	Q2, Q2, Q9 @ Q2 = xxUUxxQQxxMMxxIIxxEExxAAxx66xx22  1,3
	vqmovun.S16	D2, Q1		@ D2 = TTPPLLHHDD995511		    1,1
	vqmovun.S16	D4, Q2		@ D4 = UUQQMMIIEEAA6622		    1,1
	vst1.64	{D2}, [r12,:64], r1
	vst1.64	{D4}, [r12,:64], r1
	mov	PC,r14
	@.size loop_filter_v_neon, .-loop_filter_v_neon	@ ENDP

	@.type	_oc_loop_filter_frag_rows_neon, %function;
_oc_loop_filter_frag_rows_neon: @ PROC
	@ r0 = _ref_frame_data
	@ r1 = _ystride
	@ r2 = _bv
	@ r3 = _frags
	@ r4 = _fragi0
	@ r5 = _fragi0_end
	@ r6 = _fragi_top
	@ r7 = _fragi_bot
	@ r8 = _frag_buf_offs
	@ r9 = _nhfrags
	mov	r12,r13
	stmfd	r13!,{r0,r4-r11,r14}
	ldmfd	r12,{r4-r9}
	cmp	r4, r5		@ if(_fragi0>=_fragi0_end)
	bge	oslffri_neon_end @   bail
	subs	r9, r9, #1	@ r9 = _nhfrags-1	if (r9<=0)
	ble	oslffri_neon_end	@		  bail
	vld1.64	{D30,D31}, [r2,:128]	@ Q15= 2L in U16s
	add	r3, r3, r4, LSL #2	@ r3 = &_frags[fragi]
	add	r8, r8, r4, LSL #2	@ r8 = &_frag_buf_offs[fragi]
	sub	r7, r7, r9	@ _fragi_bot -= _nhfrags;
oslffri_neon_lp1:
	mov	r10,r4		@ r10= fragi = _fragi0
	add	r11,r4, r9	@ r11= fragi_end-1=fragi+_nhfrags-1
oslffri_neon_lp2:
	ldr	r14,[r3], #4	@ r14= _frags[fragi]	_frags++
	ldr	r0, [r13]	@ r0 = _ref_frame_data
	ldr	r12,[r8], #4	@ r12= _frag_buf_offs[fragi]   _frag_buf_offs++
	tst	r14,#OC_FRAG_CODED_FLAG
	beq	oslffri_neon_uncoded
	cmp	r10,r4		@ if (fragi>_fragi0)
	add	r0, r0, r12	@ r0 = _ref_frame_data + _frag_buf_offs[fragi]
	blgt	loop_filter_h_neon
	cmp	r4, r6		@ if (_fragi0>_fragi_top)
	blgt	loop_filter_v_neon
	cmp	r10,r11		@ if(fragi+1<fragi_end)===(fragi<fragi_end-1)
	ldrlt	r12,[r3]	@ r12 = _frags[fragi+1]
	add	r0, r0, #8
	add	r10,r10,#1	@ r10 = fragi+1;
	andlt	r12,r12,#OC_FRAG_CODED_FLAG
	cmplt	r12,#OC_FRAG_CODED_FLAG	@ && _frags[fragi+1].coded==0
	bllt	loop_filter_h_neon
	cmp	r10,r7		@ if (fragi<_fragi_bot)
	ldrlt	r12,[r3, r9, LSL #2]	@ r12 = _frags[fragi+1+_nhfrags-1]
	sub	r0, r0, #8
	add	r0, r0, r1, LSL #3
	andlt	r12,r12,#OC_FRAG_CODED_FLAG
	cmplt	r12,#OC_FRAG_CODED_FLAG
	bllt	loop_filter_v_neon
	cmp	r10,r11		@ while(fragi<=fragi_end-1)
	ble	oslffri_neon_lp2
	mov	r4, r10		@ r4 = _fragi0 += _nhfrags
	cmp	r4, r5
	blt	oslffri_neon_lp1
oslffri_neon_end:
	ldmfd	r13!,{r0,r4-r11,PC}
oslffri_neon_uncoded:
	add	r10,r10,#1
	cmp	r10,r11
	ble	oslffri_neon_lp2
	mov	r4, r10		@ r4 = _fragi0 += _nhfrags
	cmp	r4, r5
	blt	oslffri_neon_lp1
	ldmfd	r13!,{r0,r4-r11,PC}
	@.size _oc_loop_filter_frag_rows_neon, .-_oc_loop_filter_frag_rows_neon	@ ENDP
  .endif

	@ END

#endif
