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
	movl 	direction, %ecx 	#ecx = old direction
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
	xorl	%ebx, %ebx 		#counter
	pushl	$BORDER_CHAR 	# Push character	#Push the BORDER_CHAR since it will be used in all nib_put_scr calls.
	l1: 
	#draw first wall
	pushl	%ebx		 	# Push y
	pushl	$0				# Push x
	call	nib_put_scr
	addl	$8, %esp		#Clean stack
	#Draw roof
	pushl	$0		 		# Push y
	pushl	%ebx		 	# Push x
	call	nib_put_scr	
	addl	$8, %esp		#Clean stack
	#Draw second wall
	pushl	%ebx		 	# Push y
	pushl	$MAX_X		 	# Push x
	call	nib_put_scr
	addl	$8, %esp		#Clean stack
	#Draw floor
	pushl	$MAX_Y		 	# Push y
	pushl	%ebx	 		# Push x
	call	nib_put_scr
	addl	$8, %esp		#Clean stack
	incl	%ebx			#Increment counter
	cmpl	$MAX_Y, %ebx	#Next iteration if counter <= MAX_Y
	jle		l1
	addl 	$4, %esp		#Remove BORDER_CHAR from the stack
	ret

move_snake:
	leal	snake, %edx						#edx = addr of snake

	#######Move forward - add head#########
	#Get values from current head
	movl	head, %eax						#eax = head
	movl	(%edx, %eax, 8), %ecx 			#store y-value of current head
	movl	4(%edx, %eax, 8), %ebx 			#store x-value of current head 
	
	###Calculate values for the new head###
	cmpl	$KU, direction					#if keyboard input was UP -> move_up
	jnz		move_down
move_up:
	decl	%ecx							#decrement y-coordinate
	jmp		end_move						#The x-coordinate remain the same so we can end move.
move_down:
	cmpl	$KD, direction					#if keyboard input was DOWN
	jnz		xcoord
	incl	%ecx							#increment y-coordinate
	jmp		end_move						#The x-coordinate remain the same so we can end move.
xcoord:
	cmpl	$KR, direction					#if keyboard input was RIGHT -> move_right
	jnz		move_left
move_right:
	incl	%ebx							#increment x-coordinate
	jmp		end_move
move_left:
	decl	%ebx							#decrement x-coordinate
end_move:
	pushl 	%ebx							#Push x-coordinate
	pushl 	%ecx							#Push y-coordinate

check_apple_coll:
	#IF APPLE EATEN -> DON'T REMOVE TAIL
	#Check collision with apple
	movl 	max_apples, %edx				#Use edx as counter, start at the last index in apple-array
apple_coll_loop:
	leal	apple, %eax						#eax = addr of apple-array
	cmpl 	%ecx, (%eax, %edx, 8)			#if y-coordinate of snake-head == y-coordinate of apple att index edx &&
	jnz 	apple_coll_loop_f
	cmpl 	%ebx, 4(%eax, %edx, 8) 			#x-coordinate of snake-head == x-coordinate of apple at index edx -> There was a collition
	jnz 	apple_coll_loop_f

apple_coll:
	pushl 	%edx 							#Push parameter (index in apple-array)
remove_apple:
	call 	spawn_apple 					#spawn a new apple (index of apple was pushed earlier)
	addl 	$4, %esp						#Clean stack

	movl 	snake_size, %ecx 				#ecx = snake_size
	movl 	$MAX_ARR, %eax 					#eax = MAX_ARR

	cmpl	%eax, %ecx
	je 		remove_tail 					#don't grow if max size is reached

	#Avoid removing the tail to simulate growth
	#increase size
	movl 	snake_size, %ecx
	incl	%ecx
	movl 	%ecx, snake_size
	jmp 	set_new_head					#Skip remove_tail and move directly to set_new_head

apple_coll_loop_f:
	decl 	%edx							#decrement counter and check the next index in the array if counter >= 0
	jge	 	apple_coll_loop	

no_apple_coll:
	#Remove tail to simulate movement
remove_tail:
	########REMOVE TAIL############
	movl	tail, %ebx						#ebx = tail
	leal	(snake), %edx					#edx = snake

	#Remove graphic from screen
	pushl 	$EMPTY_CHAR						
	pushl 	(%edx, %ebx, 8)
	pushl 	4(%edx, %ebx, 8)
	call	nib_put_scr
	addl	$12, %esp

	#Calculate new tail (offset in array)
	incl	%ebx
	cmpl 	$MAX_ARR, %ebx		#if the end of the array is reached
	jne 	set_tail
	xorl 	%ebx, %ebx 		 	#it should start from the beggining i.e offset 0
set_tail:
	movl 	%ebx, tail 			#tail = the new index

set_new_head:
	#Calculate index of the new head
	movl 	head, %eax 			#eax = head
	incl	%eax				#increment head to get the index for the new head
	cmpl 	$MAX_ARR, %eax		#if the end of the array is reached
	jne 	set_head
	xorl 	%eax, %eax 		 	#it should start from the beggining i.e offset 0
set_head:
	movl 	%eax, head 			#head = the new index

	leal	(snake), %edx		#edx = snake
	#pop coords
	popl 	%ecx					#pop y-coord of the new head
	popl 	%ebx					#pop x-coord of the new head
	movl	%ecx, (%edx, %eax, 8)	#Set the y-coord for the new head
	movl	%ebx, 4(%edx, %eax, 8)	#Set the x-coord for the new head

check_wall_coll:					#Check for collisions with the walls
	cmpl 	$0, %ecx				#if y-coord ==  0
	je 		losers_lounge			#it has hit the roof
	cmpl	$MAX_Y, %ecx			#if y-coord == MAX_Y
	je 		losers_lounge			#it has hit the floor
	cmpl	$0, %ebx				#if x-coord == 0
	je 		losers_lounge			#It has hit the left wall
	cmpl	$MAX_X, %ebx			#if x-coord == MAX_X
	je 		losers_lounge			#it has hit the right wall

check_worm_coll:
	movl 	head, %ebx				#ebx = head
	movl 	%ebx, %eax				

	#If tail and head are the same we should skip this collision check.
	cmpl 	tail, %ebx
	je 		draw_head
worm_coll_loop:
	decl 	%ebx			#Decrease counter (index)
	#Check if ebx goes out of bound - if so start from the last slot in the array
	cmpl 	$-1, %ebx		#If counter == -1, 
	jne 	worm_coll_cmpcoords
	movl 	$MAX_ARR-1, %ebx #set it to the last index in the array
worm_coll_cmpcoords:
	#Check if x-coord of head is the same as index ebx node
	movl 	(%edx, %eax, 8), %ecx
	cmpl 	(%edx, %ebx, 8), %ecx	#Compare head's y-coord with the current node at this index
	jne 	worm_coll_loop_f 

	#Check if y-coord of head is the same as index ebx node
	movl 	4(%edx, %eax, 8), %ecx
	cmpl 	4(%edx, %ebx, 8), %ecx 	#Compare head's x-coord with the current node at this index
	je 		losers_lounge			#collision detected - the player should lose the game.
worm_coll_loop_f:
	cmpl 	tail, %ebx				#if counter == tail, the loop is done (the last index has been checked)
	jne 	worm_coll_loop

draw_head:
	#Draw the head on the screen.
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

