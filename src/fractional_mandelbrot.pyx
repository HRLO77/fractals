# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True, CYTHON_USE_UNICODE_WRITER=True, CYTHON_UNPACK_METHODS=True, CYTHON_USE_PYLONG_INTERNALS=True, CYTHON_USE_PYLIST_INTERNALS=True, CYTHON_USE_UNICODE_INTERNALS=True, CYTHON_USE_PYTYPE_LOOKUP=True
# disutils: language=c

#center=(1.4,0)
from .fractions cimport _fraction, _mult_fraction_double, _div_fraction_double, _add_fraction_double, _sub_fraction_double, _greater_than_fraction, _greater_than_double, _less_than_fraction, _less_than_double, _square, _mult_fractions, _div_fractions, _add_fractions, _sub_fractions, _eq_fractions, _as_double, _set_num_den, _fracptr_2_frac, _free_frac, _frac_ptr, _simplify_fraction, _add_fraction_fraction_double, _mult_fraction_fraction_double, _sub_fraction_fraction_double, _div_fraction_fraction_double, _is_large
from libc.stdlib cimport free, malloc
from libc.math cimport ceil as cround
from cython.parallel cimport parallel, prange

cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool
    ctypedef _Bool bool
    const bool unlikely(bool T) nogil
    const bool likely(bool T) nogil

cdef unsigned int mandelbrot(const _fraction creal, const _fraction cimag, const unsigned int maxiter) noexcept nogil:
    cdef _fraction temp1, nreal, real = creal, imag = cimag
    cdef unsigned int n
    for n in range(maxiter):

        temp1 = _square(imag)
        nreal = _square(real)
        if _is_large(&temp1):
            _simplify_fraction(&temp1)
        if _is_large(&nreal):
            _simplify_fraction(&nreal)
        nreal = _sub_fractions(nreal, &temp1)
        if _is_large(&nreal):
            _simplify_fraction(&nreal)
        nreal = _add_fractions(nreal, &creal)  # nreal = (r^2 - i^2) + creal
        if _is_large(&nreal):
            _simplify_fraction(&nreal)
        
        temp1 = _mult_fraction_fraction_double(real, &imag, 2)
        if _is_large(&temp1):
            _simplify_fraction(&temp1)
        imag = _add_fractions(temp1, &cimag) # imag = temp2+cimag
        if _is_large(&imag):
            _simplify_fraction(&imag)
        real = nreal
        #if step_div!=1:
        #    if not(n%step_div):
        #        _simplify_fraction(&imag)
        #        _simplify_fraction(&nreal)
        #else:
        #    _simplify_fraction(&imag)
        #    _simplify_fraction(&nreal)
        
        #9223372036854775807
        
        temp1 = _square(imag) # temp1 = i^2
        nreal = _square(real)

        if _is_large(&temp1):
            _simplify_fraction(&temp1)

        if _is_large(&nreal):
            _simplify_fraction(&nreal)

        nreal = _add_fractions(nreal,&temp1) # temp2 = temp1+temp2

        if _is_large(&nreal):
            _simplify_fraction(&nreal)
            
        if _greater_than_double(&nreal,4):
            return n
        if _eq_fractions(&real, &creal, False, False):
            if _eq_fractions(&imag, &cimag, False, False):
                return maxiter
    return maxiter

cdef inline void linspace(_frac_ptr arr, const unsigned int n, const _fraction start, _fraction stop) noexcept nogil:
    stop = (_div_fraction_double(_sub_fractions(stop,&start), n))
    cdef unsigned int i
    cdef _fraction val = start
    for i in range(n):
        arr[i] = val
        val = _add_fractions(val, &stop)
        _simplify_fraction(&val)

cdef list ui_2_list(const unsigned int** arr, const unsigned int xlen, const unsigned int ylen) noexcept:
    cdef list l = []
    cdef unsigned int i,j
    for i in range(xlen):
        for j in range(ylen):
            l.append(arr[i][j])
        free(arr[i])
    free(arr)
    return l

cdef unsigned int** main1(unsigned int** arr, const _frac_ptr r1, const _frac_ptr r2, const unsigned int width, const unsigned int height, const unsigned int maxiter) noexcept nogil:
    cdef unsigned int i,j
    with parallel(num_threads=8):
        for i in prange(width, nogil=True, schedule='dynamic'):
            for j in prange(height, nogil=True, schedule='dynamic'):
                arr[i][j] = mandelbrot(r1[i], r2[j], maxiter)
    return arr

cpdef public list main(const _fraction xmin, const _fraction xmax, const _fraction ymin, const _fraction ymax, const unsigned int width, const unsigned int height, const unsigned int maxiter):
    cdef unsigned int i,j
    cdef unsigned int** arr = <unsigned int**>malloc(width * sizeof(unsigned int*))
    cdef _frac_ptr r1 = <_frac_ptr>malloc(width*sizeof(_fraction))
    cdef _frac_ptr r2 = <_frac_ptr>malloc(height*sizeof(_fraction))
    cdef list data
    for i in prange(width, nogil=True, schedule='dynamic', num_threads=8):
        arr[i] = <unsigned int*>malloc(height * sizeof(unsigned int))

    linspace(r1, width, xmin, xmax)
    linspace(r2, height, ymin, ymax)
    main1(arr,r1, r2, width, height, maxiter)

    free(r2)
    free(r1)
    data = ui_2_list(arr,width, height)
    return data