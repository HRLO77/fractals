# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c

#center=(1.4,0)
from .fractions cimport _fraction, _mult_fraction_double, _div_fraction_double, _add_fraction_double, _sub_fraction_double, _greater_than, _greater_than_double, _less_than, _less_than_double, _square, _mult_fractions, _div_fractions, _add_fractions, _sub_fractions, _eq_fractions, _as_double, _set_num_den, _frac_2_fracptr, _fracptr_2_frac, _free_frac, _frac_ptr
from libc.stdio cimport puts,printf
from libc.stdlib cimport free, malloc
from libc.math cimport ceil as cround

cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool
    ctypedef _Bool bool
    const bool unlikely(bool T) nogil
    const bool likely(bool T) nogil

ctypedef fused ui_uc:
    unsigned char
    unsigned int

cdef inline ui_uc return_func(const bool cap, const ui_uc max) nogil:
    if cap:
        return <unsigned char>255
    else:
        return max

cdef inline ui_uc mandelbrot(const _fraction creal, const _fraction cimag, const ui_uc maxiter, const bool cap, const _fraction ratio) nogil:
    cdef _fraction real2, imag2
    cdef _fraction real = creal, imag = cimag
    cdef unsigned int n
    real2 = _square(creal)
    imag2 = _square(cimag)
    real2 = _add_fractions(real2, &imag2)
    if _less_than(&real2, _frac_2_fracptr(_mult_fraction_double(imag2, 0.25))):
        return return_func(cap, maxiter)
    elif _greater_than_double(&real2, 4.0):
        return 0
    for n in range(maxiter):
        real2 = _square(real)
        imag2 = _square(imag)
        if _greater_than_double(_frac_2_fracptr(_add_fractions(real2, &imag2)),  4.0):
            if cap:
                return <unsigned char>cround(_as_double(_frac_2_fracptr(_mult_fraction_double(ratio, n))))
            else:
                return n
        imag = _add_fractions(_mult_fraction_double(_mult_fractions(real, &imag), 2), &cimag)
        real = _add_fractions(_sub_fractions(real2, &imag2), &creal)
        if _eq_fractions(&imag,&cimag,False) and _eq_fractions(&imag,&cimag, False):
            return return_func(cap, maxiter)
    return return_func(cap, maxiter)

cdef inline void linspace(_frac_ptr arr, const unsigned int n, const _fraction start, const _fraction stop) nogil:
    cdef _frac_ptr step = _frac_2_fracptr(_div_fraction_double(_sub_fractions(stop,&start), n))
    cdef unsigned int i
    cdef _fraction val = start
    for i in range(n):
        arr[i] = val
        val = _add_fractions(val, step)

cdef list ui_2_list(const unsigned int** arr, const unsigned int xlen, const unsigned int ylen):
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

cdef list uc_2_list(const unsigned char** arr, const unsigned int xlen, const unsigned int ylen):
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

cpdef public list main(const _fraction xmin, const _fraction xmax, const _fraction ymin, const _fraction ymax, const unsigned int width, const unsigned int height, const ui_uc maxiter, const bool cap):
    cdef unsigned int i,j
    cdef unsigned int** arr = <unsigned int**>malloc(width * sizeof(unsigned int*))
    cdef _frac_ptr r1 = <_frac_ptr>malloc(width*sizeof(_fraction))
    cdef _frac_ptr r2 = <_frac_ptr>malloc(height*sizeof(_fraction))
    cdef _fraction ratio = _fraction(numerator=1, denominator=1)
    cdef unsigned char** arr1 = <unsigned char**>malloc(width * sizeof(unsigned char*))
    cdef list data
    try:
        if not cap:
            free(arr1)
            for i in range(width):
                arr[i] = <unsigned int*>malloc(height * sizeof(unsigned int))
        else:
            free(arr)
            for i in range(width):
                arr1[i] = <unsigned char*>malloc(height * sizeof(unsigned char))


        linspace(r1, width, xmin, xmax)
        linspace(r2, height, ymin, ymax)
        if cap:
            _set_num_den(&ratio, 255, maxiter)
            for i in range(width):
                for j in range(height):
                    arr1[i][j] = mandelbrot(r1[i], r2[j], maxiter, True, ratio)
        else:
        
            for i in range(width):
                for j in range(height):
                    arr[i][j] = mandelbrot(r1[i], r2[j], maxiter, False, ratio)

        free(r2)
        free(r1)
        if cap:
            data = uc_2_list(arr1,width, height)
        else:
            data = ui_2_list(arr,width, height)
    except BaseException as e:
        print(f'\n\n{e}\n\n')
    return data