from libc.stdio cimport puts,printf
from libc.stdlib cimport free, malloc
from gmpy2 cimport import_gmpy2, get_context, mpfr
import_gmpy2()

get_context().precision = 105

cdef mpfr = mpfr("2.5", 105)

