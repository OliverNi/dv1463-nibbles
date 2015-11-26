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
.set 	EMPTY_CHAR, 32

.data
snake:	
		.space 	300 #Something wrong with this.
tail: 	
		.long 	0
snake_size:	
		.long	1
head:	
		.long 	0
###
### Code
###
.text

	
### void start_game(int no_iter)
.globl	start_game
.type start_game,@function
start_game:
	call	nib_init
	movl	$4, (head)
	movl	$0, (tail)
	movl	$5, (snake_size)
	leal	snake, %edx
	xorl 	%ebx, %ebx
	movl	$12, %eax
	movl	%eax, (%edx, %ebx, 8)
	movl	$24, %eax
	movl	%eax, 4(%edx, %ebx, 8)
	incl	%ebx
	movl	$13, %eax
	movl	%eax, (%edx, %ebx, 8)
	movl	$24, %eax
	movl	%eax, 4(%edx, %ebx, 8)
	incl	%ebx
	movl	$14, %eax
	movl	%eax, (%edx, %ebx, 8)
	movl	$24, %eax
	movl	%eax, 4(%edx, %ebx, 8)
	incl	%ebx
	movl	$15, %eax
	movl	%eax, (%edx, %ebx, 8)
	movl	$24, %eax
	movl	%eax, 4(%edx, %ebx, 8)
	incl	%ebx
	movl	$16, %eax
	movl	%eax, (%edx, %ebx, 8)
	movl	$24, %eax
	movl	%eax, 4(%edx, %ebx, 8)
	#Spawn worm in the middle
	call	draw_map
game_loop:
	#call	nib_init
	call	move_snake
	pushl	$1
	call	sleep
	addl	$4, %esp
	
	pushl	$1
	call	sleep
	addl	$4, %esp
	call	draw_snake
	pushl	$1
	call	sleep
	addl	$4, %esp
	call 	clear_board
	
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

clear_board:

#	movl	$25, %eax
#	movl	$50, %ebx
##
#	oloop:
#	iloop:
#	pushl 	$EMPTY_CHAR
#	pushl 	%eax
#	pushl 	%ebx
#	call	nib_put_scr
#	addl	$12, %esp
#	decl	%ebx
#	jge		iloop
#	movl	$50, %ebx
#	decl	%eax
#	jge		oloop
#	ret

	xorl	%ebx, %ebx
	xorl	%ecx, %ecx

	oloop:
		cmpl	$MAX_X, %ebx
		je 		done
		incl	%ebx
	iloop:
		cmpl	$MAX_Y, %ecx
		je 		reset_iloop
		incl	%ecx

		pushl 	$EMPTY_CHAR
		pushl 	%ebx
		pushl 	%ecx
		call	nib_put_scr
		addl	$12, %esp

		jmp		iloop
	reset_iloop:
		xorl	%ecx, %ecx
		jmp 	oloop
	done:

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
	movl	tail, %eax
	l3:
	movl	$50, %ecx
	call	mod
	movl	%eax, %ebx
	leal	(snake), %edx

	movl	(%edx, %ebx, 8), %eax	#x-value of snake
	cmpl	$0, %eax
	je 		draw_snake_end #Found empty spot in array -> end draw

	movl	4(%edx, %ebx, 8), %ecx #y-value of snake

	pushl	$SNAKE_CHAR
	pushl 	%eax
	pushl 	%ecx

	call	nib_put_scr
	addl	$12, %esp

	#inc counter
	incl	%ebx
	movl	%ebx, %eax
	jmp		l3
	draw_snake_end:
	ret

move_snake:
	leal	(snake), %edx
	

	#######Move forward - add head#########
	movl	head, %eax
	movl	(%edx, %eax, 8), %ecx #store x-value of current head in %ecx
	pushl	%ecx
	movl	4(%edx, %eax, 8), %ecx #store y-value of current head in %eax
	pushl	%ecx


	incl	%eax
	movl	$50, %ecx
	call	mod
	movl	%eax, head
	#index = eax
	popl	%ecx
	#Now we can manipulate %ecx to move in y-axis
	
	leal	(snake), %edx
	movl	%ecx, 4(%edx, %eax, 8)
	popl	%ecx
	#Now we can manipulate %ecx to move in x-axis
	incl	%ecx
	movl	%ecx, (%edx, %eax, 8)


	########REMOVE TAIL############
	movl	tail, %eax
	leal	(snake), %edx
	movl	$0, (%edx, %eax, 8)
	movl	$0, 4(%edx, %eax, 8)

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
	movl	%edx, %eax	# return val
	ret
