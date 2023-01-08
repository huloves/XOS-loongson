void tgt_putchar(int);
int tgt_printf(const char *fmt, ...)
{
	
}

extern char wait_for_smp_call[];

void initmips(unsigned long long raw_memsz)
{
	/* core1 run wait_for_smp_call function in ram */
	asm volatile(".set mips64;sd %1,(%0);.set mips0;"::"r"(0xbfe11120),"r"(&wait_for_smp_call));
	tgt_fpuenable();
}
