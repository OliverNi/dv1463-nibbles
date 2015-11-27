### Constants
###
.set	MAX_Y,	14
.set	MAX_X, 14
.set	BORDER_CHAR, 43
.set	MID_X, 7
.set	MID_Y, 7
.set	SNAKE_CHAR, 111
.set	APPLE_CHAR, 64
.set	KD, 258
.set	KU, 259
.set	KL, 260
.set	KR, 261
.set 	EMPTY_CHAR, 32
.set 	MAX_ARR, 50

.section .data
apple: 			.space 	8
snake:			.space 	400 #error when end of the array is reached
tail: 			.long 	0
snake_size:		.long	0
head:			.long	0
direction:		.long	258 #DOWN default value
apples_eaten: 	.long 	0
max_apples: 	.long 	1
start_len: 		.long 	1
###
### Code
###
.text

	
.globl	start_game
.type start_game,@function
start_game:
	movl 	4(%esp), %eax
	movl 	%eax, start_len
	movl 	8(%esp), %ecx
	movl 	%ecx, max_apples
	pushl	%ebp
	movl	%esp, %ebp
	subl	$1024, %esp
	call	nib_init
	movl	$-1, head
	movl	$0, tail
	movl	$1, snake_size
	call	draw_map
	
#Spawn worm in the middle (one head at a time)
init_worm:
	#Calculate position for first head
	xorl 	%edx, %edx
	movl 	$2, %ebx
	movl  	start_len, %eax
	divl 	%ebx
	movl 	$MID_X, %ecx	
	subl 	%eax, %ecx
	xorl 	%ebx, %ebx
	pushl 	%ecx
#add the next head
worm_loop:
	movl 	head, %ecx
	incl	%ecx	#let head point to the next offset in the array
	movl 	%ecx, head
	leal 	snake, %edx
	movl 	$MID_X, %eax
	movl	%eax, 4(%edx, %ebx, 8)
	popl 	%ecx
	movl	%ecx, (%edx, %ebx, 8)
	incl	%ecx	#increase position coord
	pushl 	%ecx
	call 	draw_head
	incl 	%ebx
	cmpl 	start_len, %ebx 	#start_len, loop counter
	jne 	worm_loop

	call 	spawn_apple
	
game_loop:
	call 	check_input
	call	move_snake
	call 	draw_apple
	pushl	$500000
	call	usleep
	addl	$4, %esp
	jmp 	game_loop
losers_lounge:
winners_lounge:
	pushl	$2
	call	sleep
	addl	$4, %esp
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
	movl 	apples_eaten, %eax

	cmpl 	max_apples, %eax
	je		winners_lounge

	incl 	%eax
	movl 	%eax, apples_eaten

	leal 	apple, %ebx
	pushl	$MAX_Y
	call 	rpoint
	addl	$4, %esp
	movl 	%eax, (%ebx) #set x-coord
	pushl 	$MAX_X
	call 	rpoint
	addl	$4, %esp
	movl 	%eax, 4(%ebx) #set y-coord

ret

draw_apple:
	leal 	apple, %edx
	pushl 	$APPLE_CHAR
	pushl 	(%edx)
	pushl 	4(%edx)
	call 	nib_put_scr
	addl 	$12, %esp

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
	leal	snake, %edx
	

	#######Move forward - add head#########
	#Get values from current head
	movl	head, %eax
	movl	(%edx, %eax, 8), %ecx #store x-value of current head
	pushl	%ecx
	movl	4(%edx, %eax, 8), %ecx #store y-value of current head 
	pushl	%ecx
	
	popl	%ebx	#pop y-coord of the old head
	popl 	%ecx	#x-coord
	cmpl	$KU, direction	#if keyboard input was UP
	jnz		move_down
move_up:
	decl	%ecx
	jmp		end_move
move_down:
	cmpl	$KD, direction	#if keyboard input was DOWN
	jnz		xcoord
	incl	%ecx
	jmp		end_move
xcoord:
	cmpl	$KR, direction	#if keyboard input was RIGHT
	jnz		move_left
move_right:
	incl	%ebx
	jmp		end_move
move_left:
	decl	%ebx
end_move:
	pushl 	%ebx
	pushl 	%ecx

check_apple_coll:
	#IF APPLE EATEN -> DON'T REMOVE TAIL
	#Check collision with apple
	movl	head, %eax
	leal	snake, %edx
	leal	apple, %eax
	cmpl 	%ecx, (%eax)
	jnz 	remove_tail
	cmpl 	%ebx, 4(%eax)
	jnz 	remove_tail
	call 	spawn_apple
	movl 	snake_size, %ebx
	cmpl	$MAX_ARR, %ebx
	je		remove_tail 	#don't grow if max size is reached
	movl 	snake_size, %ebx
	incl	%ebx
	movl 	%ebx, snake_size
	jmp 	set_new_head
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

set_new_head:
	
	#Calculate index of the new head
	movl 	head, %eax
	incl	%eax

	movl	$MAX_ARR, %ecx
	call	mod
	movl	%eax, head
	leal	(snake), %edx
	#pop coords
	popl 	%ecx
	popl 	%ebx
	movl	%ecx, (%edx, %eax, 8)
	movl	%ebx, 4(%edx, %eax, 8)
check_wall_coll:
	cmpl 	$0, %ecx
	je 		losers_lounge
	cmpl	$MAX_X, %ecx
	je 		losers_lounge
	cmpl	$0, %ebx
	je 		losers_lounge
	cmpl	$MAX_Y, %ebx
	je 		losers_lounge
check_worm_coll:
	movl 	tail, %eax
	pushl 	%ebx
	movl 	head, %ebx
	cmpl 	%ebx, %eax
	popl	%ebx
	je 		draw_head
worm_coll_loop:
	#edx = snake
	cmpl 	(%edx, %eax, 8), %ecx
	jne 	no_coll_worm
	cmpl 	4(%edx, %eax, 8), %ebx
	je 		losers_lounge
no_coll_worm:
	incl 	%eax 
	pushl 	%ebx
	movl 	head, %ebx
	cmpl 	%ebx, %eax
	popl 	%ebx
	jne 	worm_coll_loop
draw_head:
	#Draw head
	movl 	head, %eax
	leal	snake, %edx
	pushl 	$SNAKE_CHAR
	pushl 	(%edx, %eax, 8)
	pushl 	4(%edx, %eax, 8)
	call	nib_put_scr
	addl	$12, %esp
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

