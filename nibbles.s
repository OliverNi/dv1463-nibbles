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
.set	WALL_COUNT,	50
.set	ROOF_COUNT, 50
.set	BORDER_CHAR, 43
	
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

### A small test program with nested loops, performs
### for (i=no_iter; i>0; i--)
###     for (j=no_iter; j>0; j--)
###         result++; 
	
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
	xorl	%ecx, %ecx
	xorl	%ebx, %ebx

	l1: 
	pushl	%ecx
	pushl	%ebx
	pushl	BORDER_CHAR
	call	nib_put_scr
	addl	$12, %esp
	cmpl	WALL_COUNT, %ebx
	incl	%ebx
	jnz		l1
	addl	ROOF_COUNT, %ecx
	cmpl	%ecx, ROOF_COUNT
	jnz		l1
ret

draw_roof:
	l2:

ret
