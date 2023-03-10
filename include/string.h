#ifndef __STRING_H
#define __STRING_H

#include <ls2k/asni.h>

#ifdef  _BSD_SIZE_T_
typedef _BSD_SIZE_T_    size_t;
#undef  _BSD_SIZE_T_
#endif

char	*strcat(char *, const char *);
char	*strchr(const char *, int);
char	*strncpy(char *, const char *, size_t);
int	strncmp(const char *, const char *, size_t);
char	*strcpy(char *, const char *);
size_t	strlen(const char *);
char	*strichr(char *, int);
void	strtoupper(char *);
void	str_fmt(char *, int, int);

/* definitions for fmt parameter of str_fmt(p,width,fmt) */
#define FMT_RJUST 0
#define FMT_LJUST 1
#define FMT_RJUST0 2
#define FMT_CENTER 3

#endif /* __STRING_H */
