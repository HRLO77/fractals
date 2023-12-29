# cython: language_level=3, binding=True, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c
from .fractions cimport _mult_fractions, _add_fractions, _fraction, _div_fractions
from time import perf_counter
cpdef public inline double test() noexcept:
    cdef _fraction temp = _fraction(numerator=1, denominator=1)
    print(temp)

    cdef _fraction f = _fraction(numerator=1341234, denominator=23567652)
    temp = _mult_fractions(f, &f)
    print(temp)

    temp = _add_fractions(temp, &f)
    print(temp)

    f = _div_fractions(temp, &temp)
    print(temp)