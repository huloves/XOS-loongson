#include <ls2k/ls2k.h>
#include <ls2k/regdef.h>
#include <ls2k/bonito.h>
#include <ls2k/ns16550.h>
#include <mips/asm.h>
#include <mips/cpu.h>
#include <mips/pte.h>

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
	/* ??????????????????start???????????????0x4000 */
stack = start - 0x4000		/* Place PMON stack below PMON start in RAM */
	/*set all spi cs to 1, default input*/
	/* ??????spi??????????????? 0xbfff0225 = 0x1fff0220 + 0xa0000000 + 5???????????????????????????*/
	/* ???spi??????????????????????????????????????????0xff */
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
	/* ??????cp0 status????????? */
	mtc0	zero, COP_0_STATUS_REG //cuckoo
	/* ??????cp0 cause????????? */
	mtc0	zero, COP_0_CAUSE_REG

	/**
	 * ???????????????????????????????????????ROM??????(0xbfc00000)
	 * ????????????cp0 status???BEV???1??????CPU??????ROM(kseg1)????????????????????????
	*/
	/* SR_BOOT_EXC_VEC = 0x00400000 */
	li	t0, SR_BOOT_EXC_VEC	/* Exception to Boostrap Location */
	mtc0	t0, COP_0_STATUS_REG //cuckoo   /* 0x00400000 ??? SR(BEV)???1 CPU ?????? kseg1 ??????????????? */

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
	sb  t1, 0x4(t0)   /* ??????spi????????????????????????????????????????????????4?????????????????????????????????????????????SPI flash?????????*/

	bal	locate			/* Get current execute address */
	nop

uncached:
	or	ra, UNCACHED_MEMORY_ADDR
	j	ra
	nop

/*
 *  Reboot vector usable from outside pmon.
 */
	.align	8
ext_map_and_reboot:
	bal	CPU_TLBClear
	nop

	li	a0, 0xc0000000
	li	a1, 0x40000000
	bal	CPU_TLBInit
	nop
	la	v0, tgt_reboot
	la	v1, start
	subu	v0, v1
	lui	v1, 0xffc0
	addu	v0, v1
	jr	v0
	nop

/*
 *  Exception vectors here for rom, before we are up and running. Catch
 *  whatever comes up before we have a fully fledged exception handler.
 */
	.align	9			/* bfc00200 */
	move	k0, ra		#save ra
	la	a0, v200_msg
	bal	stringserial
	nop
	b	exc_common

	.align	7			/* bfc00280 */
	move	k0, ra	#save ra
	la	a0, v280_msg
	bal	stringserial
	nop
	b	exc_common

/* Cache error */
	.align	8			/* bfc00300 */
	PRINTSTR("\r\nPANIC! Unexpected Cache Error exception! ")
	mfc0	a0, COP_0_CACHE_ERR
	bal	hexserial
	nop
	b	exc_common

/* General exception */
	.align	7			/* bfc00380 */
	move	k0, ra		#save ra
	la	a0, v380_msg
	bal	stringserial
	nop
	b	exc_common

	.align	8			/* bfc00400 */
	move	k0, ra		#save ra
	la	a0, v400_msg
	bal	stringserial
	nop

#if 1
	b	exc_common
	nop
#endif

	.align 8           /* bfc00500 */
	.set mips64


	/* store ra and sp to memory */
	dli t0, 0x900000000faaa040
	sd  a0, 0x0(t0) //store ra

	dli t1, 0x900000000faaa048
	sd  a1, 0x0(t1) //store sp

	dli t2, 0x900000000faaa050
	dli t0, 0x5a5a5a5a5a5a5a5a
	sd  t0, 0x0(t2) //store str flag

	.set mips3
	la  s0, start
	li  a0, 0xbfc00000
	subu    s0, a0, s0
	and s0, 0xffff0000

1:  	li v1,0x100
	subu    v1, v1, 0x1
	nop

1:  	lui t0, 0xbfe1  /* Enable DDR control register  */
	ld  t1, 0x0420(t0)
	nop
	dli t2, (0x1 << 41)
	or t1, t1, t2
	sd  t1, 0x0420(t0)

	dli t2, ~(0x1 << 40)
	and t1, t1, t2
	sd  t1, 0x0420(t0)
	sync

	.set mips64
	li  a0,0x0
	dli t0, 0x900000001fe10000

	STR_XBAR_CONFIG_NODE_a0(0x10, \
			0x0000000000000000, \
			0xfffffffff0000000, \
			0x00000000000000f0)

	dli a0, 0x900000000ff00000
	ld  t1, 0x198(a0)
	dli t3, 0x0000000f00000000
	or  t1, t1, t3  /* bit32 for self refresh*/
	sd  t1, 0x198(a0)
	sync

	/* Don't forget to recovery the XbarII config Window */
	li  a0,0x0
	dli t0, 0x900000001fe10000
	STR_XBAR_CONFIG_NODE_a0(0x10, \
			0x0000000000000000, \
			0xfffffffff0000000, \
			0x00000000000000f0)
	sync
	sync
	sync
	sync
	sync

	/* delay */
	//li  t0, 0x400000
	li  t0, 0x40
	1:
	subu    t0, t0, 0x1
	bnez    t0, 1b
	nop

	li  t0,0xbfe07000
	/* set key,usb,gmac wakeup of reg GPE0_EN */
	lw  t1, 0x2c(t0)
	li  t3, (0x1 << 8)|(0x3f<<10)|(0x1<<6)|(0x1<<5)
	or  t1, t1, t3
	sw  t1, 0x2c(t0)

	/* set USB_GMAC_OK of reg PMCON_RESUME */
	lw  t1, 0x04(t0)
	li  t3, (0x1<<7)
	or  t1, t1, t3
	sw  t1, 0x04(t0)

	/* set WOL_BAT_EN of reg PMCON_RTC */
	lw  t1, 0x08(t0)
	li  t3, (0x1<<7)
	or  t1, t1, t3
	sw  t1, 0x08(t0)

	/* clear 0-15 of reg GPE0_STS */
	lw  t1, 0x28(t0)
	li  t3, 0x0000ffff
	sw  t3, 0x28(t0)

	/*clean acpi wake status*/
	lw t1, 0x0c(t0)
	li t3, 0x8100
	sw t3, 0x0c(t0)

	/*clean acpi pwrbtn staus*/
	lw t1, 0x10(t0)
	li t3, (0x1 << 8)
	or t1, t1, t3
	sw t1, 0x10(t0)

	PRINTSTR("\nSystem Enter S3!!!\n")

	/* enable acpi porbtn and set acpi alptype is S3 status*/
	lw t1, 0x14(t0)
	li t3, 0x3400
	sw t3, 0x14(t0)
	nop

	/* delay */
	li t0, 0x4000
	2:
	subu t0, t0, 0x1
	bnez t0, 2b
	nop

	1:
	b 1b
	nop

	/* Debug exception */
	.align  7           /* bfc00480 */
exc_common:
	PRINTSTR("\r\nCAUSE=")
	mfc0	a0, COP_0_CAUSE_REG
	bal	hexserial
	nop
	PRINTSTR("\r\nSTATUS=")
	mfc0	a0, COP_0_STATUS_REG
	bal	hexserial
	nop
	PRINTSTR("\r\nERRORPC=")
	mfc0	a0, COP_0_ERROR_PC
	bal	hexserial
	nop
	PRINTSTR("\r\nEPC=")
	mfc0	a0, COP_0_EXC_PC
	bal	hexserial
	nop
1:
    	b	1b
    	nop
	PRINTSTR("\r\nDERR0=")
	cfc0	a0, COP_0_DERR_0
	bal	hexserial
	nop
	PRINTSTR("\r\nDERR1=")
	cfc0	a0, COP_0_DERR_1
	bal	hexserial
	nop

//	b	ext_map_and_reboot
	nop

	.align 8
		nop
	.align 8
	.word vsprintf

	move    a1, $0;

initregs:
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
	la	gp, _gp   /* ??????????????????_gp????????????ld.script */
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
	.set    mips32
        mfc0    t0, $15, 1      #EBASE
        .set    mips3
        andi    t0, t0, 0x3ff
        bnez    t0, wait_for_smp
        nop

	bal watchdog_close
	nop

	li	t0, 0xbfe10420
	lw	t2, 0x0(t0)
	or	t2, 0xc00
	sw	t2, 0x0(t0)

	lui	t0, 0xba00
	lui	t1, 0x1fe0
	sw	t1, 0x1010(t0) /* config bar for APB */
	lw	t2, 0x1004(t0)
	ori	t2, t2, 0x2
	sw	t2, 0x1004(t0)

	bal 	tlb_init
	nop

	bal	HS0636_beep_on
	nop
	li	a0, 0x8000
1:
	addiu	a0, -1
	nop
	bnez	a0, 1b
	nop
	bal	beep_off//mtf
	nop

#if 1	//xwr pcie signal test
        li      t0, 0xbfe10000

	li	t1, 0xc2492331
	sw	t1, 0x580(t0)
	sw	t1, 0x5a0(t0)

	li	t1, 0xff3ff0a8
	sw	t1, 0x584(t0)
	sw	t1, 0x5a4(t0)

	li	t1, 0x27fff
	sw	t1, 0x588(t0)
	sw	t1, 0x5a8(t0)

#endif
/* mtf add for cfg pcie */
	
        li      t0, 0xbfe10590
        dli     t1, 0x14fff1002
        sd      t1, 0x0(t0)
        sd      t1, 0x20(t0)

        dli     t1, 0x14fff1102
        sd      t1, 0x0(t0)
        sd      t1, 0x20(t0)
	
        dli     t1, 0x14fff1202
        sd      t1, 0x0(t0)
        sd      t1, 0x20(t0)
	
        dli     t1, 0x14fff1302
        sd      t1, 0x0(t0)
        sd      t1, 0x20(t0)
	
	li	t0, 0xbfe10430
	lw	t1, 0x0(t0)
	or	t1, t1, 0x30000	//pcie enable
	sw	t1, 0x0(t0)

//pcie1 port0
	dli	t0, 0x900000fe0800680c
	li	t1, 0xfff9ffff
        lw      t2, 0x0(t0)
        and     t1, t1, t2
	or	t1, 0x20000
	sw	t1, 0x0(t0)

	dli	t0, 0x900000fe0700681c
    lw  t2, 0x0(t0)
    li  t1, (0x1 << 26)
    or  t2, t1
    sw  t2, 0x0(t0)


	dli	t0, 0x900000fe00006800

	lw	t1, 0x78(t0)
	li	t2, ~(0x7 << 12)
	and	t1, t1, t2
	li	t2, 0x1000
	or	t1, t1, t2
	sw	t1, 0x78(t0)

#if defined(FORCE_PCIE_GEN1) && FORCE_PCIE_GEN1 & 0x10
//pcie capability link control 2, target link speed(bit 3:0)
    lw 	    t1, 0xa0(t0)
    or	    t1, 3
    xor     t1, 2
    sw      t1, 0xa0(t0)
#endif
	li	t1, 0x10000000
	sw	t1, 0x10(t0)

	dli	t0, 0x9000000000000000
	li      t1, 0x10000000
	or	t0, t0, t1

    li  t1, (0x7<<18)|(0x7<<2)
    not t1, t1
    lw  t2, 0x54(t0)
    and t2, t2, t1
    sw  t2, 0x54(t0)

    lw  t2, 0x58(t0)
    and t2, t2, t1
    sw  t2, 0x58(t0)

	dli	t1, 0xff204c | ((PCIE_LANE_FLIP>>(2*4)) & 3)
        sw      t1, 0x0(t0)
  
//pcie1 port1
	dli	t0, 0x900000fe0800700c
	li	t1, 0xfff9ffff
        lw      t2, 0x0(t0)
        and     t1, t1, t2
	or	t1, 0x20000
	sw	t1, 0x0(t0)

	dli	t0, 0x900000fe0700701c
    lw  t2, 0x0(t0)
    li  t1, (0x1 << 26)
    or  t2, t1
    sw  t2, 0x0(t0)

	dli	t0, 0x900000fe00007000

	lw	t1, 0x78(t0)
	li	t2, ~(0x7 << 12)
	and	t1, t1, t2
	li	t2, 0x1000
	or	t1, t1, t2
	sw	t1, 0x78(t0)

#if defined(FORCE_PCIE_GEN1) && FORCE_PCIE_GEN1 & 0x20
//pcie capability link control 2, target link speed(bit 3:0)
    lw 	    t1, 0xa0(t0)
    or	    t1, 3
    xor     t1, 2
    sw      t1, 0xa0(t0)
#endif
	li	t1, 0x10100000
	sw	t1, 0x10(t0)

	dli	t0, 0x9000000000000000
	li      t1, 0x10100000
	or	t0, t0, t1

    li  t1, (0x7<<18)|(0x7<<2)
    not t1, t1
    lw  t2, 0x54(t0)
    and t2, t2, t1
    sw  t2, 0x54(t0)

    lw  t2, 0x58(t0)
    and t2, t2, t1
    sw  t2, 0x58(t0)

	dli	t1, 0xff204c | ((PCIE_LANE_FLIP>>(2*5)) & 3)
        sw      t1, 0x0(t0)
  
//pcie0 port0
	dli	t0, 0x900000fe0800480c	//other pcie controller
	li	t1, 0xfff9ffff
        lw      t2, 0x0(t0)
        and     t1, t1, t2
	or	t1, 0x20000
	sw	t1, 0x0(t0)

	dli	t0, 0x900000fe0700481c
    lw  t2, 0x0(t0)
    li  t1, (0x1 << 26)
    or  t2, t1
    sw  t2, 0x0(t0)

	dli	t0, 0x900000fe00004800

	lw	t1, 0x78(t0)
	li	t2, ~(0x7 << 12)
	and	t1, t1, t2
	li	t2, 0x1000
	or	t1, t1, t2
	sw	t1, 0x78(t0)

#if defined(FORCE_PCIE_GEN1) && FORCE_PCIE_GEN1 & 1
//pcie capability link control 2, target link speed(bit 3:0)
    lw 	    t1, 0xa0(t0)
    or	    t1, 3
    xor     t1, 2
    sw      t1, 0xa0(t0)
#endif
	li	t1, 0x11000000
	sw	t1, 0x10(t0)

	dli	t0, 0x9000000000000000
	li      t1, 0x11000000
	or	t0, t0, t1

    li  t1, (0x7<<18)|(0x7<<2)
    not t1, t1
    lw  t2, 0x54(t0)
    and t2, t2, t1
    sw  t2, 0x54(t0)

    lw  t2, 0x58(t0)
    and t2, t2, t1
    sw  t2, 0x58(t0)

	dli	t1, 0xff204c | ((PCIE_LANE_FLIP>>(2*0)) & 3)
        sw      t1, 0x0(t0)
  
//pcie0 port1
	dli	t0, 0x900000fe0800500c	//other pcie controller
	li	t1, 0xfff9ffff
        lw      t2, 0x0(t0)
        and     t1, t1, t2
	or	t1, 0x20000
	sw	t1, 0x0(t0)

	dli	t0, 0x900000fe0700501c
    lw  t2, 0x0(t0)
    li  t1, (0x1 << 26)
    or  t2, t1
    sw  t2, 0x0(t0)

	dli	t0, 0x900000fe00005000

	lw	t1, 0x78(t0)
	li	t2, ~(0x7 << 12)
	and	t1, t1, t2
	li	t2, 0x1000
	or	t1, t1, t2
	sw	t1, 0x78(t0)

#if defined(FORCE_PCIE_GEN1) && FORCE_PCIE_GEN1 & 2
//pcie capability link control 2, target link speed(bit 3:0)
    lw 	    t1, 0xa0(t0)
    or	    t1, 3
    xor     t1, 2
    sw      t1, 0xa0(t0)
#endif
	li	t1, 0x11100000
	sw	t1, 0x10(t0)

	dli	t0, 0x9000000000000000
	li      t1, 0x11100000
	or	t0, t0, t1

    li  t1, (0x7<<18)|(0x7<<2)
    not t1, t1
    lw  t2, 0x54(t0)
    and t2, t2, t1
    sw  t2, 0x54(t0)

    lw  t2, 0x58(t0)
    and t2, t2, t1
    sw  t2, 0x58(t0)

	dli	t1, 0xff204c | ((PCIE_LANE_FLIP>>(2*1)) & 3)
        sw      t1, 0x0(t0)
  
//pcie0 port2
	dli	t0, 0x900000fe0800580c	//other pcie controller
	li	t1, 0xfff9ffff
        lw      t2, 0x0(t0)
        and     t1, t1, t2
	or	t1, 0x20000
	sw	t1, 0x0(t0)

	dli	t0, 0x900000fe00005800

	lw	t1, 0x78(t0)
	li	t2, ~(0x7 << 12)
	and	t1, t1, t2
	li	t2, 0x1000
	or	t1, t1, t2
	sw	t1, 0x78(t0)

#if defined(FORCE_PCIE_GEN1) && FORCE_PCIE_GEN1 & 4
//pcie capability link control 2, target link speed(bit 3:0)
    lw 	    t1, 0xa0(t0)
    or	    t1, 3
    xor     t1, 2
    sw      t1, 0xa0(t0)
#endif
	li	t1, 0x11200000
	sw	t1, 0x10(t0)

	dli	t0, 0x9000000000000000
	li      t1, 0x11200000
	or	t0, t0, t1

    li  t1, (0x7<<18)|(0x7<<2)
    not t1, t1
    lw  t2, 0x54(t0)
    and t2, t2, t1
    sw  t2, 0x54(t0)

    lw  t2, 0x58(t0)
    and t2, t2, t1
    sw  t2, 0x58(t0)

	dli	t1, 0xff204c | ((PCIE_LANE_FLIP>>(2*2)) & 3) 
        sw      t1, 0x0(t0)
  
//pcie0 port3
	dli	t0, 0x900000fe0800600c	//other pcie controller
	li	t1, 0xfff9ffff
        lw      t2, 0x0(t0)
        and     t1, t1, t2
	or	t1, 0x20000
	sw	t1, 0x0(t0)

	dli	t0, 0x900000fe00006000

	lw	t1, 0x78(t0)
	li	t2, ~(0x7 << 12)
	and	t1, t1, t2
	li	t2, 0x1000
	or	t1, t1, t2
	sw	t1, 0x78(t0)

#if defined(FORCE_PCIE_GEN1) && FORCE_PCIE_GEN1 & 8
//pcie capability link control 2, target link speed(bit 3:0)
    lw 	    t1, 0xa0(t0)
    or	    t1, 3
    xor     t1, 2
    sw      t1, 0xa0(t0)
#endif
	li	t1, 0x11300000
	sw	t1, 0x10(t0)

	dli	t0, 0x9000000000000000
	li      t1, 0x11300000
	or	t0, t0, t1

    li  t1, (0x7<<18)|(0x7<<2)
    not t1, t1
    lw  t2, 0x54(t0)
    and t2, t2, t1
    sw  t2, 0x54(t0)

    lw  t2, 0x58(t0)
    and t2, t2, t1
    sw  t2, 0x58(t0)

	dli	t1, 0xff204c | ((PCIE_LANE_FLIP>>(2*3)) & 3)
        sw      t1, 0x0(t0)

pcie_cfg_done:
	bal	initserial
	nop

	PRINTSTR("\r\ninitserial good ^_^...\r\n")
	nop

loop_:
	b loop_

	bal 	initserial_later
	nop

#if 1 /* Config SATA : use internel clock */
	li	t0, 0xbfe10000

    	li      t1, 0x30c31cf9
    	sw      t1, 0x454(t0)
    	li      t1, 0xf300040f
    	sw      t1, 0x450(t0)

#if 1
	PRINTSTR("\r\nUSE internel SATA ref clock\r\n")
	li	t1, 0xbfe10450
	ld	a0, 0x0(t1)
	li	a1, 0x2
	not	a1, a1
	and	a0, a0, a1
	sd	a0, 0x0(t1)
	sync

	ld	a0, 0x0(t1)
	li	a1, 0x4
    or  a0, a1
	sd	a0, 0x0(t1)
	sync

	ld	a0, 0x0(t1)
	li	a1, 0x8
    or  a0, a1
	sd	a0, 0x0(t1)
	sync

	ld	a0, 0x0(t1)
	bal	hexserial64
	nop
#endif
#endif

#if 1 /* Config SATA TX signal*/
        li      t0, 0xbfe10458
        dli     t1, 0x1403f1002
        sd      t1, 0x0(t0)
#endif


#if 1 // Fix the Gmac0  multi-func to enable Gmac1
	li	t0, 0xbfe13800
	dli	a0, 0xffffff0000ffffff
	sd	a0, 0x08(t0)

	li	t0, 0xba001800
	li	a0, 0x0080ff08
	sw	a0, 0x0c(t0)
#endif

#if 1 // Set the invalid BAR to read only
	li	t0, 0xbfe13800
	dli	a0, 0xff00ff0000fffff0
	sd	a0, 0x00(t0)
	sd	a0, 0x08(t0)
	sd	a0, 0x10(t0)
	sd	a0, 0x18(t0)
	sd	a0, 0x20(t0)
	sd	a0, 0x28(t0)
	sd	a0, 0x30(t0)
	sd	a0, 0x38(t0)
	sd	a0, 0x40(t0)
	sd	a0, 0x48(t0)
	sd	a0, 0x50(t0)
#endif

start_now:

	PRINTSTR("\r\nPMON2000 MIPS Initializing. Standby...\r\n")

	bnez	s0, 1f
	nop
	li	a0, 128
	la	v0, initmips
	jr	v0
	nop

.global wait_for_smp;
.global wait_for_smp_call;
wait_for_smp:
	bal 	tlb_init
	nop
	mfc0	t1, CP0_CONFIG
	ori	t1, t1, 0x3
	mtc0	t1, CP0_CONFIG
	la	t1, 1f
	addu	t1, s0
	li	v0, 0x9fffffff
	and	t1, v0
	jr	t1
	nop
1:
	li	t0, 0xbfe11120
	sd	zero, 0(t0)
	sd	t1, 8(t0)

wait_for_smp_call:
1:
	ld	t1, 0(t0)
	beqz	t1, 1b
	ld	sp, 8(t0)
	sd	zero,0(t0)
	ld	gp, 16(t0)

	jr	t1
	nop

LEAF(CPU_TLBClear)
	li	a3, 0			# First TLB index.

	li	a2, PG_SIZE_4K
	MTC0	a2, COP_0_TLB_PG_MASK   # Whatever...

1:
	MTC0	zero, COP_0_TLB_HI	# Clear entry high.
	MTC0	zero, COP_0_TLB_LO0	# Clear entry low0.
	MTC0	zero, COP_0_TLB_LO1	# Clear entry low1.

	mtc0	a3, COP_0_TLB_INDEX	# Set the index.
	addiu	a3, 1
	li	a2, 64
	nop
	nop
	tlbwi				# Write the TLB

	bne	a3, a2, 1b
	nop

	jr	ra
	nop
END(CPU_TLBClear)

/*
 *  Set up the TLB. Normally called from start.S.
 */
LEAF(CPU_TLBInit)
	li	a3, 0			# First TLB index.

	li	a2, PG_SIZE_16M
	MTC0	a2, COP_0_TLB_PG_MASK   # All pages are 16Mb.

1:
	and	a2, a0, PG_SVPN
	MTC0	a2, COP_0_TLB_HI	# Set up entry high.

	move	a2, a0
	srl	a2, a0, PG_SHIFT 
	and	a2, a2, PG_FRAME
	ori	a2, PG_IOPAGE
	MTC0	a2, COP_0_TLB_LO0	# Set up entry low0.
	addu	a2, (0x01000000 >> PG_SHIFT)
	MTC0	a2, COP_0_TLB_LO1	# Set up entry low1.

	mtc0    a3, COP_0_TLB_INDEX	# Set the index.
	addiu	a3, 1
	li	a2, 0x02000000
	subu	a1, a2
	nop
	tlbwi				# Write the TLB

	bgtz	a1, 1b
	addu	a0, a2			# Step address 32Mb.

	jr	ra
	nop
END(CPU_TLBInit)

LEAF(outstring)
	move	a2, ra
	move	a1, a0
	lbu	a0, 0(a1)
1:
	beqz	a0, 2f
	nop
	bal	tgt_putchar
	addiu	a1, 1
	b	1b
	lbu	a0, 0(a1)

2:
	j	a2
	nop
END(outstring)

LEAF(hexserial)
	move	a2, ra
	move	a1, a0
	li	a3, 7
1:
	rol	a0, a1, 4
	move	a1, a0
	and	a0, 0xf
	la	v0, hexchar
	addu	v0, s0
	addu	v0, a0
#ifdef BOOT_FROM_NAND
#ifdef NAND_ECC_MODE
	addiu   v0, v0,0x400 
#endif
#endif
	bal	tgt_putchar
	lbu	a0, 0(v0)

	bnez	a3, 1b
	addu	a3, -1

	j	a2
	nop
END(hexserial)

LEAF(stringserial)
	move	a2, ra
	addu	a1, a0, s0
	lbu	a0, 0(a1)
1:
	beqz	a0, 2f
	nop
	bal	tgt_putchar
	addiu	a1, 1
	b	1b
	lbu	a0, 0(a1)
2:
	j	a2
	nop
END(stringserial)

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
END(outstring)
__main:
	j	ra
	nop

	.rdata
transmit_pat_msg:
	.asciz	"\r\nInvalid transmit pattern.  Must be DDDD or DDxDDx\r\n"
v200_msg:
	.asciz	"\r\nPANIC! Unexpected TLB refill exception!\r\n"
v280_msg:
	.asciz	"\r\nPANIC! Unexpected XTLB refill exception!\r\n"
v380_msg:
	.asciz	"\r\nPANIC! Unexpected General exception!\r\n"
v400_msg:
	.asciz	"\r\nPANIC! Unexpected Interrupt exception!\r\n"
hexchar:
	.ascii	"0123456789abcdef"

	.text
	.align	2

#define Index_Store_Tag_D			0x09
#define Index_Invalidate_I			0x00
#define Index_Writeback_Inv_D			0x01
#define Index_Writeback_Inv_S			0x01//delete scache  
#define Index_Store_Tag_S			0x0B 

LEAF(nullfunction)
	jr ra
	nop
END(nullfunction)

LEAF(tlb_init)
        mtc0    $0, CP0_WIRED
        mtc0    $0, CP0_PAGEMASK
tlb_flush_all:
        lui     a0, 0x8000
        addiu   a1, $0, 64
        #a0=KSEG0,a1 = tlbsize, v0, v1, a3 used as local registers
        mtc0    $0, CP0_ENTRYLO0
        mtc0    $0, CP0_ENTRYLO1
        mfc0    v0, CP0_WIRED
        addu    v1, $0, a0
1:      sltu    a3, v0, a1
        beq     a3, $0, 1f
        nop
        mtc0    v1, CP0_ENTRYHI
        mtc0    v0, CP0_INDEX
        tlbwi
        addiu   v1, v1, 0x2000
        beq     $0, $0, 1b
        addiu   v0, v0, 1
1:
        ###tlb_init finish####
        tlbp
	jr ra
	nop
END(tlb_init)

LEAF(initserial)
	.set noat
	move 	AT,ra

#if 1   //mtf add
	li	a0, COM1_BASE_ADDR
	li	t1, CFCR_DLAB
	sb	t1, NSREG(NS16550_CFCR)(a0)

	li	t1, 0
	sb	t1, 1(a0)
	li	t1, 0x36	# divider, highest possible baud rate
	sb	t1, 0(a0)

1:
	lb	a1, 0(a0)
	bne	a1, t1, 1b
	nop

	li	t1, 3	#CFCR_8BITS
	sb	t1, 3(a0)	#NSREG(NS16550_CFCR)(v0)

	li	t1, 71
	sb	t1, 2(a0)
#endif
 
        j       ra
        nop
	.set at
END(initserial)

LEAF(initserial_later)
	.set noat
	move 	AT,ra

#if 1   //mtf add
	li	a0, COM1_BASE_ADDR
	li	t1, CFCR_DLAB
	sb	t1, NSREG(NS16550_CFCR)(a0)

	li	t1, 0
	sb	t1, 1(a0)
	li	t1, 68	# divider, highest possible baud rate
	sb	t1, 0(a0)

1:
	lb	a1, 0(a0)
	bne	a1, t1, 1b
	nop

	li	t1, 3	#CFCR_8BITS
	sb	t1, 3(a0)	#NSREG(NS16550_CFCR)(v0)

	li	t1, 71
	sb	t1, 2(a0)
#endif
 
        j       ra
        nop
	.set at
END(initserial_later)

LEAF(tgt_putchar)
	.set noat
	move	AT, ra
	la	v0, COM1_BASE_ADDR
	bal	1f
	nop
	jr	AT
	nop
  
1:
	lbu	v1, NSREG(NS16550_LSR)(v0)
	and	v1, LSR_TXRDY
	beqz	v1, 1b
	nop
						 
	sb	a0, NSREG(NS16550_DATA)(v0)
	j	ra
	nop
	.set at
END(tgt_putchar)

LEAF(hexserial64)
	move	t7, ra
	move	t6, a0
	dsrl	a0, 32
	bal	hexserial
	nop
	move	a0, t6
	bal	hexserial
	nop
	jr	t7
	nop
END(hexserial64)

#define BEEP_GPIO 39

LEAF(HS0636_beep_on)
//enable output
	li	t1, 0xbfe10500 + BEEP_GPIO*4/32

	li	v1, (1<<(BEEP_GPIO&31))
	lw	t0, 0(t1)
	or	t0, v1
	xor	t0, v1
	sw	t0, 0(t1)

	li	t1, 0xbfe10510 + BEEP_GPIO*4/32
	li	a1, 0x80
222:
	li	v1, (1<<(BEEP_GPIO&31))
	lw	t0, 0(t1)
	or	t0, v1
	xor	t0, v1
	sw	t0, 0(t1)

	li	a0, 0xd
1:
	addiu	a0, -1
	nop
	bnez	a0, 1b
	nop

	li	v1, (1<<(BEEP_GPIO&31))
	lw	t0, 0(t1)
	or	t0, v1
	sw	t0, 0(t1)


	li	a0, 0xd
1:
	addiu	a0, -1
	nop
	bnez	a0, 1b
	nop

	addiu	a1, -1
	nop
	bnez	a1, 222b
	nop

	jr	ra
	nop
END(HS0636_beep_on)

LEAF(beep_on)
	/* enable gpio35 output */
	li	t1, 0xbfe10500 + BEEP_GPIO*4/32
	li	v1, (1<<(BEEP_GPIO&31))
	lw	t0, 0(t1)
	or	t0, v1
	xor	t0, v1
	sw	t0, 0(t1)
	/* set gpio35 high */
	lw	t0, 0x10(t1)
	or	t0, v1
	sw	t0, 0x10(t1)
	
	jr	ra
	nop
END(beep_on)
	
LEAF(beep_off)
	/* enable gpio35 output */
	li	t1, 0xbfe10500 + BEEP_GPIO*4/32
	li	v1, (1<<(BEEP_GPIO&31))
	lw	t0, 0(t1)
	or	t0, v1
	xor	t0, v1
	sw	t0, 0(t1)
	/* set gpio35 high */
	lw	t0, 0x10(t1)
	or	t0, v1
	xor	t0, v1
	sw	t0, 0x10(t1)

	jr	ra
	nop
END(beep_off)

LEAF(watchdog_close)
	//disable watch DOG.
	/*gpio 3 output zero*/
	li t1,0xbfe10500

	li t2,(1 << 3)
	not t2,t2
	lw t3,0x0(t1)
	and t2,t3
	sw t2,0x0(t1)

	li t2,(1 << 3)
	lw t3,0x10(t1)
	not t2,t2
	and t2,t3
	sw t2,0x10(t1)
	nop

	jr		ra
	nop
END(watchdog_close)
