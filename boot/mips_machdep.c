#include <stdio.h>
#include <mips/types.h>

/*for toolchain mips-elf-gcc mips3 use 32 fpu regs*/
void tgt_fpuenable()
{
#if __mips < 3
asm(\
"mfc0 $2,$12;\n" \
"li   $3,0x30000000 #ST0_CU1;\n" \
"or   $2,$3;\n" \
"mtc0 $2,$12;\n" \
"li $2,0x00000000 #FPU_DEFAULT;\n" \
"ctc1 $2,$31;\n" \
:::"$2","$3"
	);
#else
asm(\
"mfc0 $2,$12;\n" \
"li   $3,0x34000000 #ST0_CU1;\n" \
"or   $2,$3;\n" \
"mtc0 $2,$12;\n" \
"li $2,0x00000000 #FPU_DEFAULT;\n" \
"ctc1 $2,$31;\n" \
:::"$2","$3"
	);
#endif
}
