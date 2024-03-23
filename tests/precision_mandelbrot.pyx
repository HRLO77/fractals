# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True, CYTHON_USE_UNICODE_WRITER=True, CYTHON_UNPACK_METHODS=True, CYTHON_USE_PYLONG_INTERNALS=True, CYTHON_USE_PYLIST_INTERNALS=True, CYTHON_USE_UNICODE_INTERNALS=True, CYTHON_USE_PYTYPE_LOOKUP=True
# disutils: language=c

#center=(1.4,0)
from .cynum cimport _square_decimal, _mult_decimals, _subtract_decimals, _add_decimals, _abs_dec, _printf_dec, _dec_2_str, _left_shift_digits, _right_shift_digits, _normalize_digits, _empty_decimal, _cydecimal, _cydecimal_ptr, _mult_decimal_decimal_digit, _true_greater_than, _true_eq, _decimal_from_double, MAX_LENGTH, MAX_INDICE, N_DIGITS, N_PRECISION, N_DIGITS_I, N_PRECISION_I

from libc.stdlib cimport free, malloc
from libc.math cimport ceil as cround
from cython.parallel cimport parallel, prange

cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool
    ctypedef _Bool bool


cdef _cydecimal FOUR = _empty_decimal()
cdef _cydecimal TWO = _empty_decimal()
FOUR.digits[N_DIGITS_I] = 4  # i sure hope this is fast!
TWO.digits[N_DIGITS_I] = 2

cdef unsigned int mandelbrot(const _cydecimal creal, const _cydecimal cimag, const unsigned int maxiter) except * nogil:
    cdef _cydecimal temp1, nreal, real = creal, imag = cimag
    cdef unsigned int n
    for n in range(maxiter):

        temp1 = _square_decimal(&imag)
        nreal = _square_decimal(&real)
        nreal = _add_decimals(nreal, temp1)
        nreal = _add_decimals(nreal, creal)  # nreal = (r^2 - i^2) + creal
        
        temp1 = _mult_decimals(&real, &imag)
        temp1 = _mult_decimals(&temp1, &TWO)
        real = nreal
        #if step_div!=1:
        #    if not(n%step_div):
        #        _simplify_cydecimal(&imag)
        #        _simplify_cydecimal(&nreal)
        #else:
        #    _simplify_cydecimal(&imag)
        #    _simplify_cydecimal(&nreal)
        
        #9223372036854775807
        
        temp1 = _square_decimal(&imag) # temp1 = i^2
        nreal = _square_decimal(&real)


        nreal = _add_decimals(nreal,temp1) # temp2 = temp1+temp2

        if _true_greater_than(&nreal,&FOUR):
            return n
        if _true_eq(&real, &creal):
            if _true_eq(&imag, &cimag):
                return maxiter
    return maxiter

cdef inline void linspace(_cydecimal_ptr arr, const unsigned int n, const _cydecimal_ptr n_recip, _cydecimal start, _cydecimal stop) except * nogil:
    stop = _subtract_decimals(stop,start)
    stop = (_mult_decimals(&stop, n_recip))
    cdef unsigned int i
    for i in range(n):
        arr[i] = start
        start = _add_decimals(start, stop)

cdef list ui_2_list(const unsigned int** arr, const unsigned int xlen, const unsigned int ylen) except *:
    cdef list l = []
    cdef unsigned int i,j
    for i in range(xlen):
        for j in range(ylen):
            l.append(arr[i][j])
        free(arr[i])
    free(arr)
    return l

cdef unsigned int** main1(unsigned int** arr, const _cydecimal_ptr r1, const _cydecimal_ptr r2, const unsigned int width, const unsigned int height, const unsigned int maxiter) except * nogil:
    cdef unsigned int i,j
    with parallel(num_threads=8):
        for i in prange(width, nogil=True, schedule='dynamic'):
            for j in prange(height, nogil=True, schedule='dynamic'):
                arr[i][j] = mandelbrot(r1[i], r2[j], maxiter)
    return arr

cdef public list main(const _cydecimal xmin, const _cydecimal xmax, const _cydecimal ymin, const _cydecimal ymax, const _cydecimal n_recip, const unsigned int width, const unsigned int height, const unsigned int maxiter):
    print('in function')
    cdef unsigned int i,j
    cdef unsigned int** arr = <unsigned int**>malloc(width * sizeof(unsigned int*))
    cdef _cydecimal_ptr r1 = <_cydecimal_ptr>malloc(width*sizeof(_cydecimal))
    cdef _cydecimal_ptr r2 = <_cydecimal_ptr>malloc(height*sizeof(_cydecimal))
    cdef list data
    for i in prange(width, nogil=True, schedule='dynamic', num_threads=8):
        arr[i] = <unsigned int*>malloc(height * sizeof(unsigned int))

    print('started allocation')
    linspace(r1, width, &n_recip, xmin, xmax)
    linspace(r2, height, &n_recip, ymin, ymax)
    print('done allocation')
    main1(arr,r1, r2, width, height, maxiter)
    print('done allocation1')
    free(r2)
    free(r1)
    data = ui_2_list(arr,width, height)
    return data