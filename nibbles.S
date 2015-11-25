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
.set	MID_X, 12
.set	MID_Y, 24
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
snake:	.space 	300 #Something wrong with this.
snake_size:	.word	1
tail: 	.word 	0
head:	.word 	0
###
### Code
###
.text

	
### void start_game(int no_iter)
.globl	start_game
.type start_game,@function
start_game:
	call	nib_init
	movl	$0, (head)
	movl	$0, (tail)
	movl	$1, snake_size
	leal	snake, %edx
	xorl 	%ebx, %ebx
	movl	$MID_X, %eax
	movl	%eax, (%edx, %ebx, 8)
	movl	$MID_X, %eax
	movl	%eax, 4(%edx, %ebx, 8)
	movl	$-1, 8(%edx, %ebx, 8)
	addl	$4, %ebx
	movl	$-1, 12(%edx, %ebx, 8)

	#Spawn worm in the middle
game_loop:
	call	move_snake
	call	draw_snake
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
	cmpl	$MAX_Y, %ebx
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
	cmpl	$MAX_X, %ebx
	jle		l2

	ret

draw_snake:
	xorl	%edx, %edx	
	xorl	%ebx, %ebx #counter

	l3:
	leal	(snake), %edx
	#Get x- and y-values
	movl	(%edx, %ebx, 8), %eax
	cmpl	$0, %eax
	je 		next_node

	movl	4(%edx, %ebx, 8), %ecx

	pushl	$SNAKE_CHAR
	pushl 	%eax
	pushl 	%ecx

	call	nib_put_scr
	addl	$12, %esp

	#inc counter
	next_node:
	addl	$8, %ebx

	cmpl	$588, %ebx
	jle		l3

	ret

move_snake:
	leal	(snake), %edx
	

	#######Move forward - add head#########
	movl	head, %eax
	movl	(%edx, %eax, 8), %ecx #store x-value of current head in %eax
	pushl	%ecx
	movl	4(%edx, %eax, 8), %ecx #store y-value of current head in %eax
	pushl	%ecx

	#Create new node in snake (Replace with function to find the next available space in the array)
	#Store off-set of new node in %ecx

	incl	%eax
	movl	$50, %ecx
	call	mod
	movl	%eax, head
	#index = eax
	popl	%ecx
	#Now we can manipulate %ecx to move in y-axis
	incl	%ecx
	movl	%ecx, 4(%edx, %eax, 8)
	popl	%ecx
	#Now we can manipulate %ecx to move in x-axis
	movl	%ecx, (%edx, %eax, 8)


	########REMOVE TAIL############
	movl	tail, %eax
	movl	$0, (%edx, %eax, 8)
	movl	$0, (%edx, %eax, 8)

	incl	%eax
	movl	$50, %ecx
	call	mod
	movl	%eax, tail

	ret


mod:
	xorl	%edx, %edx # edx = 0 (reserve 32 bit for rest)
	divl	%ecx	# random/(max-1) (%eax/%ecx)
	# %eax = kvot
	# %edx = rest
	addl	$1, %edx	# %edx + 1
	movl	%edx, %eax	# return val
	ret
