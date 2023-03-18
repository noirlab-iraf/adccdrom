# FVEXPR common.

pointer	fv_oval				# pointer to expr value operand
int	fv_getop			# user supplied get operand procedure
int	fv_ufcn				# user supplied function call procedure

common	/xfvcom/ fv_oval, fv_getop, fv_ufcn
