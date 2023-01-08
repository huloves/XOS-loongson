#ifndef __PMON_H
#define __PMON_H

#include <mips/types.h>

void get_memorysize(unsigned long long raw_memsz);

/* Target dependent functions */
void tgt_putchar(int);

/*-----*/
int	atob(u_int32_t *, char *, int);

#endif /* __PMON_H */
