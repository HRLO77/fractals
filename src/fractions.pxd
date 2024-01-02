# cython: language_level=3, binding=True, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c


from libc.stdlib cimport malloc, free
from libc.stdio cimport printf
cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool

cdef extern from * nogil:
    '''
#include <math.h>
#include <stdio.h>

struct _fraction {
    double numerator;
    double denominator;
};

typedef struct _fraction* _frac_ptr;

static inline double gcd(const double n1, const double n2) {
    if (n2) {
        return gcd(n2, fmod(n1, n2));
    } else {
        return 1/n1;
    }
}

static double gcd1(const double n1, const double n2) {
    double i;
    double min = fabs(fabs(n1) - fabs(n2));
    double g = 1;
    if ((n1 == 1 || n2 == 0) || (n1 == 0 || n2 == 0)) {
        return 1;
    }
    for (i = 1; (i <= min); i++) {
        if (!fmod(n2, i)) {
            if (!fmod(n1, i)) {
                g = i;
                break;
            }
        }
    }
    return 1 / g;
}

static double inline c_n_pow(double n1, const double pow) {
    double i;
    double x = n1;
    if (pow == 0.0) {
        return 1.0;
    }
    if (pow == 1.0) {
        return n1;
    }
    for (i = 2.0; (i <= pow); i++) {
        x = x * n1;
    }
    return x;
}

static struct _fraction inline _fracptr_2_frac(const _frac_ptr ptr) {
    return *ptr;
}
    '''
    cdef struct _fraction:
        double numerator # only numerator is ever negative
        double denominator
    ctypedef (_fraction*) _frac_ptr  # typedef
    const _fraction _fracptr_2_frac(const _frac_ptr ptr) noexcept nogil # converts an _frac_ptr type to _fraction.
    const double gcd(const double n1, const double n2) noexcept nogil  # finds the gcd of two doubles
    const double c_n_pow(double n1, const double pow) noexcept nogil  # raises n1 to pow

cdef inline void _free_frac(_frac_ptr first) noexcept nogil:
    free(first)

cdef inline _frac_ptr _alloc_frac(const double numerator, const double denominator) noexcept nogil:
    cdef _frac_ptr res = <_frac_ptr>malloc(sizeof(_fraction))
    res.numerator=numerator
    res.denominator=denominator
    return res

cdef inline void _set_num_den(_frac_ptr first, const double numerator, const double denominator) noexcept nogil:
    first.numerator = numerator
    first.denominator = denominator

cdef inline _fraction _n_power(_fraction first, const double n) noexcept nogil:
    first.numerator = c_n_pow(first.numerator, n)
    first.denominator = c_n_pow(first.denominator, n)
    return first

cdef inline _Bool _eq_fractions(const _frac_ptr first, const _frac_ptr second, const _Bool div, const _Bool multiples) noexcept nogil:
    cdef _Bool b
    if div:
        b = _as_double(first)==_as_double(second)
    else:
        b = first.numerator==second.numerator and first.denominator==second.denominator
        if (not b) and multiples:
            b = ((first.numerator*second.denominator) == (first.denominator*second.numerator))
    return b

cdef inline _Bool _eq_fraction_double(const _frac_ptr first, const double second) noexcept nogil:
    return first.numerator == (second*first.denominator)

cdef inline _fraction _cube(_fraction first) noexcept nogil:
    first.numerator = first.numerator*first.numerator*first.numerator
    first.denominator = first.denominator*first.denominator*first.denominator
    return first

cdef inline _fraction _square(_fraction first) noexcept nogil:
    first.numerator = first.numerator*first.numerator
    first.denominator = first.denominator*first.denominator
    return first

cdef inline _Bool _less_than_double(const _frac_ptr first, const double second) noexcept nogil:
    return (first.numerator) < (second*first.denominator)

cdef inline _Bool _greater_than_double(const _frac_ptr first, const double second) noexcept nogil:
    return (first.numerator) > (second*first.denominator)

cdef inline _fraction _div_fraction_double(_fraction first, const double second) noexcept nogil:
    first.denominator = (first.denominator*second)
    _fix_num_den(&first)
    return first

cdef inline _fraction _mult_fraction_double(_fraction first, const double second) noexcept nogil:
    first.numerator = (first.numerator*second)
    return first

cdef inline _fraction _add_fraction_double(_fraction first, const double second) noexcept nogil: # first is the greater
    first.numerator = (first.numerator+(second*first.denominator))
    return first

cdef inline _fraction _sub_fraction_double(_fraction first, const double second) noexcept nogil: # first is the greater
    first.numerator = (first.numerator-(second*first.denominator))
    return first

cdef inline _fraction _reciprocal_double(const double first) noexcept nogil:
    cdef _fraction res = _fraction(numerator=1, denominator=first)
    if res.denominator < 0:
        res.numerator = -res.numerator
        res.denominator = -res.denominator
    return res
# top is double math

cdef inline _Bool _greater_than_fraction(const _frac_ptr first, const _fraction *second) noexcept nogil:
    return ((second).numerator*first.denominator) < (first.numerator*(second).denominator)

cdef inline _Bool _less_than_fraction(const _frac_ptr first, const _fraction *second) noexcept nogil:
    return ((second).numerator*first.denominator) > (first.numerator*(second).denominator)

cdef inline void _simplify_fraction(_frac_ptr first) noexcept nogil:
    cdef double factor = gcd(first.numerator, first.denominator)
    first.numerator = first.numerator*factor
    first.denominator = first.denominator*factor

cdef inline _fraction _negative(_fraction first) noexcept nogil:
    first.numerator = -first.numerator
    return first

cdef inline _fraction _reciprocal_fraction(_fraction first) noexcept nogil:
    cdef double temp = first.numerator
    first.numerator = first.denominator
    first.denominator = temp
    if temp < 0:
        first.numerator = -first.numerator
        first.denominator = -first.denominator
    return first

cdef inline void _fix_num_den(_frac_ptr first) noexcept nogil:
    if (first.denominator < 0):
        first.denominator = -first.denominator
        first.numerator = -first.numerator

cdef inline _fraction _mult_fractions(_fraction first, const _frac_ptr second) noexcept nogil:
    first.numerator = first.numerator*second.numerator
    first.denominator = first.denominator*second.denominator
    return first

cdef inline _fraction _div_fractions(_fraction first, const _frac_ptr second) noexcept nogil:
    first.numerator = first.numerator*second.denominator
    first.denominator = first.denominator*second.numerator
    _fix_num_den(&first)
    return first
#{'numerator': -2.0, 'denominator': 1.0} {'numerator': 3.0, 'denominator': 640.0
cdef inline _fraction _add_fractions(_fraction first, const _frac_ptr second) noexcept nogil: # first is the greater
    # -2/1 + 3/640
    # 3-1280/640
    #cdef double factor1 = (first.denominator*second.denominator)#*gcd(first.denominator, second.denominator)  # easiest way tbh
    first.numerator = (second.numerator*(first.denominator))+(first.numerator*(second.denominator))
    first.denominator=(first.denominator*second.denominator)
    _fix_num_den(&first)
    return first

cdef inline _fraction _sub_fractions(_fraction first, _frac_ptr second) noexcept nogil: # first is the greater
    first.numerator = (first.numerator*(second.denominator))-(second.numerator*(first.denominator))
    first.denominator = first.denominator*second.denominator
    _fix_num_den(&first)
    return first

cdef inline double _as_double(const _frac_ptr first) noexcept nogil:
    #printf("Im being doubled %f %f\n", first.numerator, first.denominator)
    return first.numerator/first.denominator

cpdef inline _Bool greater_than_fraction(const _fraction first, const _fraction second) noexcept nogil:
    return _greater_than_fraction(&first, &second)

cpdef inline _Bool less_than_fraction(const _fraction first, const _fraction second) noexcept nogil:
    return _less_than_fraction(&first, &second)

cpdef inline _fraction simplify_fraction(_fraction first) noexcept nogil:
    _simplify_fraction(&first)
    return first

cpdef inline _fraction negative(_fraction first) noexcept nogil:
    return (_negative(first))

cpdef inline _fraction reciprocal_double(const double first) noexcept nogil:
    return (_reciprocal_double(first))

cpdef inline _fraction reciprocal_fraction(_fraction first) noexcept nogil:
    return (_reciprocal_fraction(first))

cpdef inline _fraction fix_num_den(_fraction first) noexcept nogil:
    _fix_num_den(&first)
    return first
    
cpdef inline _fraction mult_fractions(_fraction first, const _fraction second) noexcept nogil:
    return ((_mult_fractions(first, &second)))

cpdef inline _fraction div_fractions(_fraction first, const _fraction second) noexcept nogil:
    return (_div_fractions(first, &second))

cpdef inline _fraction add_fractions(_fraction first, const _fraction second) noexcept nogil: # first is the greater
    return (_add_fractions(first, &second))

cpdef inline _fraction sub_fractions(_fraction first, _fraction second) noexcept nogil: # first is the greater
    return (_sub_fractions(first, &second))

cpdef inline double as_double(const _fraction first) noexcept nogil:
    return _as_double(&first)

cpdef inline _Bool less_than_double(const _fraction first, const double second) noexcept nogil:
    return _less_than_double(&first, second)

cpdef inline _Bool greater_than_double(const _fraction first, const double second) noexcept nogil:
    return _greater_than_double(&first, second)

cpdef inline _fraction div_fraction_double(_fraction first, const double second) noexcept nogil:
    return (_div_fraction_double(first, second))

cpdef inline _fraction mult_fraction_double(_fraction first, const double second) noexcept nogil:
    return (_mult_fraction_double(first, second))

cpdef inline _fraction add_fraction_double(_fraction first, const double second) noexcept nogil: # first is the greater
    return (_add_fraction_double(first, second))

cpdef inline _fraction sub_fraction_double(_fraction first, const double second) noexcept nogil: # first is the greater
    return (_sub_fraction_double(first, second))

cpdef inline _fraction cube(_fraction first) noexcept nogil:
    return (_cube(first))

cpdef inline _fraction square(_fraction first) noexcept nogil:
    return (_square(first))

cpdef inline _fraction n_power(_fraction first, const double n) noexcept nogil:
    return (_n_power(first, n))

cpdef inline _Bool eq_fractions(const _fraction first, const _fraction second, const _Bool div, const _Bool multiples) noexcept nogil:
    return _eq_fractions(&first, &second, div, multiples)

cpdef inline _Bool eq_fraction_double(const _fraction first, const double second) noexcept nogil:
    return _eq_fraction_double(&first, second)

cpdef inline void set_num_den(_fraction first, const double numerator, const double denominator) noexcept nogil:
    _set_num_den(&first, numerator, denominator)

cpdef inline dict fraction(const double numerator, const double denominator) noexcept:
    return {"numerator":numerator, "denominator":denominator}