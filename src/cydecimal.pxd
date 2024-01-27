# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c

from libc.math cimport fabs, powf, fmod, floor, log10, ceil
from libc.stdlib cimport free, realloc, malloc, atoi as _atoi, atof as _atof, abs as cabs
from libc.string cimport memcpy, strcpy, strlen as _strlen, strrchr as _strrchr, strtok as _strtok, strcat as _strcat, strpbrk as _strpbrk, memset as _memset
from libc.stdio cimport printf, puts
# strtok is the first, strrchr is last
cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool
    ctypedef _Bool bool

cdef extern from * nogil:
    '''
#define N_DIGITS 5
#define N_PRECISION 85
#define N_DIGITS_I N_DIGITS-1
#define N_PRECISION_I N_PRECISION-1
#define MAX_INDICE N_DIGITS+N_PRECISION_I
#define MAX_LENGTH N_DIGITS+N_PRECISION

typedef char exponent_t;

struct _cydecimal {
    char digits[MAX_LENGTH];
    exponent_t exp; 
};

typedef struct _cydecimal* _cydecimal_ptr;
    
static struct _cydecimal inline _cydecimal_ptr_2_cydecimal(const _cydecimal_ptr ptr){
    return *ptr;
}
    '''
    const unsigned char N_DIGITS
    const unsigned char N_PRECISION
    const unsigned char N_DIGITS_I
    const unsigned char N_PRECISION_I
    const unsigned int MAX_INDICE
    const unsigned int MAX_LENGTH
    ctypedef short exponent_t

    cdef struct _cydecimal:
        char[MAX_LENGTH] digits
        exponent_t exp
        
    ctypedef _cydecimal* _cydecimal_ptr
    const _cydecimal _cydecimal_ptr_2_cydecimal(const _cydecimal_ptr ptr) noexcept nogil

cdef inline _cydecimal _new_decimal_from_string(const char* first) noexcept nogil

cdef inline void _empty_char_arr(char* first) noexcept nogil:
    _memset(first, 0, _strlen(first))  # very nice

cpdef inline _cydecimal new_decimal_from_string(const char* first) noexcept:
    cdef _cydecimal res
    res = _new_decimal_from_string(first)
    return res

cdef inline _cydecimal _new_decimal(const char[MAX_LENGTH]* digits) noexcept:
    cdef _cydecimal res
    memcpy(&res.digits, digits, sizeof(digits))
    return res

cpdef inline _cydecimal new_decimal(bytes digits) noexcept:
    cdef char[MAX_LENGTH] d = (<char*>digits)
    return _new_decimal(&d)

cdef inline _cydecimal _new_decimal_from_int(int first) noexcept nogil

cpdef inline _cydecimal new_decimal_from_int(int first) noexcept nogil:
    return _new_decimal_from_int(first)

cdef inline _cydecimal _new_decimal_from_large_double(const double first) noexcept nogil

cpdef inline _cydecimal new_decimal_from_large_double(const double first) noexcept nogil:
    return _new_decimal_from_large_double(first)

cdef inline void _destruct_decimal(_cydecimal_ptr first) noexcept nogil:
    free(first.digits)

cdef inline bool _greater_than_decimal(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:
    cdef unsigned int i
    for i in range(MAX_LENGTH):
        if first.digits[i] > second.digits[i]:
            return True
        elif first.digits[i] < second.digits[i]:
            return False
    return False  # equal

cpdef inline bool greater_than_decimal(const _cydecimal first, const _cydecimal second) noexcept nogil:
    return _greater_than_decimal(&first, &second)

cdef inline bool _eq_decimal(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:
    cdef unsigned int i
    for i in range(MAX_LENGTH):
        if first.digits[i] == second.digits[i]:
            continue
        else:
            return False
    return True  # equal

cpdef inline bool eq_decimal(const _cydecimal first, const _cydecimal second) noexcept nogil:
    return _eq_decimal(&first, &second)

cdef inline bool _less_than_decimal(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:
    cdef unsigned int i
    for i in range(MAX_LENGTH):
        if first.digits[i] < second.digits[i]:
            return True
        elif first.digits[i] > second.digits[i]:
            return False
    return False  # equal

cpdef inline bool less_than_decimal(const _cydecimal first, const _cydecimal second) noexcept nogil:
    return _less_than_decimal(&first, &second)

cdef inline _cydecimal _add_decimals(_cydecimal first, const _cydecimal_ptr second) noexcept nogil

cpdef inline _cydecimal add_decimals(_cydecimal first, const _cydecimal second) noexcept nogil:
    return _add_decimals(first, &second)

cdef inline _cydecimal _subtract_decimals(_cydecimal first, _cydecimal second) noexcept nogil

cpdef inline _cydecimal subtract_decimals(_cydecimal first, _cydecimal second) noexcept nogil:
    return _subtract_decimals(first, second)

cdef inline _cydecimal _mult_decimals(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept

cpdef inline _cydecimal mult_decimals(const _cydecimal first, const _cydecimal second) noexcept:
    return _mult_decimals(&first, &second)

cdef inline unsigned int _n_precision(const _cydecimal_ptr first) noexcept nogil:
    cdef unsigned int i, j=0, k=0
    cdef bool done = True
    for i in range(N_PRECISION):
        if (first.digits[i+N_DIGITS])==0 and done:
            j = i
            done=True
        elif done and i==0:
            done = False
        else:
            k = i
    return k-j+1

cdef inline unsigned int _n_full_digits(const _cydecimal_ptr first) noexcept nogil:
    cdef unsigned int i, j=0, k=0
    cdef bool done = True
    for i in range(N_DIGITS):
        if first.digits[i]==0 and done:
            j = i
            done=True
        elif done and i==0:
            done = False
        else:
            k = i
    return k-j+1

cdef inline unsigned int _n_digits(const _cydecimal_ptr first) noexcept nogil:
    cdef unsigned int i, j=0, k=0
    cdef bool done = True
    for i in range(MAX_INDICE):
        if first.digits[i]==0 and done:
            j = i
            done=True
        elif done and i==0:
            done = False
        else:
            k = i
    return k-j+1

cdef inline char* _dec_2_str(_cydecimal dec) noexcept nogil

cpdef inline bytes dec_2_str(_cydecimal dec) noexcept:
    return _dec_2_str(dec)
    
cpdef inline void test() except *:
    cdef _cydecimal test = _new_decimal_from_string((b'123.27'))
    cdef _cydecimal t = _new_decimal_from_string((b'312.86'))
    print(dec_2_str(test), len(test.digits))
    
    print(dec_2_str(t), len(test.digits))
    
    test = _mult_decimals(&test, &t)
    print(dec_2_str(test), len(test.digits))

    