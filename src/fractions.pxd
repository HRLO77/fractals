# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True, CYTHON_USE_UNICODE_WRITER=True, CYTHON_UNPACK_METHODS=True, CYTHON_USE_PYLONG_INTERNALS=True, CYTHON_USE_PYLIST_INTERNALS=True, CYTHON_USE_UNICODE_INTERNALS=True, CYTHON_USE_PYTYPE_LOOKUP=True
# disutils: language=c


from libc.stdlib cimport malloc, free
from libc.math cimport fma
from libc.math cimport fabs
cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool

'''cdef extern from "immintrin.h" nogil:
    ctypedef double __m256d
    const double _mm256_mul_pd(const double a, const double b) noexcept nogil
    const double _mm256_add_pd(const double a, const double b) noexcept nogil
    const double _mm256_div_pd(const double a, const double b) noexcept nogil
    const double _mm256_sub_pd(const double a, const double b) noexcept nogil
    const double _mm256_cmp_pd(const double a, const double b, const int imm8) noexcept nogil
    const double _mm256_cmpeq_pd(const double a, const double b) noexcept nogil
    const double _mm256_fmadd_pd(const double a, const double b, const double c) noexcept nogil
    const double _mm256_fmsub_pd (const double a, const double b, const double c) noexcept nogil
    const double _mm256_fmod_pd(const double a, const double b) noexcept nogil
# Function using AVX2 for double multiplication

cdef inline double fma_avx(__m256d x, double y, double z) noexcept nogil:
    return _mm256_fmadd_pd(x, y, z)

cdef inline double multiply_avx(__m256d x, double y) noexcept nogil:
    return _mm256_mul_pd(x, y)

# Function using AVX2 for double addition
cdef inline double add_avx(__m256d x, double y) noexcept nogil:
    return _mm256_add_pd(x, y)

# Function using AVX2 for double division
cdef inline double divide_avx(__m256d x, double y) noexcept nogil:
    return _mm256_div_pd(x, y)

# Function using AVX2 for double subtraction
cdef inline double subtract_avx(__m256d x, double y) noexcept nogil:
    return _mm256_sub_pd(x, y)

# Function using AVX2 for double comparison
cdef inline double _less_than_double(__m256d x, double y) noexcept nogil:
    return _mm256_cmp_pd(x, y, 1)

# Function using AVX2 for double comparison
cdef inline double _greater_than_double(__m256d x, double y) noexcept nogil:
    return _mm256_cmp_pd(x, y, 14)

# Function using AVX2 for double equality comparison
cdef inline double equal_avx(__m256d x, double y) noexcept nogil:
    return _mm256_cmp_pd(x, y, 0)'''

cdef extern from * nogil:
    '''
#include <math.h>

struct _fraction {
    double numerator;
    double denominator;
};

typedef struct _fraction* _frac_ptr;

#define MAX_DOUBLE 1.79769313486231570e+308d
#define MIN_DOUBLE 2.2250738585072014E-308d
#define LARGE_DOUBLE 1E+50
#define ONE_THIRD 1/3

static inline bool _is_large(const _frac_ptr ptr){
    return (fabs(ptr->numerator) > LARGE_DOUBLE) || ((ptr->denominator) > LARGE_DOUBLE);
}

static inline double gcd(const double n1, const double n2) {
    if (n2) {
        return gcd(n2, fmod(n1, n2));
    } else {
        return 1/(double)n1;
    }
}

static double inline c_n_pow(const double n1, const double pow) {
    double i;
    double x = n1;
    if (pow == 0) {
        return 1;
    }
    if (pow == 1) {
        return n1;
    }
    for (i = 2; (i <= pow); i++) {
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
    const double MAX_DOUBLE
    const double MIN_DOUBLE
    const double LARGE_DOUBLE
    const double ONE_THIRD
    const _fraction _fracptr_2_frac(const _frac_ptr ptr) noexcept nogil # converts an _frac_ptr type to _fraction.
    const double gcd(const double n1, const double n2) noexcept nogil  # finds the gcd of two __m256ds
    const _Bool _is_large(const _frac_ptr first) noexcept nogil  # is the fractional components large?
    const double c_n_pow(const double n1, const double pow) noexcept nogil  # raises n1 to pow

cdef inline void _free_frac(_frac_ptr first) noexcept nogil:
    free(first)

cdef inline _frac_ptr _alloc_frac(const double numerator, const double denominator) noexcept nogil:
    cdef _frac_ptr res = <_frac_ptr>malloc(sizeof(_fraction))
    res.numerator=numerator
    res.denominator=denominator
    return res

# above is memory, below is misc and fraction and long long int/double math

cdef inline void _set_num_den(_frac_ptr first, const double numerator, const double denominator) noexcept nogil:
    first.numerator = numerator
    first.denominator = denominator

cdef inline _fraction _n_power(_fraction first, const double n) noexcept nogil:
    first.numerator = c_n_pow(first.numerator, n)
    first.denominator = c_n_pow(first.denominator, n)
    return first

cdef inline _Bool _eq_fraction_double(const _frac_ptr first, const double second) noexcept nogil:
    return first.numerator == (second*first.denominator)

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
    first.numerator = fma(second, first.denominator, first.numerator)
    return first

cdef inline _fraction _sub_fraction_double(_fraction first, const double second) noexcept nogil: # first is the greater
    first.numerator = fma(-second, first.denominator, first.numerator)
    return first

cdef inline _fraction _reciprocal_double(const double first) noexcept nogil:
    cdef _fraction res = _fraction(numerator=1, denominator=first)
    if res.denominator < 0:
        res.numerator = -res.numerator
        res.denominator = -res.denominator
    return res

# underneath is fraction fraction double math, top is double math

cdef inline _fraction _mult_fraction_fraction_double(_fraction first, const _frac_ptr second, const double third) noexcept nogil:
    first.numerator = (first.numerator*second.numerator*third)
    first.denominator = first.denominator*second.denominator
    return first

cdef inline _fraction _div_fraction_fraction_double(_fraction first, const _frac_ptr second, const double third) noexcept nogil:
    first.numerator = (first.numerator*second.denominator)
    first.denominator = (first.denominator*second.numerator*third)
    _fix_num_den(&first)
    return first

cdef inline _fraction _sub_fraction_fraction_double(_fraction first, const _frac_ptr second, const double third) noexcept nogil: # first is the greater
    # 1/3 - 2/5 - 2/1
    # 3-1280/640
    #cdef double factor1 = (first.denominator*second.denominator)#*gcd(first.denominator, second.denominator)  # TODO
    first.numerator = fma(-third*first.denominator, second.denominator,fma(first.numerator,(second.denominator),fma((-second.numerator),(first.denominator),0)))
    first.denominator=(first.denominator*second.denominator)
    _fix_num_den(&first)
    return first

cdef inline _fraction _add_fraction_fraction_double(_fraction first, const _frac_ptr second, const double third) noexcept nogil: # first is the greater
    # 1/3 + 2/5 + 2/1
    # 3-1280/640
    #cdef double factor1 = (first.denominator*second.denominator)#*gcd(first.denominator, second.denominator)  # TODO
    first.numerator = fma(third*first.denominator, second.denominator,fma(first.numerator,(second.denominator),fma((second.numerator),(first.denominator),0)))
    first.denominator=(first.denominator*second.denominator)
    _fix_num_den(&first)
    return first

# above is fraction fraction double math, below is fraction fraction math

cdef inline _Bool _eq_fractions(const _frac_ptr first, const _frac_ptr second, const _Bool div, const _Bool multiples) noexcept nogil:
    cdef _Bool b
    if div:
        b = _as_double(first)==_as_double(second)
    else:
        b = first.numerator==second.numerator and first.denominator==second.denominator
        if (not b) and multiples:
            b = ((first.numerator*second.denominator) == (first.denominator*second.numerator))
    return b

cdef inline _fraction _cube(_fraction first) noexcept nogil:
    first.numerator = first.numerator*first.numerator*first.numerator
    first.denominator = first.denominator*first.denominator*first.denominator
    return first

cdef inline _fraction _square(_fraction first) noexcept nogil:
    first.numerator = fma(first.numerator, first.numerator, 0)
    first.denominator = fma(first.denominator, first.denominator, 0)
    return first

cdef inline _Bool _greater_than_fraction(const _frac_ptr first, const _frac_ptr second) noexcept nogil:
    return ((second).numerator*first.denominator) < (first.numerator*(second).denominator)

cdef inline _Bool _less_than_fraction(const _frac_ptr first, const _frac_ptr second) noexcept nogil:
    return ((second).numerator*first.denominator) > (first.numerator*(second).denominator)

cdef inline void _simplify_fraction(_frac_ptr first) noexcept nogil:
    cdef double factor = gcd(fabs(first.numerator) if first.numerator > first.denominator else first.denominator, fabs(first.numerator-first.denominator))
    first.numerator = fma(first.numerator,factor,0)
    first.denominator = fma(first.denominator,factor,0)

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

cdef inline _fraction _add_fractions(_fraction first, const _frac_ptr second) noexcept nogil: # first is the greater
    # -2/1 + 3/640
    # 3-1280/640
    #cdef double factor1 = (first.denominator*second.denominator)#*gcd(first.denominator, second.denominator)  # easiest way tbh
    first.numerator = fma(first.numerator,(second.denominator),fma((second.numerator),(first.denominator),0))
    first.denominator=(first.denominator*second.denominator)
    _fix_num_den(&first)
    return first

cdef inline _fraction _sub_fractions(_fraction first, _frac_ptr second) noexcept nogil: # first is the greater
    first.numerator = fma(first.numerator,(second.denominator),(fma((-second.numerator),(first.denominator),0)))
    first.denominator = first.denominator*second.denominator
    _fix_num_den(&first)
    return first

cdef inline double _as_double(const _frac_ptr first) noexcept nogil:
    #printf("Im being __m256dd %f %f\n", first.numerator, first.denominator)
    return <double>first.numerator/<double>first.denominator

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
    
cpdef inline _Bool is_large(const _fraction first) noexcept nogil:
    return _is_large(&first)

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

cdef inline _fraction mult_fraction_fraction_double(_fraction first, const _fraction second, const double third) noexcept nogil:
    return _mult_fraction_fraction_double(first, &second, third)

cpdef inline _fraction div_fraction_fraction_double(_fraction first, const _fraction second, const double third) noexcept nogil:
    return _div_fraction_fraction_double(first, &second, third)

cpdef inline _fraction sub_fraction_fraction_double(_fraction first, const _fraction second, const double third) noexcept nogil: # first is the greater
    return _sub_fraction_fraction_double(first, &second, third)

cpdef inline _fraction add_fraction_fraction_double(_fraction first, const _fraction second, const double third) noexcept nogil: # first is the greater
    return _add_fraction_fraction_double(first, &second, third)

cpdef inline dict fraction(const double numerator, const double denominator) noexcept:
    return {"numerator":numerator, "denominator":denominator}