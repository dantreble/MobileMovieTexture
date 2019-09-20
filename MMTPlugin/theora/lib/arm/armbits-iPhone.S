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
@
@ function:
@   last mod: $Id: armbits.s 17481 2010-10-03 22:49:42Z tterribe $
@
@********************************************************************


    .text

    .align 2

	.globl _oc_pack_read_arm
	.globl _oc_pack_read1_arm
	.globl _oc_huff_token_decode_arm

	@.type	_oc_pack_read1_arm, %function; 
_oc_pack_read1_arm: @ PROC
	@ r0 = oc_pack_buf *_b
	add r12,r0,#8
	ldmia r12,{r2,r3}      @ r2 = window
	@ Stall...             ; r3 = available
	@ Stall...
	subs r3,r3,#1          @ r3 = available-1, available<1 => LT
	blt oc_pack_read1_refill
	mov r0,r2,LSR #31      @ r0 = window>>31
	mov r2,r2,LSL #1       @ r2 = window<<=1
	stmia r12,{r2,r3}      @ window = r2
	                       @ available = r3
	mov PC,r14
	@.size _oc_pack_read1_arm, .-_oc_pack_read1_arm	@ ENDP

	@.type	_oc_pack_read_arm, %function; 
_oc_pack_read_arm: @ PROC
	@ r0 = oc_pack_buf *_b
	@ r1 = int          _bits
	add r12,r0,#8
	ldmia r12,{r2,r3}      @ r2 = window
	@ Stall...             ; r3 = available
	@ Stall...
	subs r3,r3,r1          @ r3 = available-_bits, available<_bits => LT
	blt oc_pack_read_refill
	rsb r0,r1,#32          @ r0 = 32-_bits
	mov r0,r2,LSR r0       @ r0 = window>>32-_bits
	mov r2,r2,LSL r1       @ r2 = window<<=_bits
	stmia r12,{r2,r3}      @ window = r2
	                       @ available = r3
	mov PC,r14

@ We need to refill window.
oc_pack_read1_refill:
	mov r1,#1
oc_pack_read_refill:
	stmfd r13!,{r10,r11,r14}
	ldmia r0,{r10,r11}     @ r10 = stop
	                       @ r11 = ptr
	rsb r0,r1,#32          @ r0 = 32-_bits
	rsb r3,r3,r0           @ r3 = 32-available
@ We can use unsigned compares for both the pointers and for available
@  (allowing us to chain condition codes) because available will never be
@  larger than 32 (or we wouldn't be here), and thus 32-available will never be
@  negative.
	cmp r10,r11            @ ptr<stop => HI
	cmphi r3,#7            @   available<=24 => HI
	ldrbhi r14,[r11],#1    @     r14 = *ptr++
	subhi r3,#8            @     available += 8
	@ (HI) Stall...
	orrhi r2,r14,LSL r3    @     r2 = window|=r14<<32-available
	cmphi r10,r11          @     ptr<stop => HI
	cmphi r3,#7            @       available<=24 => HI
	ldrbhi r14,[r11],#1    @         r14 = *ptr++
	subhi r3,#8            @         available += 8
	@ (HI) Stall...
	orrhi r2,r14,LSL r3    @         r2 = window|=r14<<32-available
	cmphi r10,r11          @         ptr<stop => HI
	cmphi r3,#7            @           available<=24 => HI
	ldrbhi r14,[r11],#1    @             r14 = *ptr++
	subhi r3,#8            @             available += 8
	@ (HI) Stall...
	orrhi r2,r14,LSL r3    @             r2 = window|=r14<<32-available
	cmphi r10,r11          @             ptr<stop => HI
	cmphi r3,#7            @               available<=24 => HI
	ldrbhi r14,[r11],#1    @                 r14 = *ptr++
	subhi r3,#8            @                 available += 8
	@ (HI) Stall...
	orrhi r2,r14,LSL r3    @                 r2 = window|=r14<<32-available
	subs r3,r0,r3          @ r3 = available-=_bits, available<bits => GT
	blt oc_pack_read_refill_last
	mov r0,r2,LSR r0       @ r0 = window>>32-_bits
	mov r2,r2,LSL r1       @ r2 = window<<=_bits
	str r11,[r12,#-4]      @ ptr = r11
	stmia r12,{r2,r3}      @ window = r2
	                       @ available = r3
	ldmfd r13!,{r10,r11,PC}

@ Either we wanted to read more than 24 bits and didnt have enough room to
@  stuff the last byte into the window, or we hit the end of the packet.
oc_pack_read_refill_last:
	cmp r11,r10            @ ptr<stop => LO
@ If we didnt hit the end of the packet, then pull enough of the next byte to
@  to fill up the window.
	ldrblo r14,[r11]       @ (LO) r14 = *ptr
@ Otherwise, set the EOF flag and pretend we have lots of available bits.
	movhs r14,#1           @ (HS) r14 = 1
	addlo r10,r3,r1        @ (LO) r10 = available
	strhs r14,[r12,#8]     @ (HS) eof = 1
	andlo r10,r10,#7       @ (LO) r10 = available0x7
	movhs r3,#1<<30        @ (HS) available = OC_LOTS_OF_BITS
	orrlo r2,r14,LSL r10   @ (LO) r2 = window|=*ptr>>(available0x7)
	mov r0,r2,LSR r0       @ r0 = window>>32-_bits
	mov r2,r2,LSL r1       @ r2 = window<<=_bits
	str r11,[r12,#-4]      @ ptr = r11
	stmia r12,{r2,r3}      @ window = r2
	                       @ available = r3
	ldmfd r13!,{r10,r11,PC}
	@.size _oc_pack_read_arm, .-_oc_pack_read_arm	@ ENDP



	@.type	_oc_huff_token_decode_arm, %function; 
_oc_huff_token_decode_arm: @ PROC
	@ r0 = oc_pack_buf       *_b
	@ r1 = const ogg_int16_t *_tree
	stmfd r13!,{r4,r5,r10,r14}
	ldrsh r10,[r1]         @ r10 = n=_tree[0]
	ldmia r0,{r2-r5}       @ r2 = stop
	@ Stall...             ; r3 = ptr
	@ Stall...             ; r4 = window
	                       @ r5 = available
	cmp r10,r5             @ n>available => GT
	bgt oc_huff_token_decode_refill0
	rsb r14,r10,#32        @ r14 = 32-n
	mov r14,r4,LSR r14     @ r14 = bits=window>>32-n
	add r14,r1,r14,LSL #1  @ r14 = _tree+bits
	ldrsh r12,[r14,#2]     @ r12 = node=_tree[1+bits]
	@ Stall...
	@ Stall...
	rsbs r14,r12,#0        @ r14 = -node, node>0 => MI
	bmi oc_huff_token_decode_continue
	mov r10,r14,LSR #8     @ r10 = n=node>>8
	mov r4,r4,LSL r10      @ r4 = window<<=n
	sub r5,r10             @ r5 = available-=n
	stmib r0,{r3-r5}       @ ptr = r3
	                       @ window = r4
	                       @ available = r5
	and r0,r14,#255        @ r0 = node0x255
	ldmfd r13!,{r4,r5,r10,pc}

@ The first tree node wasnt enough to reach a leaf, read another
oc_huff_token_decode_continue:
	add r12,r1,r12,LSL #1  @ r12 = _tree+node
	mov r4,r4,LSL r10      @ r4 = window<<=n
	sub r5,r5,r10          @ r5 = available-=n
	ldrsh r10,[r12],#2     @ r10 = n=_tree[node]
	@ Stall...             ; r12 = _tree+node+1
	@ Stall...
	cmp r10,r5             @ n>available => GT
	bgt oc_huff_token_decode_refill
	rsb r14,r10,#32        @ r14 = 32-n
	mov r14,r4,LSR r14     @ r14 = bits=window>>32-n
	add r12,r12,r14        @
	ldrsh r12,[r12,r14]    @ r12 = node=_tree[node+1+bits]
	@ Stall...
	@ Stall...
	rsbs r14,r12,#0        @ r14 = -node, node>0 => MI
	bmi oc_huff_token_decode_continue
	mov r10,r14,LSR #8     @ r10 = n=node>>8
	mov r4,r4,LSL r10      @ r4 = window<<=n
	sub r5,r10             @ r5 = available-=n
	stmib r0,{r3-r5}       @ ptr = r3
	                       @ window = r4
	                       @ available = r5
	and r0,r14,#255        @ r0 = node0x255
	ldmfd r13!,{r4,r5,r10,pc}

oc_huff_token_decode_refill0:
	add r12,r1,#2          @ r12 = _tree+1
oc_huff_token_decode_refill:
@ We cant possibly need more than 15 bits, so available must be <= 15.
@ Therefore we can load at least two bytes without checking it.
	cmp r2,r3              @ ptr<stop => HI
	ldrbhi r14,[r3],#1     @   r14 = *ptr++
	rsbhi r5,r5,#24        @ (HI) available = 32-(available+=8)
	rsbls r5,r5,#32        @ (LS) r5 = 32-available
	orrhi r4,r14,LSL r5    @   r4 = window|=r14<<32-available
	cmphi r2,r3            @   ptr<stop => HI
	ldrbhi r14,[r3],#1     @     r14 = *ptr++
	subhi r5,#8            @     available += 8
	@ (HI) Stall...
	orrhi r4,r14,LSL r5    @     r4 = window|=r14<<32-available
@ We can use unsigned compares for both the pointers and for available
@  (allowing us to chain condition codes) because available will never be
@  larger than 32 (or we wouldnt be here), and thus 32-available will never be
@  negative.
	cmphi r2,r3            @     ptr<stop => HI
	cmphi r5,#7            @       available<=24 => HI
	ldrbhi r14,[r3],#1     @         r14 = *ptr++
	subhi r5,#8            @         available += 8
	@ (HI) Stall...
	orrhi r4,r14,LSL r5    @         r4 = window|=r14<<32-available
	cmp r2,r3              @ ptr<stop => HI
	movls r5,#-1<<30       @ (LS) available = OC_LOTS_OF_BITS+32
	cmphi r5,#7            @ (HI) available<=24 => HI
	ldrbhi r14,[r3],#1     @ (HI)   r14 = *ptr++
	subhi r5,#8            @ (HI)   available += 8
	@ (HI) Stall...
	orrhi r4,r14,LSL r5    @ (HI)   r4 = window|=r14<<32-available
	rsb r14,r10,#32        @ r14 = 32-n
	mov r14,r4,LSR r14     @ r14 = bits=window>>32-n
	add r12,r12,r14        @
	ldrsh r12,[r12,r14]    @ r12 = node=_tree[node+1+bits]
	rsb r5,r5,#32          @ r5 = available
	@ Stall...
	rsbs r14,r12,#0        @ r14 = -node, node>0 => MI
	bmi oc_huff_token_decode_continue
	mov r10,r14,LSR #8     @ r10 = n=node>>8
	mov r4,r4,LSL r10      @ r4 = window<<=n
	sub r5,r10             @ r5 = available-=n
	stmib r0,{r3-r5}       @ ptr = r3
	                       @ window = r4
	                       @ available = r5
	and r0,r14,#255        @ r0 = node0x255
	ldmfd r13!,{r4,r5,r10,pc}
	@.size _oc_huff_token_decode_arm, .-_oc_huff_token_decode_arm	@ ENDP

	@ END

    #endif
