#include <ls2k/stdarg.h>
#include <ls2k/va-mips.h>
#include <string.h>
#include <mips/types.h>
#include <ctype.h>
#include <ls2k/pmon.h>

/*
 *  int vsprintf(d,s,ap)
 */
int 
vsprintf (char *d, const char *s, va_list ap)
{
	const char *t;
	char *p, *dst, tmp[40];
	unsigned int n;
	int fmt, trunc, haddot, width, base, longlong;

	dst = d;
	for (; *s;) {
		if (*s == '%') {
			s++;
			fmt = FMT_RJUST;
			width = trunc = haddot = longlong = 0;
			for (; *s; s++) {
				if (strchr ("diobpxXulscefg%", *s))
					break;
				else if (*s == '-')
					fmt = FMT_LJUST;
				else if (*s == '0')
					fmt = FMT_RJUST0;
				else if (*s == '~')
					fmt = FMT_CENTER;
				else if (*s == '*') {
					if (haddot)
						trunc = va_arg (ap, int);
					else
						width = va_arg (ap, int);
				} else if (*s >= '1' && *s <= '9') {
					for (t = s; isdigit (*s); s++);
					strncpy (tmp, t, s - t);
					tmp[s - t] = '\0';
					atob (&n, tmp, 10);
					if (haddot)
						trunc = n;
					else
						width = n;
					s--;
				} else if (*s == '.')
					haddot = 1;
			}
			if (*s == '%') {
				*d++ = '%';
				*d = 0;
			} else if (*s == 's') {
				p = va_arg (ap, char *);

				if (p)
					strcpy (d, p);
				else
					strcpy (d, "(null)");
			} else if (*s == 'c') {
				n = va_arg (ap, int);
				*d = n;
				d[1] = 0;
			} else {
				if (*s == 'l') {
					if (*++s == 'l') {
						longlong = 1;
						++s;
					}
				}
				if (strchr ("diobpxXu", *s)) {
				 if ((*s == 'd') || (*s == 'i'))
					 base = -10;
					else if (*s == 'u')
						base = 10;
					else if (*s == 'x' || *s == 'X')
						base = 16;
					else if(*s == 'p') {
						base = 16;
						*d++ = '0';
						*d++ = 'x';
						fmt = FMT_RJUST0;
						width = 8;
					}
					else if (*s == 'o')
						base = 8;
					else if (*s == 'b')
						base = 2;
#ifdef HAVE_QUAD
					if (longlong)
						llbtoa(d, va_arg (ap, quad_t),
						    base);
#else
					if (longlong)
					{
					long x=va_arg (ap, long long);
						btoa(d, (long)x,
						    base);
					}

#endif
					else
						btoa(d, va_arg (ap, int), base);

					if (*s == 'X')
						strtoupper(d);
				}
#ifdef FLOATINGPT
				else if (strchr ("eEfgG", *s)) {
					ap2double(d, *s, width, trunc, ap);
				}
#endif
			}
			if (trunc)
				d[trunc] = 0;
			if (width)
				str_fmt (d, width, fmt);
			for (; *d; d++);
			s++;
		} else
			*d++ = *s++;
	}
	*d = 0;
	return (d - dst);
}
