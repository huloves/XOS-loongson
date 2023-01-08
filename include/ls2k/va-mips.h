#ifndef __VA_MIPS_H
#define __VA_MIPS_H

#define va_start(__AP, __LASTARG) \
  (__AP = (__gnuc_va_list) __builtin_next_arg (__LASTARG))

#define va_end(__AP)	((void)0)

#endif /* __VA_MIPS_H */
