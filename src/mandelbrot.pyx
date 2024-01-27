# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c

#center=(1.4,0)

from libc.stdio cimport puts,printf
from libc.stdlib cimport free, malloc
from libc.math cimport ceil as cround
from cython.parallel cimport parallel, prange

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

cdef inline ui_uc mandelbrot(const long double creal, const long double cimag, const ui_uc maxiter, const bool cap, const long double ratio) noexcept nogil:
    cdef long double real2, imag2
    cdef long double real = creal, imag = cimag
    cdef unsigned int n
    real2 = creal*creal 
    imag2 = cimag*cimag
    real2 = real2+imag2
    if (real2) <= 0.25 * imag2:
        return return_func(cap, maxiter)
    elif real2 >= 4.0:
        return 0
    for n in range(maxiter):
        real2 = real*real
        imag2 = imag*imag
        if real2 + imag2 > 4.0:
            if cap:
                return <unsigned char>cround(n*ratio)
            else:
                return n
        imag = 2* real*imag + cimag
        real = real2 - imag2 + creal
        if (imag == cimag) and (real == creal):
            return return_func(cap, maxiter)
    return return_func(cap, maxiter)

cdef inline void linspace(long double* arr, const unsigned int n, const long double start, const long double stop) noexcept nogil:
    cdef long double step = (stop-start)/n
    cdef unsigned int i
    cdef long double val = start
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

cdef unsigned int** main1(unsigned int** arr, const long double* r1, const long double* r2, const unsigned int width, const unsigned int height, const unsigned int maxiter, const bool cap, const long double ratio,) noexcept nogil:
    cdef unsigned int i,j
    with parallel():
        for i in prange(width, nogil=True):
            for j in prange(height, nogil=True):
                arr[i][j] = mandelbrot(r1[i], r2[j], maxiter, cap, ratio)
    return arr

cdef unsigned char** main2(unsigned char** arr, const long double* r1, const long double* r2, const unsigned int width, const unsigned int height, const unsigned int maxiter, const bool cap, const long double ratio,) noexcept nogil:
    cdef unsigned int i,j
    with parallel():
        for i in prange(width, nogil=True):
            for j in prange(height, nogil=True):
                arr[i][j] = mandelbrot(r1[i], r2[j], maxiter, cap, ratio)
    return arr

cpdef public list main(const long double xmin, const long double xmax, const long double ymin, const long double ymax, const unsigned int width, const unsigned int height, const ui_uc maxiter, const bool cap) noexcept:
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

    cdef long double* r1 = <long double*>malloc(width*sizeof(long double))
    cdef long double* r2 = <long double*>malloc(height*sizeof(long double))
    cdef long double ratio = 0
    linspace(r1, width, xmin, xmax)
    linspace(r2, height, ymin, ymax)
    if cap:
        ratio = 255.0/maxiter
        main2(arr1, r1, r2, width, height, maxiter, cap, ratio)
    else:
        main1(arr, r1, r2, width, height, maxiter, cap, ratio)

    free(r2)
    free(r1)
    cdef list data
    if cap:
        data = uc_2_list(arr1,width, height)
    else:
        data = ui_2_list(arr,width, height)
    return data