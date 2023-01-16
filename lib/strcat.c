#include <string.h>

char *
strcat(char *dst, const char *src)
{
	char *d;

	if (!dst || !src)
		return (dst);

	d = dst;
	for (; *d; d++);
	for (; *src; src++)
		*d++ = *src;
	*d = 0;
	return (dst);
}