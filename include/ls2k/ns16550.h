#ifndef __NS16550_H
#define __NS16550_H

#ifndef nsreg
#ifndef USE_SM502_UART0
#define nsreg(x)	unsigned char x
#else
#define	nsreg(x)	unsigned int  x
#endif
#endif

#ifndef NSREG
#define NSREG(x)	x
#endif

#define	NS16550_DATA	0
#define	NS16550_IER	1
#define	NS16550_IIR	2
#define	NS16550_FIFO	2
#define	NS16550_CFCR	3
#define	NS16550_MCR	4
#define	NS16550_LSR	5
#define	NS16550_MSR	6	
#define	NS16550_SCR	7

/* character format control register */
#define	CFCR_DLAB	0x80	/* divisor latch */
#define	CFCR_SBREAK	0x40	/* send break */
#define	CFCR_PZERO	0x30	/* zero parity */
#define	CFCR_PONE	0x20	/* one parity */
#define	CFCR_PEVEN	0x10	/* even parity */
#define	CFCR_PODD	0x00	/* odd parity */
#define	CFCR_PENAB	0x08	/* parity enable */
#define	CFCR_STOPB	0x04	/* 2 stop bits */
#define	CFCR_8BITS	0x03	/* 8 data bits */
#define	CFCR_7BITS	0x02	/* 7 data bits */
#define	CFCR_6BITS	0x01	/* 6 data bits */
#define	CFCR_5BITS	0x00	/* 5 data bits */

/* modem control register */
#define	MCR_LOOPBACK	0x10	/* loopback */
#define	MCR_IENABLE	0x08	/* output 2 = int enable */
#define	MCR_DRS		0x04	/* output 1 = xxx */
#define	MCR_RTS		0x02	/* enable RTS */
#define	MCR_DTR		0x01	/* enable DTR */

/* line status register */
#define	LSR_RCV_FIFO	0x80	/* error in receive fifo */
#define	LSR_TSRE	0x40	/* transmitter empty */
#define	LSR_TXRDY	0x20	/* transmitter ready */
#define	LSR_BI		0x10	/* break detected */
#define	LSR_FE		0x08	/* framing error */
#define	LSR_PE		0x04	/* parity error */
#define	LSR_OE		0x02	/* overrun error */
#define	LSR_RXRDY	0x01	/* receiver ready */
#define	LSR_RCV_MASK	0x1f

/* modem status register */
#define	MSR_DCD		0x80	/* DCD active */
#define	MSR_RI		0x40	/* RI  active */
#define	MSR_DSR		0x20	/* DSR active */
#define	MSR_CTS		0x10	/* CTS active */
#define	MSR_DDCD	0x08    /* DCD changed */
#define	MSR_TERI	0x04    /* RI  changed */
#define	MSR_DDSR	0x02    /* DSR changed */
#define	MSR_DCTS	0x01    /* CTS changed */

#endif /* __NS16550_H */
