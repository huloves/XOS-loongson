#include <ls2k/pmon.h>

unsigned long long memorysize = 0;
unsigned long long memorysize_high = 0;
unsigned long long memorysize_total = 0;

void get_memorysize(unsigned long long raw_memsz)
{
	unsigned long long memsz, mem_size;

	memsz = raw_memsz & 0xff;
	memsz = memsz << 29;
	memsz = memsz - 0x1000000;
	memsz = memsz >> 20;

	/*
	 *	Set up memory address decoders to map entire memory.
	 *	But first move away bootrom map to high memory.
	 */
	memorysize = memsz > 240 ? 240 << 20 : memsz << 20;
	memorysize_high = memsz > 240 ? (((unsigned long long)memsz) - 240) << 20 : 0;
	mem_size = memsz;

	memorysize_total =  ((memorysize  +  memorysize_high)  >> 20) + 16;
}