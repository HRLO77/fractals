# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True, CYTHON_USE_UNICODE_WRITER=True, CYTHON_UNPACK_METHODS=True, CYTHON_USE_PYLONG_INTERNALS=True, CYTHON_USE_PYLIST_INTERNALS=True, CYTHON_USE_UNICODE_INTERNALS=True, CYTHON_USE_PYTYPE_LOOKUP=True
# disutils: language=c

#center=(1.4,0)
from .cynum cimport _square_decimal, _mult_decimals, _subtract_decimals, _add_decimals, _abs_dec, _printf_dec, _dec_2_str, _left_shift_digits, _right_shift_digits, _normalize_digits, _empty_decimal, _cydecimal, _cydecimal_ptr, _mult_decimal_decimal_digit, _true_greater_than, _true_eq, _decimal_from_double, MAX_LENGTH, MAX_INDICE, N_DIGITS, N_PRECISION, N_DIGITS_I, N_PRECISION_I, _is_zero, dec_2_str, _close_zero, _n_whole_digits, _norm_decimal_from_string, _eq_digits
from libc.stdio cimport printf
from libc.stdlib cimport free, malloc
from libc.math cimport ceil as cround
from cython.parallel cimport parallel, prange

cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool
    ctypedef _Bool bool


cdef _cydecimal FOUR = _decimal_from_double(4.0)
cdef _cydecimal TWO = _decimal_from_double(2.0)

cdef unsigned int mandelbrot( _cydecimal creal,  _cydecimal cimag, const unsigned int maxiter, unsigned int testi, unsigned int testj) except *:
    cdef _cydecimal temp1, real = creal, imag = cimag, real2, imag2
    cdef unsigned int n
    for n in range(maxiter):

        real2 = _square_decimal(real) # x^2 + y^2

        imag2 = _square_decimal(imag)

        temp1 = _add_decimals(real2, imag2) # x^2 + y^2 > 4


        #if (_is_zero(&real2) and _is_zero(&imag2)):
        #    return maxiter

        if _true_greater_than(temp1,FOUR):
            return n


        imag = _add_decimals(_mult_decimals(TWO, _mult_decimals(real, imag)), cimag) # y = (2*x*y)+cimag
        real = _add_decimals(_subtract_decimals(real2, imag2), creal) # x = (x^2 - y^2) + creal

        if _true_eq(real, creal):
            if _true_eq(imag, cimag):
                return maxiter
    return maxiter

cdef inline void linspace(_cydecimal_ptr arr, const unsigned int n, _cydecimal n_recip, _cydecimal start, _cydecimal stop) except * nogil:
    cdef _cydecimal temp
    stop = _subtract_decimals(stop,start)
    temp = (_mult_decimals(stop, n_recip))
    cdef unsigned int i
    for i in range(n):
        arr[i] = start
        start = _add_decimals(start, temp)

cdef list ui_2_list(const unsigned int** arr, const unsigned int xlen, const unsigned int ylen) except *:
    cdef list l = []
    cdef list k = []
    cdef unsigned int i,j
    for i in range(xlen):
        for j in range(ylen):
            k.append(arr[i][j])
        l.append(k)
        k = []
        free(arr[i])
    free(arr)
    return l

cdef unsigned int** main1(unsigned int** arr, const _cydecimal_ptr r1, const _cydecimal_ptr r2, const unsigned int width, const unsigned int height, const unsigned int maxiter) except * :
    cdef unsigned int i,j
    #with parallel(num_threads=8):
    #    for i in prange(width, nogil=True, schedule='dynamic'):
    #        for j in prange(height, nogil=True, schedule='dynamic'):
    #            arr[i][j] = mandelbrot(r1[i], r2[j], maxiter)
    for i in range(width):
        for j in range(height):
            arr[i][j] = mandelbrot(r1[i], r2[j], maxiter,i, j)
        if i%5==0:
            printf("%d\r", i)
    return arr

cdef public list main(const _cydecimal xmin, const _cydecimal xmax, const _cydecimal ymin, const _cydecimal ymax, const _cydecimal x_recip, const _cydecimal y_recip, const unsigned int width, const unsigned int height, const unsigned int maxiter) except *:
    cdef unsigned int i,j
    cdef unsigned int** arr = <unsigned int**>malloc(width * sizeof(unsigned int*))
    cdef _cydecimal_ptr r1 = <_cydecimal_ptr>malloc(width*sizeof(_cydecimal))
    cdef _cydecimal_ptr r2 = <_cydecimal_ptr>malloc(height*sizeof(_cydecimal))
    cdef list data
    for i in prange(width, nogil=True, schedule='dynamic', num_threads=8):
        arr[i] = <unsigned int*>malloc(height * sizeof(unsigned int))
    linspace(r1, width, x_recip, xmin, xmax)
    linspace(r2, height, y_recip, ymin, ymax)
    main1(arr,r1, r2, width, height, maxiter)
    free(r2)
    free(r1)
    data = ui_2_list(arr,width, height)
    return data