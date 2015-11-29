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
.set 	MAX_ARR,	50

.section .data
apple: 			.space 	200
snake:			.space 	400
tail: 			.long 	0
snake_size:		.long	0
head:			.long	-1
direction:		.long	258 #DOWN default value
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
	decl	%ecx		#-1 so it works better in loops (offset starts at 0)
	movl 	%ecx, max_apples
	pushl	%ebp
	movl	%esp, %ebp
	subl	$1024, %esp
	call	nib_init
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

	#increase size
	movl 	snake_size, %ecx
	incl	%ecx
	movl 	%ecx, snake_size

	cmpl 	start_len, %ebx 	#start_len, loop counter
	jne 	worm_loop

init_apples:
	movl 	max_apples, %ebx
	#decl	%ebx
init_apples_loop:
	pushl 	%ebx
	call 	spawn_apple
	addl	$4, %esp

	decl	%ebx
	jge		init_apples_loop	

	
game_loop:
	call 	check_input
	call	move_snake
	call 	draw_apples
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
	movl 	direction, %ecx
x_axis_l:
	cmpl 	$KL, %ecx
	jne 	x_axis_r
	cmpl 	$KR, %eax
	je 		do_nothing
x_axis_r:
	cmpl	$KR, %ecx
	jne 	y_axis_u
	cmpl	$KL, %eax
	je 		do_nothing
y_axis_u:
	cmpl 	$KU, %ecx
	jne 	y_axis_d
	cmpl	$KD, %eax
	je 		do_nothing
y_axis_d:
	cmpl 	$KD, %ecx
	jne 	change_direction
	cmpl	$KU, %eax
	je 		do_nothing
change_direction:
	movl 	%eax, direction
do_nothing:
ret
# void spawn_apple(int offset)
# offset: The offset in the array where the appleshould be stored
spawn_apple:
	pushl 	%ebx
	movl 	8(%esp), %ebx
	
	pushl	$MAX_Y
	call 	rpoint
	addl	$4, %esp
	leal 	apple, %edx
	movl 	%eax, (%edx, %ebx, 8) #set x-coord

	pushl 	$MAX_X
	call 	rpoint
	addl	$4, %esp
	leal 	apple, %edx
	movl 	%eax, 4(%edx, %ebx, 8) #set y-coord

	popl 	%ebx
	ret

draw_apples:
	pushl	%ebx
	movl 	max_apples, %ebx
	#decl 	%ebx
draw_apples_loop:
	leal 	apple, %edx

	pushl 	$APPLE_CHAR
	pushl 	(%edx, %ebx, 8)
	pushl 	4(%edx, %ebx, 8)
	call 	nib_put_scr
	addl 	$12, %esp

	decl	%ebx
	jge 	draw_apples_loop

	popl 	%ebx
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
	movl 	max_apples, %edx
apple_coll_loop:
	leal	apple, %eax
	cmpl 	%ecx, (%eax, %edx, 8)
	jnz 	apple_coll_loop_f
	cmpl 	%ebx, 4(%eax, %edx, 8)
	jnz 	apple_coll_loop_f

apple_coll:
	pushl 	%edx #save index of the apple
remove_apple:
	pushl 	$EMPTY_CHAR
	pushl 	4(%eax, %edx, 8)
	pushl 	(%eax, %edx, 8)
	call 	nib_put_scr
	addl 	$12, %esp

	call 	spawn_apple #spawn a new apple (index of apple was pushed earlier)
	addl 	$4, %esp

	movl 	snake_size, %ecx
	movl 	$MAX_ARR, %eax
	decl	%eax

	cmpl	%eax, %ecx
	je 		remove_tail 	#don't grow if max size is reached

	#Avoid removing the tail to simulate growth
	#increase size
	movl 	snake_size, %ecx
	incl	%ecx
	movl 	%ecx, snake_size
	jmp 	set_new_head

apple_coll_loop_f:
	decl 	%edx
	jge	 	apple_coll_loop	

no_apple_coll:
	#Remove tail to simulate movement
remove_tail:
	########REMOVE TAIL############
	movl	tail, %ebx
	leal	(snake), %edx

	#Remove graphic
	pushl 	$EMPTY_CHAR
	pushl 	(%edx, %ebx, 8)
	pushl 	4(%edx, %ebx, 8)
	call	nib_put_scr
	addl	$12, %esp

	#Calculate new tail (offset in array)
	incl	%ebx
	cmpl 	$MAX_ARR, %ebx
	jne 	set_tail
	xorl 	%ebx, %ebx 		#if the end of the array is reached it should start from the beggining i.e offset 0
set_tail:
	movl 	%ebx, tail

set_new_head:
	#Calculate index of the new head
	movl 	head, %eax
	incl	%eax
	cmpl 	$MAX_ARR, %eax
	jne 	set_head
	xorl 	%eax, %eax 		#if the end of the array is reached it should start from the beggining i.e offset 0
set_head:
	movl 	%eax, head

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
	movl 	snake_size, %ebx
worm_coll_loop:
	decl 	%ebx
	jz 		draw_head
	#edx = snake
	pushl 	%eax				#THIS IS BULLSHIT BUT I RAN OUT OF REGISTERS AND I*M TOO TIRED TO THINK
	movl 	head, %eax
	movl 	(%edx, %eax, 8), %ecx
	popl 	%eax
	cmpl 	(%edx, %eax, 8), %ecx
	jne 	worm_coll_loop_f

	pushl 	%eax				#THIS IS BULLSHIT BUT I RAN OUT OF REGISTERS AND I*M TOO TIRED TO THINK
	movl 	head, %eax
	movl 	4(%edx, %eax, 8), %ecx
	popl 	%eax
	cmpl 	4(%edx, %eax, 8), %ecx
	je 		losers_lounge
worm_coll_loop_f:
	incl 	%eax
	jmp 	worm_coll_loop

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

