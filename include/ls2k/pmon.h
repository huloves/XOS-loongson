#ifndef __PMON_H
#define __PMON_H

#include <mips/types.h>

void get_memorysize(unsigned long long raw_memsz);

/* Target dependent functions */
void tgt_putchar(int);

/*-----*/
int	atob(u_int32_t *, char *, int);
char	*btoa(char *, u_int32_t, int32_t);

#endif /* __PMON_H */
