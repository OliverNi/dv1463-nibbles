/*********************************************************************
 *
 * Copyright (C) 2010,  Blekinge Institute of Technology
 *
 * Filename:      loops.s
 * Author:        Håkan Grahn <hgr@bth.se>
 * Description:   Example with nested loops, assembly
 *
 ********************************************************************/
###
### Constants
###
.set	MAX_Y,	25
.set	MAX_X, 50
.set	BORDER_CHAR, 43
.set	MID_X, 24
.set	MID_Y, 12
.set	SNAKE_CHAR, 111
.set	APPLE_CHAR, 64
.set	KD, 258
.set	KU, 259
.set	KL, 260
.set	KR, 261
	
###
### Global variables
###
.bss
.align 4
result:	.word	0

.data
	
###
### Code
###
.text

	
### void start_game(int no_iter)
.globl	start_game
.type start_game,@function
start_game:
	call	nib_init
	#Spawn worm in the middle
game_loop:
	call	draw_map
	jmp 	game_loop
	#check apple collision
	#-set flag
	#check wall collision
	#-end game
	#poll keyboard input
	#move worm
	#Go to game_loop

	call	nib_end
	ret

draw_map:
	call 	draw_walls
	call 	draw_roof
ret

draw_walls:
	xorl	%edx, %edx	
	xorl	%ebx, %ebx #counter

	l1: 
	pushl	$BORDER_CHAR # Push character
	pushl	%ebx		 # Push y
	pushl	$0		 # Push x
	call	nib_put_scr
	addl	$12, %esp
	pushl	$BORDER_CHAR # Push character
	pushl	%ebx		 # Push y
	pushl	$MAX_X		 # Push x
	call	nib_put_scr
	addl	$12, %esp
	incl	%ebx
	cmpb	$MAX_Y, %ebx
	jle		l1
	ret

draw_roof:
	xorl	%edx, %edx	
	xorl	%ebx, %ebx #counter

	l2: 
	pushl	$BORDER_CHAR # Push character
	pushl	$0		 # Push y
	pushl	%ebx		 # Push x
	call	nib_put_scr
	addl	$12, %esp
	pushl	$BORDER_CHAR # Push character
	pushl	$MAX_Y		 # Push y
	pushl	%ebx	 # Push x
	call	nib_put_scr
	addl	$12, %esp
	incl	%ebx
	cmpb	$MAX_X, %ebx
	jle		l2

	ret
