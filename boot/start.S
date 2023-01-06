#include <ls2k/regdef.h>
#include <ls2k/bonito.h>
#include <mips/asm.h>
#include <mips/cpu.h>

#define TTYDEBUG
#ifdef TTYDEBUG
#define	TTYDBG(x) \
	.rdata;98: .asciz x; .text; la a0, 98b; bal stringserial; nop
#else
#define TTYDBG(x)
#endif
#define HAVE_TARGET_GETCHAR
#define	PRINTSTR(x) \
	.rdata;98: .asciz x; .text; la a0, 98b; bal stringserial; nop

#define CONFIG_CACHE_64K_4WAY 1 

#define tmpsize		s1
#define msize		s2
#define sdShape		s3
#define bonito		s4
#define dbg		s5
#define sdCfg		s6

/*
 * Coprocessor 0 register names
 */
#define CP0_INDEX $0
#define CP0_RANDOM $1
#define CP0_ENTRYLO0 $2
#define CP0_ENTRYLO1 $3
#define CP0_CONF $3
#define CP0_CONTEXT $4
#define CP0_PAGEMASK $5
#define CP0_WIRED $6
#define CP0_INFO $7
#define CP0_BADVADDR $8
#define CP0_COUNT $9
#define CP0_ENTRYHI $10
#define CP0_COMPARE $11
#define CP0_STATUS $12
#define CP0_CAUSE $13
#define CP0_EPC $14
#define CP0_PRID $15
#define CP0_CONFIG $16
#define CP0_LLADDR $17
#define CP0_WATCHLO $18
#define CP0_WATCHHI $19
#define CP0_XCONTEXT $20
#define CP0_FRAMEMASK $21
#define CP0_DIAGNOSTIC $22
#define CP0_PERFORMANCE $25
#define CP0_ECC $26
#define CP0_CACHEERR $27
#define CP0_TAGLO $28
#define CP0_TAGHI $29
#define CP0_ERROREPC $30

#define CP0_DEBUG  $23
#define CP0_DEPC   $24
#define CP0_DESAVE $31

#ifdef ACPI_S3_MODE

#define S3_REG_SAVE_AREA        0xffffffffa00f0000
#define GEN_RTC_1_REG        	0xffffffffbfef0050
#define PM1_CNT                 0xffffffffbfef0014
#define INTIEN0                 0xbfd00044
#define INTIEN1                 0xbfd0005c
#define INTIEN2                 0xbfd00074
#define INTIEN3                 0xbfd0008c
#define INTIEN4                 0xbfd000a4

#endif




/*
 *   Register usage:
 *
 *	s0	link versus load offset, used to relocate absolute adresses.
 *	s1	free
 *	s2	memory size.
 *	s3	sdShape.
 *	s4	Bonito base address.
 *	s5	dbg.
 *	s6	sdCfg.
 *	s7	rasave.
 *	s8	L3 Cache size.
 */


#ifdef BOOT_FROM_NAND

#define Index_Store_Tag_D			0x09
#define Index_Store_Tag_S			0x0B 
#define Index_Store_Tag_I                       0x08        


#define CONFREG_BASE 0xbfd00000
#define APB_BASE 0xbfe80000
#define NAND_BASE 0x60000
#define NAND_DMA_OFFSET 0x40
#define REMAP_REG 0xbfd80088
//#define REMAP_REG 0x1fd80088
#define REMAP_DDR 0x00e000f0 //0x80e00000 
#define REMAP_DDR_DMA 0x00e00000 //0x80e00000 

#endif
#ifndef PCIE_LANE_FLIP
#define PCIE_LANE_FLIP 0x300 /*pcie1 port0 rx, tx lane revert*/
#endif

	.set	noreorder
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:
	.globl	stack
	/* 设置栈指针为start地址之前的0x4000 */
stack = start - 0x4000		/* Place PMON stack below PMON start in RAM */
	/*set all spi cs to 1, default input*/
	/* 设置spi配置寄存器 0xbfff0225 = 0x1fff0220 + 0xa0000000 + 5，所以是片选寄存器*/
	/* 将spi配置空间中的片选寄存器设置为0xff */
	li v0,0xbfff0225
	li v1,0xff
	sb v1,(v0)

#if 1 //fix the hardware poweroff error.

	bal	ls2k_version
	nop
	bnez	v0,2f
	nop

	.set    mips32
	mfc0    t0, $15, 1      #EBASE
	.set    mips3
	andi    t0, t0, 0x3ff
	bnez    t0, 2f
	nop

	lui	t0, 0xba00
	lui	t1, 0x1fe0
	sw	t1, 0x1010(t0) /* config bar for APB */
	lw	t2, 0x1004(t0)
	ori	t2, t2, 0x2
	sw	t2, 0x1004(t0)

	li t0,0xbfe0700c
	lw t1,0x0(t0)
	and t2,t1,(1 << 11)
	beqz  t2,2f
	nop

	li t0,0xbfe0700c
	lw t1, 0x0(t0)
	sw t1,0x0(t0)
	li t2,0x3c00
	li t0,0xbfe07014
	sw t2,0x0(t0)
2:
#endif

	/* init processor state at first*/
/* NOTE!! Not more that 16 instructions here!!! Right now it's FULL! */
	/* 清零cp0 status寄存器 */
	mtc0	zero, COP_0_STATUS_REG //cuckoo
	/* 清零cp0 cause寄存器 */
	mtc0	zero, COP_0_CAUSE_REG

	/**
	 * 设置启动异常向量入口地址为ROM地址(0xbfc00000)
	 * 将寄存器cp0 status的BEV置1，使CPU采用ROM(kseg1)空间的异常入口点
	*/
	/* SR_BOOT_EXC_VEC = 0x00400000 */
	li	t0, SR_BOOT_EXC_VEC	/* Exception to Boostrap Location */
	mtc0	t0, COP_0_STATUS_REG //cuckoo   /* 0x00400000 给 SR(BEV)置1 CPU 使用 kseg1 作为入口点 */

	bal     initregs
        nop

	.set	mips32
	mfc0	t0, $16, 6		#Store fill
	.set	mips3
	li	t1, 0xfffffeff
	and	t0, t1, t0
	.set	mips32
	mtc0	t0, $16, 6		#Store fill
	.set	mips3

	/* spi speedup */
	li  t0, 0xbfff0220
	li  t1, 0x47
	sb  t1, 0x4(t0)   /* 设置spi参数控制寄存器，时钟分频数设置为4，快速读模式，连续地址读模式，SPI flash读使能*/

uncached:
	or	ra, UNCACHED_MEMORY_ADDR
	j	ra
	nop

initregs:
	.set noat
        ## init registers
        move    $1, $0
        move    $2, $0
        move    $3, $0
        move    $4, $0
        move    $5, $0
        move    $6, $0
        move    $7, $0
        move    $8, $0
        move    $9, $0
        move    $10, $0
        move    $11, $0
        move    $12, $0
        move    $13, $0
        move    $14, $0
        move    $15, $0
        move    $16, $0
        move    $17, $0
        move    $18, $0
        move    $19, $0
        move    $20, $0
        move    $21, $0
        move    $22, $0
        move    $23, $0
        move    $24, $0
        move    $25, $0
        move    $26, $0
        move    $27, $0
        move    $28, $0
        move    $29, $0
        move    $30, $0

	/* now begin initial float CP1 register */
        ## float point

        mfc0    t0, CP0_STATUS
        li	t1, 0x64000000|SR_KX|SR_SX|SR_UX|SR_BOOT_EXC_VEC
        or      t0, t0, t1
        mtc0    t0, CP0_STATUS
	la	sp, stack
	la	gp, _gp   /* 加载全局指针_gp，定义在ld.script */
	jr	ra
	nop

/*
 *  We get here from executing a bal to get the PC value of the current execute
 *  location into ra. Check to see if we run from ROM or if this is ramloaded.
 */
locate:
	la	s0, uncached
	subu	s0, ra, s0

	mfc0    t0, CP0_STATUS
	li	t1, 0x64000000|SR_KX|SR_SX|SR_UX|SR_BOOT_EXC_VEC      # {cu3,cu2,cu1,cu0}<={0110, status_fr<=1,0xe0 to enable 64bit space
	or	t0, t0, t1
	mtc0	t0, CP0_STATUS
	mtc0	zero, COP_0_CAUSE_REG

cp0_main:


LEAF(ls2k_version)
	.set    mips32
	li a0,0xbfc00000+ NVRAM_OFFS
	lbu v0, (a0)
	xor v0, 0x50
	li a0, 2
	sltu a0, v0, a0
	beqz a0, 1f
	nop
	jr ra
	nop
1:
	
	mfc0    a0, COP_0_PRID
	.set    mips3
	andi    a0, a0, 0xf
	li	a1, 0x3
	bne     a0, a1, 2f
	li	v0, 0
	li	v0, 0x1
2:
	j	ra
	nop
