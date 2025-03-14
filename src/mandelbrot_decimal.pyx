# cython: language_level=3

#center=(1.4,0)

from libc.stdio cimport puts,printf
from libc.stdlib cimport free, malloc
from libc.math cimport ceil as cround
import decimal
decimal.getcontext().prec = 85

cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool
    ctypedef _Bool bool
    const bool unlikely(bool T) noexcept nogil
    const bool likely(bool T) noexcept nogil


#cdef object quarter = decimal.Decimal('0.25')
cdef object four = decimal.Decimal('4')
cdef object two = decimal.Decimal('2')

cdef inline unsigned int mandelbrot(object creal, object cimag, const unsigned int maxiter) noexcept:
    cdef object real2, imag2
    cdef object real = creal, imag = cimag
    cdef unsigned int n
    #real2 = creal*creal 
    #imag2 = cimag*cimag
    #real2 = real2+imag2
    #if (real2) <= quarter * imag2:
    #    return maxiter
    #elif real2 >= four:
    #    return 0

    for n in range(maxiter):
        real2 = real*real
        imag2 = imag*imag
        if real2 + imag2 > four:
            return n
        imag = two* real*imag + cimag
        real = real2 - imag2 + creal
        #if (imag == cimag):
        #    if (real==creal):
        #        return maxiter
    return maxiter

cdef unsigned int** main1(unsigned int** arr, list[object] r1, list[object] r2, const unsigned int width, const unsigned int height, const unsigned int maxiter) noexcept:
    cdef unsigned int i,j
    for i in range(width):
        for j in range(height):
            arr[i][j] = mandelbrot(r1[i], r2[j], maxiter)
    return arr

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

cdef inline list[object] linspace(list[object] arr, object n, object start, object stop) noexcept:
    cdef object step = (stop-start)/(decimal.Decimal(<object>n))
    cdef unsigned int i
    cdef object val = start
    for i in range(n):
        arr[i] = val
        val += step
    return arr

cpdef public list run(object xmin, object xmax, object ymin, object ymax, const unsigned int width, const unsigned int height, const unsigned int maxiter) noexcept:
    cdef unsigned int i,j
    cdef unsigned int** arr = <unsigned int**>malloc(width * sizeof(unsigned int*))
    for i in range(width):
        arr[i] = <unsigned int*>malloc(height * sizeof(unsigned int))
    cdef list r1 = [0 for i in range(width)]
    cdef list r2 = [0 for i in range(height)]
    r1 = linspace(r1, width, xmin, xmax)
    r2 = linspace(r2, height, ymin, ymax)
    main1(arr, r1, r2, width, height, maxiter)
    del r1
    del r2
    return ui_2_list(arr, width, height)