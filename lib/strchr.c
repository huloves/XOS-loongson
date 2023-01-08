#include <string.h>

char *strchr(const char *p, int c)
{
	if (!p)
		return (0);

	for (; *p; p++)
		if (*p == c)
			return ((char *)p);
	return (0);
}
