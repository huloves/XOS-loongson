#ifndef __STRING_H
#define __STRING_H

#include <ls2k/asni.h>

#ifdef  _BSD_SIZE_T_
typedef _BSD_SIZE_T_    size_t;
#undef  _BSD_SIZE_T_
#endif

char	*strchr(const char *, int);
int	strncmp(const char *, const char *, size_t);

/* definitions for fmt parameter of str_fmt(p,width,fmt) */
#define FMT_RJUST 0
#define FMT_LJUST 1
#define FMT_RJUST0 2
#define FMT_CENTER 3

#endif /* __STRING_H */
