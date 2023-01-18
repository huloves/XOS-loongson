#ifndef _MIPS_PTE_H
#define _MIPS_PTE_H

#define	PT_ENTRY_NULL	((pt_entry_t *) 0)

#define PG_WIRED	0x80000000	/* SW */
#define PG_RO		0x40000000	/* SW */

#define	PG_SVPN		0xfffff000	/* Software page no mask */
#define	PG_HVPN		0xffffe000	/* Hardware page no mask */
#define	PG_ODDPG	0x00001000	/* Odd even pte entry */
#define	PG_ASID		0x000000ff	/* Address space ID */
#define	PG_G		0x00000001	/* HW */
#define	PG_V		0x00000002
#define	PG_NV		0x00000000
#define	PG_M		0x00000004
#define	PG_ATTR		0x0000003f
#define	PG_UNCACHED	0x00000010
#define	PG_CACHED	0x00000018
#define	PG_CACHEMODE	0x00000038
#define	PG_ROPAGE	(PG_V | PG_RO | PG_CACHED) /* Write protected */
#define	PG_RWPAGE	(PG_V | PG_M | PG_CACHED)  /* Not wr-prot not clean */
#define	PG_CWPAGE	(PG_V | PG_CACHED)	   /* Not wr-prot but clean */
#define	PG_IOPAGE	(PG_G | PG_V | PG_M | PG_UNCACHED)
#define	PG_FRAME	0x3fffffc0
#define PG_SHIFT	6
#define pfn_is_ext(x) ((x) & 0x3c000000)
#define vad_to_pfn(x) (((unsigned)(x) >> PG_SHIFT) & PG_FRAME)
#define vad_to_pfn64(x) (((quad_t)(x) >> PG_SHIFT) & PG_FRAME)
#define pfn_to_pad(x) (((x) & PG_FRAME) << PG_SHIFT)
#define vad_to_vpn(x) ((unsigned)(x) & PG_SVPN)
#define vpn_to_vad(x) ((x) & PG_SVPN)
/* User viritual to pte page entry */
#define uvtopte(adr) (((adr) >> PGSHIFT) & (NPTEPG -1))

#define	PG_SIZE_4K	0x00000000
#define	PG_SIZE_16K	0x00006000
#define	PG_SIZE_64K	0x0001e000
#define	PG_SIZE_256K	0x0007e000
#define	PG_SIZE_1M	0x001fe000
#define	PG_SIZE_4M	0x007fe000
#define	PG_SIZE_16M	0x01ffe000

#if defined(RM9000)
#define PG_SIZE_64M	0x07ffe000
#define PG_SIZE_256M	0x1fffe000
#endif

#endif /* _MIPS_PTE_H */
