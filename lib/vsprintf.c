#include <ls2k/stdarg.h>
#include <string.h>

int vsprintf(char *d, const char *s, va_list ap)
{
	const char *t;
	char *p, *dst, tmp[40];
	unsigned int n;
	int fmt, trunc, haddot, width, base, longlong;
}