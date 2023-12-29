# cython: language_level=3, binding=True, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c

cdef public struct _fraction:
    double numerator # only numerator is ever negative
    double denominator

cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool

cdef extern from * nogil:
    '''
    #include <math.h>

    static inline double gcd1(double n1, double n2){
        if (n2){
            return gcd1(n2, fmod(n1, n2));
        }
        else{
            return n1;
        }
    }

    static double gcd(const double n1, const double n2){
        unsigned long long int i;
        double min = fabs(fabs(n2)-fabs(n1));
        double g =1;
        for(i=2; (i <= min); i++){
            if(!fmod(n2, i)){
                if (!fmod(n1, i)){
                    g = i;
                    break;
                }
            }
        }
        return 1/g;
    }
    static double inline c_n_pow(double n1, const double pow){
        double i;
        double x = n1;
        if (pow==0.0){
            return 1.0;
        }
        if (pow==1.0){
            return n1;
        }
        for (i=2.0;(i<=pow);i++){
            x = x*n1;
        }
        return x;
    }
    '''
    const double gcd(const double n1, const double n2) noexcept nogil
    const double c_n_pow(double n1, const double pow) noexcept nogil

cdef inline _fraction _n_power(_fraction first, double n) nogil:
    first.numerator = c_n_pow(first.numerator, n)
    first.denominator = c_n_pow(first.denominator, n)
    return first

cdef inline _Bool _eq_fractions(_fraction* first, _fraction* second)
    cdef _Bool b = first
cdef inline _fraction _cube(_fraction first) noexcept nogil:
    first.numerator = first.numerator*first.numerator*first.numerator
    first.denominator = first.denominator*first.denominator*first.denominator
    return first

cdef inline _fraction _square(_fraction first) noexcept nogil:
    first.numerator = first.numerator*first.numerator
    first.denominator = first.denominator*first.denominator
    return first

cdef inline _Bool _less_than_double(_fraction* first, double second) noexcept nogil:
    return (first.numerator) < (second*first.denominator)

cdef inline _Bool _greater_than_double(_fraction* first, double second) noexcept nogil:
    return (first.numerator) > (second*first.denominator)

cdef inline _fraction _div_fraction_double(_fraction first, double second) noexcept nogil:
    first.denominator = first.denominator*second
    first = _fix_num_den(&first)
    return first

cdef inline _fraction _mult_fraction_double(_fraction first, double second) noexcept nogil:
    first.numerator = first.numerator*second
    return first

cdef inline _fraction _add_fraction_double(_fraction first, double second) noexcept nogil: # first is the greater
    first.numerator = first.numerator+(second*first.denominator)
    return first

cdef inline _fraction _sub_fraction_double(_fraction first, double second) noexcept nogil: # first is the greater
    first.numerator = first.numerator-(second*first.denominator)
    return first

# top is double math

cdef inline _Bool _greater_than(_fraction* first, _fraction *second) noexcept nogil:
    return (first.numerator*(second).denominator) > ((second).numerator*first.denominator)

cdef inline _Bool _less_than(_fraction* first, _fraction *second) noexcept nogil:
    return (first.numerator*(second).denominator) < ((second).numerator*first.denominator)

cdef inline _fraction _simplify_fraction(_fraction* first) noexcept nogil:
    cdef double factor = gcd(first.numerator, first.denominator)
    first.numerator = first.numerator*factor
    first.denominator = first.denominator*factor
    return first[0]

cdef inline _fraction _negative(_fraction first) noexcept nogil:
    first.numerator = -first.numerator
    return first

cdef inline _fraction _reciprocal(_fraction first) noexcept nogil:
    cdef double temp = first.numerator
    first.numerator = first.denominator
    first.denominator = temp
    if temp < 0:
        first.numerator = -first.numerator
        first.denominator = -first.denominator
    return first

cdef inline _fraction _fix_num_den(_fraction* first) noexcept nogil:
    if (first.denominator < 0):
        first.denominator = -first.denominator
        first.numerator = -first.numerator
    return first[0]

cdef inline _fraction _mult_fractions(_fraction first, _fraction* second) noexcept nogil:
    first.numerator = first.numerator*second.numerator
    first.denominator = first.denominator*second.denominator
    return first

cdef inline _fraction _div_fractions(_fraction first, _fraction* second) noexcept nogil:
    first.numerator = first.numerator*second.denominator
    first.denominator = first.denominator*second.numerator
    first = _fix_num_den(&first)
    return first

cdef inline _fraction _add_fractions(_fraction first, _fraction* second) noexcept nogil: # first is the greater
    cdef double temp = first.denominator
    cdef double factor1 = (first.denominator*second.denominator)*gcd(first.denominator, second.denominator)  # easiest way tbh
    first.denominator=factor1
    first.numerator = (second.numerator*(factor1/second.denominator))+(first.numerator*(factor1/temp))
    first = _fix_num_den(&first)
    return first

cdef inline _fraction _sub_fractions(_fraction first, _fraction* second) noexcept nogil: # first is the greater
    second.numerator = -second.numerator

    return _add_fractions(first, second)

cdef inline double _as_double(_fraction* first) noexcept nogil:
    return first.numerator/first.denominator

cpdef inline _Bool greater_than(_fraction first, _fraction second) noexcept nogil:
    return _greater_than(&first, &second)

cpdef inline _Bool less_than(_fraction first, _fraction second) noexcept nogil:
    return _less_than(&first, &second)

cpdef inline _fraction simplify_fraction(_fraction first) noexcept nogil:
    return _simplify_fraction(&first)

cpdef inline _fraction negative(_fraction first) noexcept nogil:
    return _negative(first)

cpdef inline _fraction reciprocal(_fraction first) noexcept nogil:
    return _reciprocal(first)

cpdef inline _fraction fix_num_den(_fraction first) noexcept nogil:
    return _fix_num_den(&first)

cpdef inline _fraction mult_fractions(_fraction first, _fraction second) noexcept nogil:
    return _mult_fractions(first, &second)

cpdef inline _fraction div_fractions(_fraction first, _fraction second) noexcept nogil:
    return _div_fractions(first, &second)

cpdef inline _fraction add_fractions(_fraction first, _fraction second) noexcept nogil: # first is the greater
    return _add_fractions(first, &second)

cpdef inline _fraction sub_fractions(_fraction first, _fraction second) noexcept nogil: # first is the greater
    return _sub_fractions(first, &second)

cpdef inline double as_double(_fraction first) noexcept nogil:
    return _as_double(&first)

cpdef inline _Bool less_than_double(_fraction first, double second) noexcept nogil:
    return _less_than_double(&first, second)

cpdef inline _Bool greater_than_double(_fraction first, double second) noexcept nogil:
    return _greater_than_double(&first, second)

cpdef inline _fraction div_fraction_double(_fraction first, double second) noexcept nogil:
    return _div_fraction_double(first, second)

cpdef inline _fraction mult_fraction_double(_fraction first, double second) noexcept nogil:
    return _mult_fraction_double(first, second)

cpdef inline _fraction add_fraction_double(_fraction first, double second) noexcept nogil: # first is the greater
    return _add_fraction_double(first, second)

cpdef inline _fraction sub_fraction_double(_fraction first, double second) noexcept nogil: # first is the greater
    return _sub_fraction_double(first, second)

cpdef inline _fraction cube(_fraction first) noexcept nogil:
    return _cube(first)

cpdef inline _fraction square(_fraction first) noexcept nogil:
    return _square(first)

cdef inline _fraction n_power(_fraction first, double n) nogil:
    return _n_power(first, n)

cpdef inline dict fraction(double numerator, double denominator) noexcept:
    return {'numerator': numerator, 'denominator': denominator}