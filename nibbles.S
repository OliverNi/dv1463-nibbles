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
.set 	MAX_ARR, 6

.section .data
apple: 		.space 	8
snake:		.space 	64 #error when end of the array is reached
tail: 		.long 	0
snake_size:	.long	0
head:		.long	0
direction:	.long	258 #DOWN default value
###
### Code
###
.text

	
### void start_game(int no_iter)
.globl	start_game
.type start_game,@function
start_game:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$1024, %esp
	call	nib_init
	movb	$0, head
	movb	$0, tail
	movb	$1, snake_size
	leal	snake, %edx
	xorl 	%ebx, %ebx
	#Spawn worm in the middle
	movl	$MID_X, (%edx, %ebx, 8)
	movl	$MID_Y, 4(%edx, %ebx, 8)
	
	call	draw_map #K, A, B
	call 	spawn_apple
game_loop:
	call 	check_input
	call	move_snake #D
	#call	draw_snake #C
	pushl	$1
	call	sleep
	addl	$4, %esp
	jmp 	game_loop
	call	nib_end
	leave
	ret
check_input:
	call 	nib_poll_kbd
	cmpl	$-1, %eax
	je 		do_nothing
	movl 	%eax, direction
do_nothing:
ret
spawn_apple:
	pushl 	%ebx
	leal 	apple, %ebx
	pushl 	$APPLE_CHAR
	pushl	$MAX_Y
	call 	rpoint
	addl	$4, %esp
	movl 	%eax, (%ebx) #set x-coord
	pushl 	%eax
	pushl 	$MAX_X
	call 	rpoint
	addl	$4, %esp
	movl 	%eax, 4(%ebx) #set y-coord
	pushl	%eax
	call	nib_put_scr
	addl	$12, %esp
	popl	%ebx
ret

draw_map:
	call 	draw_walls
	pushl	$1
	call	sleep
	addl	$4, %esp
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

move_snake:
	leal	(snake), %edx
	

	#######Move forward - add head#########
	#Get values from current head
	movl	head, %eax
	movl	(%edx, %eax, 8), %ecx #store x-value of current head
	pushl	%ecx
	movl	4(%edx, %eax, 8), %ecx #store y-value of current head 
	pushl	%ecx

	#Calculate index of the new head
	incl	%eax
	movl	$MAX_ARR, %ecx
	call	mod
	movl	%eax, head
	
	leal	(snake), %edx
	
	popl	%ebx	#pop y-coord of the old head
	popl 	%ecx	#x-coord
	cmpl	$KU, direction	#if keyboard input was UP
	jnz		move_down
move_up:
	decl	%ecx
	jmp		set_xy
move_down:
	cmpl	$KD, direction	#if keyboard input was DOWN
	jnz		xcoord
	incl	%ecx
	jmp		set_xy
xcoord:
	cmpl	$KR, direction	#if keyboard input was RIGHT
	jnz		move_left
move_right:
	incl	%ebx
	jmp		set_xy
move_left:
	decl	%ebx
set_xy:

	movl	%ecx, (%edx, %eax, 8)
	movl	%ebx, 4(%edx, %eax, 8)

draw_head:
	#Draw head
	pushl 	$SNAKE_CHAR
	pushl 	(%edx, %eax, 8)
	pushl 	4(%edx, %eax, 8)
	call	nib_put_scr
	addl	$12, %esp


	#IF APPLE EATEN -> DON'T REMOVE TAIL
	#Check collision with apple
	movl	head, %eax
	leal	(snake), %edx
	leal	apple, %ebx
	movl 	(%ebx), %ecx
	cmpl 	%ecx, (%edx, %eax, 8)
	jnz 	remove_tail
	movl 	4(%ebx), %ecx
	cmpl 	%ecx, 4(%edx, %eax, 8)
	jnz 	remove_tail
	call 	spawn_apple
	movl 	$snake_size, %ebx
	incl	%ebx
	movl 	%ebx, snake_size
	cmpl	$MAX_ARR, %ebx
	jl 		remove_tail 	#don't grow if max size is reached
	jmp 	end_move

remove_tail:
	########REMOVE TAIL############
	movl	tail, %eax
	leal	(snake), %edx

	#Remove graphic
	pushl 	$EMPTY_CHAR
	pushl 	(%edx, %eax, 8)
	pushl 	4(%edx, %eax, 8)
	call	nib_put_scr
	addl	$12, %esp

	#Would be better if we could grab this from the stack but nothing's working.
	movl	tail, %eax	
	leal	(snake), %edx

	#Reset values in array
	movl	$0, (%edx, %eax, 8)
	movl	$0, 4(%edx, %eax, 8)

	#Calculate new tail (offset in array)
	incl	%eax
	movl	$MAX_ARR, %ecx
	call	mod
	movl	%eax, tail
	end_move:
	ret
#int mod(int i, int mod_val) params stored int %eax and %ecx
# returns i mod mod_val
# result is returned in %eax
mod:
	xorl	%edx, %edx # edx = 0 (reserve 32 bit for rest)
	divl	%ecx	# random/(max-1) (%eax/%ecx)
	# %eax = kvot
	# %edx = rest
	movl	%edx, %eax	# return val
	ret

# int rpoint(int max) { return rand() % (max - 1) + 1; }
# returns random value between 1 and max - 1
# result is returned in %eax
rpoint:
	call	rand			# eax = random value
	movl    4(%esp), %edx		# edx = max
	leal	-1(%edx), %ecx		# ecx = max - 1
	xorl	%edx, %edx 		# edx = 0 (reserve 32 bit for rest)
	divl	%ecx			# random/(max-1) (%eax/%ecx)
					# %eax = kvot
					# %edx = rest
	addl	$1, %edx		# %edx + 1
	movl	%edx, %eax		# return val
	ret

