#ifndef _STDIO_H
#define _STDIO_H

#define EOF  (-1)

typedef char* va_list;

#define va_start(ap, v) ap = (va_list)&v
#define va_arg(ap, t) *((t*)(ap += 4))
#define va_end(ap) ap = NULL

extern int vsprintf(char *buf, const char *fmt, va_list args);

#endif /* _STDIO_H */
