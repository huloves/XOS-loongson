#include <ls2k/regdef.h>

	.set	noreorder
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:
	.globl	stack
stack = start - 0x4000		/* Place PMON stack below PMON start in RAM */
	/*set all spi cs to 1, default input*/
	li v0,0xbfff0225
	li v1,0xff
	sb v1,(v0)
