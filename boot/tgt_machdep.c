#include <stdio.h>
#include <mips/types.h>

void tgt_putchar(int);
int tgt_printf(const char *fmt, ...)
{
	int n;
	char buf[1024];
	char *p = buf;
	char c;
	va_list ap;
	va_start(ap, fmt);
	n = vsprintf(buf, fmt, ap);
	va_end(ap);
	while ((c = *p++)) {
		if (c == '\n')
			tgt_putchar('\r');
		tgt_putchar(c);
	}
	return (n);
}

extern char wait_for_smp_call[];

void initmips(unsigned long long raw_memsz)
{
	/* core1 run wait_for_smp_call function in ram */
	asm volatile(".set mips64;sd %1,(%0);.set mips0;"::"r"(0xbfe11120),"r"(&wait_for_smp_call));
	// tgt_fpuenable();
	tgt_printf("memorysize_high");
}
