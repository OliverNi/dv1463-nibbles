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
.set	MAX_ITER,	5
	
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
	movl	4(%esp), %ecx	# no of iterations
	cmpl	$MAX_ITER, %ecx	# just a check...
	jle	ok
	ret
ok:	
	xorl	%eax, %eax	# set the result register to zero
oloop:	movl	4(%esp), %ebx	# start outer loop, init the no iter in iloop
iloop:	incl	%eax		# start inner loop, increment the result
	decl	%ebx
	jnz	iloop		# end of inner loop
	loop	oloop		# end of outer loop
	movl	%eax, result	# store the result
	call	nib_end
	ret
