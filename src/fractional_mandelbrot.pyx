# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c

#center=(1.4,0)
from .fractions cimport _fraction, _mult_fraction_double, _div_fraction_double, _add_fraction_double, _sub_fraction_double, _greater_than, _greater_than_double, _less_than, _less_than_double, _square, _mult_fractions, _div_fractions, _add_fractions, _sub_fractions
from libc.stdio cimport puts,printf
from libc.stdlib cimport free, malloc
from libc.math cimport ceil as cround

cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool
    ctypedef _Bool bool
    const bool unlikely(bool T) noexcept nogil
    const bool likely(bool T) noexcept nogil

ctypedef fused ui_uc:
    unsigned char
    unsigned int

cdef inline ui_uc return_func(const bool cap, const ui_uc max) noexcept nogil:
    if cap:
        return <unsigned char>255
    else:
        return max

cdef inline ui_uc mandelbrot(const _fraction creal, const _fraction cimag, const ui_uc maxiter, const bool cap, const _fraction ratio) noexcept nogil:
    cdef _fraction real2, imag2
    cdef _fraction real = creal, imag = cimag
    cdef double n
    real2 = _square(creal)
    imag2 = _square(cimag)
    real2 = _add_fractions(real2, imag2)
    if _less_than(real2, _mult_fraction_double(imag2, 0.25)):
        return return_func(cap, maxiter)
    elif _greater_than_double(real2, 4.0):
        return 0
    for n in range(maxiter):
        real2 = _square(real)
        imag2 = _square(imag)
        if _greater_than_double(_add_fractions(real2, imag2),  4.0):
            if cap:
                return <unsigned char>cround(_as_double(_mult_fraction_double(ratio, n)))
            else:
                return n
        imag = _add_fractions(_mult_fraction_double(_mult_fractions(real, imag), 2), cimag)
        real = _add_fractions(_sub_fractions(real2, imag2), creal)
        if (imag == cimag) and (real == creal):
            return return_func(cap, maxiter)
    return return_func(cap, maxiter)

cdef inline void linspace(_fraction* arr, const unsigned int n, const _fraction start, const _fraction stop) noexcept nogil:
    cdef _fraction step = (stop-start)/n
    cdef unsigned int i
    cdef _fraction val = start
    for i in range(n):
        arr[i] = val
        val += step

cdef list ui_2_list(const unsigned int** arr, const unsigned int xlen, const unsigned int ylen) noexcept:
    cdef list l = []
    cdef list temp = []
    cdef unsigned int i,j
    for i in range(xlen):
        for j in range(ylen):
            temp.append(arr[i][j])
        l.append(temp.copy())
        free(arr[i])
        temp.clear()
    free(arr)
    return l

cdef list uc_2_list(const unsigned char** arr, const unsigned int xlen, const unsigned int ylen) noexcept:
    cdef list l = []
    cdef list temp = []
    cdef unsigned int i,j
    for i in range(xlen):
        for j in range(ylen):
            temp.append(arr[i][j])
        l.append(temp.copy())
        free(arr[i])
        temp.clear()
    free(arr)
    return l

cpdef public list main(const _fraction xmin, const _fraction xmax, const _fraction ymin, const _fraction ymax, const unsigned int width, const unsigned int height, const ui_uc maxiter, const bool cap) noexcept:
    cdef unsigned int i,j
    cdef unsigned int** arr = <unsigned int**>malloc(width * sizeof(unsigned int*))
    cdef unsigned char** arr1 = <unsigned char**>malloc(width * sizeof(unsigned char*))
    if not cap:
        free(arr1)
        for i in range(width):
            arr[i] = <unsigned int*>malloc(height * sizeof(unsigned int))
    else:
        free(arr)
        for i in range(width):
            arr1[i] = <unsigned char*>malloc(height * sizeof(unsigned char))

    cdef _fraction* r1 = <_fraction*>malloc(width*sizeof(_fraction))
    cdef _fraction* r2 = <_fraction*>malloc(height*sizeof(_fraction))
    cdef _fraction ratio = 0
    linspace(r1, width, xmin, xmax)
    linspace(r2, height, ymin, ymax)
    if cap:
        ratio = 255.0/maxiter
        for i in range(width):
            for j in range(height):
                arr1[i][j] = mandelbrot(r1[i], r2[j], maxiter, cap, ratio)
    else:
        for i in range(width):
            for j in range(height):
                arr[i][j] = mandelbrot(r1[i], r2[j], maxiter, False, 0)

    free(r2)
    free(r1)
    cdef list data
    if cap:
        data = uc_2_list(arr1,width, height)
    else:
        data = ui_2_list(arr,width, height)
    return data