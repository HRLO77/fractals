# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True, CYTHON_USE_UNICODE_WRITER=True, CYTHON_UNPACK_METHODS=True, CYTHON_USE_PYLONG_INTERNALS=True, CYTHON_USE_PYLIST_INTERNALS=True, CYTHON_USE_UNICODE_INTERNALS=True, CYTHON_USE_PYTYPE_LOOKUP=True
# disutils: language=c

#center=(1.4,0)
from .cynum cimport _square_decimal, _mult_decimals, _subtract_decimals, _add_decimals, _abs_dec, _printf_dec, _dec_2_str, _left_shift_digits, _right_shift_digits, _normalize_digits, _empty_decimal, _cydecimal, _cydecimal_ptr, _mult_decimal_decimal_digit, _true_greater_than, _true_eq, _decimal_from_double, MAX_LENGTH, MAX_INDICE, N_DIGITS, N_PRECISION, N_DIGITS_I, N_PRECISION_I, _is_zero, dec_2_str, _close_zero, _n_whole_digits, _norm_decimal_from_string, _eq_digits, _round_decimal, exponent_t 
from libc.stdio cimport printf
from libc.stdlib cimport free, malloc
from libc.math cimport ceil as cround
from cython.parallel cimport parallel, prange

cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool
    ctypedef _Bool bool
#if testi==368 and testj==66:

cdef _cydecimal FOUR = _decimal_from_double(4.0)
cdef _cydecimal TWO = _decimal_from_double(2.0)
FOUR.exp=0
TWO.exp=0

cdef unsigned int mandelbrot( _cydecimal creal,  _cydecimal cimag, const unsigned int maxiter, const unsigned int testi, const unsigned int testj, const int IMAG_ZERO_IND) noexcept nogil:
    cdef _cydecimal temp1, real = creal, imag = cimag, real2, imag2
    cdef unsigned int n
    cdef exponent_t comparision = (-(<exponent_t>MAX_INDICE))+5
    #Re: -0.16    - it 368
    #Im: -1.0304  - it 66

    for n in range(maxiter):

        #if testi==354 and testj==225:
        #    print(dec_2_str(real), dec_2_str(imag), 'ITERATION', n)
        real2 = _square_decimal(real) # x^2 + y^2
        #if testi==3 and testj==250:
        #   print('CONT', dec_2_str(real), 'ITERATION', n, testi, testj, IMAG_ZERO_IND)
        

        if IMAG_ZERO_IND==-1:
            imag2 = _square_decimal(imag)
            temp1 = _add_decimals(real2, imag2) # x^2 + y^2 > 4
        elif IMAG_ZERO_IND==testj:
            temp1=real2

        else:
            
            imag2 = _square_decimal(imag)
            temp1 = _add_decimals(real2, imag2) # x^2 + y^2 > 4
        #if testi==354 and testj==225 and n==121:
         #   print(dec_2_str(real2), dec_2_str(imag2), 'ITEARTION', n)
        #if (_is_zero(&real2) and _is_zero(&imag2)):
        #    return maxiter

        if _true_greater_than(temp1,FOUR):
            #if testi==205 and testj==221:
            #    print('out', dec_2_str(real), dec_2_str(imag))
            return n
        # so, seems like there is NO BUG here (compared to complex type code)
        #    print('subbed', dec_2_str(_subtract_decimals(real2, imag2)))
        
        # something possibly incorrect in imag mult

        if IMAG_ZERO_IND==-1:
            imag = _add_decimals(_mult_decimals(_mult_decimals(real, imag), TWO), cimag) # y = (2*x*y)+cimag
            #if testi==205 and testj==221:
            #    print('got past this part')
            real = _add_decimals(_subtract_decimals(real2, imag2), creal) # x = (x^2 - y^2) + creal
        elif (testj==IMAG_ZERO_IND):
            # leave imag as zero
            real = _add_decimals(real2, creal)
        else:
            imag = _add_decimals(_mult_decimals(_mult_decimals(real, imag), TWO), cimag) # y = (2*x*y)+cimag
            #if testi==354 and testj==225:
            #    print('test far', dec_2_str(real2), dec_2_str(imag2), 'ITERATION', n)
            #if testi==205 and testj==221:
            #    print('got past this part')
            real  = _subtract_decimals(real2, imag2)
            #if testi==354 and testj==225 and n==121:
            #    print(dec_2_str(real), dec_2_str(creal), 'ITTTTT', n)
            real = _add_decimals(real, creal) # x = (x^2 - y^2) + creal
        #if testi==354 and testj==225:
        #    print('no this far', 'ITERATION', n)

        if (imag.exp < comparision):
            _round_decimal(&imag, 1)
        if (real.exp < comparision):
            _round_decimal(&real, 1)

        if _true_eq(real, creal):
            if _true_eq(imag, cimag):
                return maxiter
    #if testi==205 and testj==221:
    #    print('exited the loop')
    return maxiter

cdef inline int linspace(_cydecimal_ptr arr, const unsigned int n, _cydecimal n_recip, _cydecimal start, _cydecimal stop, const bool globe)nogil:
    cdef int res=-1
    cdef _cydecimal temp
    stop = _subtract_decimals(stop,start)
    temp = (_mult_decimals(stop, n_recip))
    cdef int i
    for i in range(n):
        arr[i] = start
        start = _add_decimals(start, temp)
        _normalize_digits(&start, False)
        if globe:
            if _is_zero(&start):
                res=(i)+1
    return res
    
cdef list ui_2_list(unsigned int** arr, const unsigned int xlen, const unsigned int ylen):
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

cdef unsigned int** main1(unsigned int** arr, const _cydecimal_ptr r1, const _cydecimal_ptr r2, const unsigned int width, const unsigned int height, const unsigned int maxiter, const int IMAG_ZERO_IND) noexcept nogil:
    cdef unsigned int i,j
    with parallel(num_threads=6):
        for i in prange(width, nogil=True, schedule='guided'):
            for j in prange(height, nogil=True, schedule='dynamic'):
                arr[i][j] = mandelbrot(r1[i], r2[j], maxiter, i, j, IMAG_ZERO_IND)
            printf("%d\r", i)#204, 257
    #for i in range(width):
    #    for j in range(height):
    #        arr[i][j] = mandelbrot(r1[i], r2[j], maxiter, i, j, IMAG_ZERO_IND)
    #        printf("%d %d\n", i, j)
    return arr

cdef public list main(const _cydecimal xmin, const _cydecimal xmax, const _cydecimal ymin, const _cydecimal ymax, const _cydecimal x_recip, const _cydecimal y_recip, const unsigned int width, const unsigned int height, const unsigned int maxiter) noexcept:
    cdef unsigned int i,j
    cdef unsigned int** arr = <unsigned int**>malloc(width * sizeof(unsigned int*))
    cdef _cydecimal_ptr r1 = <_cydecimal_ptr>malloc(width*sizeof(_cydecimal))
    cdef _cydecimal_ptr r2 = <_cydecimal_ptr>malloc(height*sizeof(_cydecimal))
    cdef list data
    #for i in prange(width, nogil=True, schedule='dynamic', num_threads=8):
    for i in range(width):
        arr[i] = <unsigned int*>malloc(height * sizeof(unsigned int))
    cdef int IMAG_ZERO_IND = -1
    linspace(r1, width, x_recip, xmin, xmax, False)
    IMAG_ZERO_IND = linspace(r2, height, y_recip, ymin, ymax, True)
    printf('made it this far\n')
    main1(arr,r1, r2, width, height, maxiter, IMAG_ZERO_IND)
    free(r2)
    free(r1)
    data = ui_2_list(arr,width, height)
    return data

'''
Re: -0.16    - it 368
Im: -1.0304  - it 66
'''