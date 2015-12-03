### Constants
###
.set	MAX_Y,	32
.set	MAX_X, 32
.set	BORDER_CHAR, 43
.set	MID_X, 16
.set	MID_Y, 16
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
	movl 	4(%esp), %eax	#Get the len parameter
	movl 	%eax, start_len
	movl 	8(%esp), %ecx	#Get the apples parameter
	decl	%ecx		#-1 so it works better in loops (offset starts at 0)			####THIS IS DUMB#####
	movl 	%ecx, max_apples
	pushl	%ebp			#Prologue
	movl	%esp, %ebp
	subl	$1024, %esp		#Allocate memory
	call	nib_init
	call	draw_map		#Draw borders for the game-board.
	
#Spawn worm in the middle (one head at a time)
init_worm:
	#Calculate position for first head
	xorl 	%edx, %edx			#%edx = 0 (preparation for div)
	movl 	$2, %ebx			
	movl  	start_len, %eax		#Divide len
	divl 	%ebx				#Divide len with two to make sure that the middle-part of the worm starts in the middle.
	movl 	$MID_Y, %ecx		#Get the middle-position
	subl 	%eax, %ecx			#Get the startposition for the tail
	xorl 	%ebx, %ebx			#ebx = 0
	pushl 	%ecx				#Push middle-position
#add the next head
worm_loop:
	movl 	head, %ecx			#ecx = offset for head
	incl	%ecx				#let head point to the next offset in the array
	movl 	%ecx, head 			#
	leal 	snake, %edx 		#Get the address for snake
	movl 	$MID_X, %eax 		
	movl	%eax, 4(%edx, %ebx, 8)	#Put node in the middle (x-axis)
	popl 	%ecx
	movl	%ecx, (%edx, %ebx, 8) 	#Set y-coordinate
	incl	%ecx					#increase y-position coord
	pushl 	%ecx					#Push y-coord for the next node	
	call 	draw_head				#Draw the node
	incl 	%ebx					#Increment loop counter (and index-position)

	#increase snake_size
	movl 	snake_size, %ecx		
	incl	%ecx
	movl 	%ecx, snake_size

	cmpl 	start_len, %ebx 	#if (index != start_len)
	jne 	worm_loop 			#next iteration (Put next node of snake)

init_apples:
	movl 	max_apples, %ebx 	#ebx = amount of apples on the screen at the same time.
init_apples_loop:				
	pushl 	%ebx 				#Push index in apple-array as parameter
	call 	spawn_apple 		#Put a new apple on the screen
	addl	$4, %esp			#Clean the stack

	decl	%ebx				#Decrement loop counter (index in apple-array)
	jge		init_apples_loop	#Next iteration if ebx > 0

	
game_loop:
	call 	check_input			#Get the direction of the snake
	call	move_snake			#Move the snake and check collisions
	call 	draw_apples 		#Draw the apples (This is polled because there is a problem when an apple is spawned on the snake)
	pushl	$200000				
	call	usleep				#Add some delay to the game loop to prevent the snake from moving to fast.
	addl	$4, %esp
	jmp 	game_loop
losers_lounge:					#If this is reached the player has lost the player has lost the game
	pushl	$2 		
	call	sleep 				#Sleep for two seconds then end the game
	addl	$4, %esp
	call	nib_end
	leave
	ret
check_input: 					#Check for player's keyboard input
	call 	nib_poll_kbd
	cmpl	$-1, %eax			#If nib_poll_kbd returned -1 there was no input, don't change the direction.
	je 		do_nothing
	movl 	direction, %ecx 	#ecx = direction
	#Check legality of moves 
x_axis_l:		
	cmpl 	$KL, %ecx 			#if current direction is LEFT and the new direction is RIGHT, don't change the direction
	jne 	x_axis_r
	cmpl 	$KR, %eax
	je 		do_nothing
x_axis_r:
	cmpl	$KR, %ecx			#if current direction is RIGHT and the new direction is LEFT, don't change the direction
	jne 	y_axis_u
	cmpl	$KL, %eax
	je 		do_nothing
y_axis_u:
	cmpl 	$KU, %ecx 			#if current direction is UP and the new direction is DOWN, don't change the direction
	jne 	y_axis_d
	cmpl	$KD, %eax
	je 		do_nothing
y_axis_d:
	cmpl 	$KD, %ecx   		#if current direction is DOWN and the new direction is UP, don't change the direction
	jne 	change_direction
	cmpl	$KU, %eax
	je 		do_nothing
change_direction:
	movl 	%eax, direction 	#Put the new direction in the direction-variable
do_nothing:
ret
# void spawn_apple(int offset)
# offset: The offset in the array where the appleshould be stored
spawn_apple:
	pushl 	%ebx					#Save ebx so we can reset it later (calling convention)
	movl 	8(%esp), %ebx			#Get the parameter (index where the spawned apple should be stored)
	
	#Get a random y-coord for the new apple
	pushl	$MAX_Y					#Push parameter (mod-value)
	call 	rpoint
	addl	$4, %esp				#Clean the stack
	leal 	apple, %edx				#edx = address of apple-array
	movl 	%eax, (%edx, %ebx, 8) 	#set y-coord

	#Get a random x-coord for the new apple
	pushl 	$MAX_X
	call 	rpoint
	addl	$4, %esp
	leal 	apple, %edx
	movl 	%eax, 4(%edx, %ebx, 8) #set x-coord

	popl 	%ebx					#Restore ebx (calling convention)
	ret

draw_apples:
	pushl	%ebx					#Save ebx (calling convention)
	movl 	max_apples, %ebx		#Initiate loop counter with max-index of apple-array
draw_apples_loop:					#Loop through all indices of the apple-array and draw them on the screen
	leal 	apple, %edx				#edx = addr of apple-array

	pushl 	$APPLE_CHAR				#Push parameters
	pushl 	(%edx, %ebx, 8)
	pushl 	4(%edx, %ebx, 8)
	call 	nib_put_scr 			#Draw an apple at its correct coordinates 
	addl 	$12, %esp				#Clean the stack

	decl	%ebx					#Decrement counter (index)
	jge 	draw_apples_loop		#if ebx > 0 continue to next iteration

	popl 	%ebx					#Restore ebx (calling convention)
	ret

draw_map:
	call 	draw_walls 				#Draw the outer walls (y-axis borders)
	call 	draw_roof				#Draw roof and floor (x-axis borders)
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
	
	###Calculate values for the new head###
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
	call 	spawn_apple #spawn a new apple (index of apple was pushed earlier)
	addl 	$4, %esp

	movl 	snake_size, %ecx
	movl 	$MAX_ARR, %eax

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
	movl 	head, %ebx
	movl 	%ebx, %eax

	#If tail and head are the same we should skip this collision check.
	cmpl 	tail, %ebx
	je 		draw_head
worm_coll_loop:
	decl 	%ebx
	#Check if ebx goes out of bound - if so start from the last slot in the array
	cmpl 	$-1, %ebx
	jne 	worm_coll_cmpcoords
	movl 	$MAX_ARR-1, %ebx
worm_coll_cmpcoords:
	#Check if x-coord of head is the same as index ebx node
	movl 	(%edx, %eax, 8), %ecx
	cmpl 	(%edx, %ebx, 8), %ecx
	jne 	worm_coll_loop_f 

	#Check if y-coord of head is the same as index ebx node
	movl 	4(%edx, %eax, 8), %ecx
	cmpl 	4(%edx, %ebx, 8), %ecx
	je 		losers_lounge
worm_coll_loop_f:
	cmpl 	tail, %ebx
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

