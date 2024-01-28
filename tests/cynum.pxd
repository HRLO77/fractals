# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c

from libc.math cimport fabs, powf, fmod, floor, log10, ceil
from libc.stdlib cimport free, realloc, malloc, atoi as _atoi, atof as _atof, abs as cabs, abort as _abort, exit as _exit
from libc.string cimport memcpy, strcpy as _strcpy, strlen as _strlen, strrchr as _strrchr, strtok as _strtok, strcat as _strcat, strpbrk as _strpbrk, memset as _memset
from libc.stdio cimport printf, puts
# strtok is the first, strrchr is last
cdef extern from "<stdbool.h>" nogil:
    ctypedef bint _Bool
    ctypedef _Bool bool

cdef extern from * nogil:
    '''
typedef short exponent_t;
typedef unsigned short iterable_t;

#define N_DIGITS ((unsigned char)50)
#define N_PRECISION ((unsigned char)50)
#define N_DIGITS_I ((unsigned char)(N_DIGITS-1))
#define N_PRECISION_I ((unsigned char)(N_PRECISION-1))
#define MAX_INDICE ((iterable_t)(N_DIGITS+N_PRECISION_I))
#define MAX_LENGTH ((iterable_t)(N_DIGITS+N_PRECISION))



struct _cydecimal {
    char digits[MAX_LENGTH];
    exponent_t exp; 
};

typedef struct _cydecimal* _cydecimal_ptr;
    
static struct _cydecimal inline _cydecimal_ptr_2_cydecimal(const _cydecimal_ptr ptr){
    return *ptr;
}


static void inline _left_shift_digits(_cydecimal_ptr first, const iterable_t shift) {
    memcpy(first->digits, first->digits + shift, MAX_LENGTH - shift);
    memset(first->digits + MAX_LENGTH - shift, 0, shift);
    first->exp = ((first->exp)+shift);
}

static void inline _right_shift_digits(_cydecimal_ptr first, const iterable_t shift) {
    memcpy(first->digits + shift, first->digits, MAX_LENGTH - shift); // this will probably result in errors, switch with memmove if so
    memset(first->digits, 0, shift);
    first->exp = ((first->exp)-shift);
}

static void inline _program_error(char* err){
    err[strlen(err)-1] = 0;
    printf(err);
}
    '''
    ctypedef unsigned short iterable_t
    ctypedef short exponent_t
    const unsigned char N_DIGITS
    const unsigned char N_PRECISION
    const unsigned char N_DIGITS_I
    const unsigned char N_PRECISION_I
    const iterable_t MAX_INDICE
    const iterable_t MAX_LENGTH
    
    cdef struct _cydecimal:
        char[MAX_LENGTH] digits
        exponent_t exp
        
    ctypedef _cydecimal* _cydecimal_ptr
    const _cydecimal _cydecimal_ptr_2_cydecimal(const _cydecimal_ptr ptr) noexcept nogil
    const void _left_shift_digits(_cydecimal_ptr first, const iterable_t shift) noexcept nogil
    const void _right_shift_digits(_cydecimal_ptr first, const iterable_t shift) noexcept nogil
    const void _program_error(const char* err) noexcept nogil
    const bool unlikely(bool T) noexcept nogil
    const bool likely(bool T) noexcept nogil

cdef inline _cydecimal _norm_decimal_from_double(const double first) noexcept nogil

cdef inline _cydecimal _decimal_from_string(const char* first) noexcept nogil

cdef inline _cydecimal _norm_decimal_from_string(const char* first) noexcept nogil

cdef inline _cydecimal _decimal_from_int(int first) noexcept nogil

cdef inline _cydecimal _decimal_from_double(const double first) noexcept nogil

cdef inline _cydecimal _subtract_decimals(_cydecimal first, _cydecimal second) noexcept nogil

cdef inline _cydecimal _add_decimals(_cydecimal first, _cydecimal second) noexcept nogil

cdef inline void _empty_char_arr(char* first) noexcept nogil:
    _memset(first, 0, _strlen(first))  # very nice

cdef inline char* _dec_2_str(const _cydecimal_ptr dec) noexcept nogil

cdef inline _cydecimal _decimal(const char[MAX_LENGTH]* digits) noexcept nogil:
    cdef _cydecimal res
    memcpy(&res.digits, digits, sizeof(digits))
    return res

cdef inline void _destruct_decimal(_cydecimal_ptr first) noexcept nogil:
    free(first.digits)

cdef inline void _printf_dec(const _cydecimal_ptr dec) noexcept nogil:
    #cdef char* data = <char*>malloc(sizeof(char)*MAX_LENGTH+25)
    #cdef char* temp = data
    #data = _dec_2_str(dec)
    printf("%s\n",_dec_2_str(dec))
    #free(temp)

cdef inline bool _greater_than_digits(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:  # only checks digits in-order
    cdef iterable_t i
    for i in range(MAX_LENGTH):
        if first.digits[i] > second.digits[i]:
            return True
        elif first.digits[i] < second.digits[i]:
            return False
    return False  # equal

cdef inline bool _greater_than_exp(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:  # does NOT normalize digits,
    return first.exp > second.exp

cdef inline bool _true_greater_than(_cydecimal_ptr first, _cydecimal_ptr second) noexcept nogil:  # DOES normalize digits
    cdef iterable_t x
    if first.exp > second.exp:  # bring up second, without _normalize as we have to normalize after precision and leading zero normalization ANYWAY
        x = first.exp-second.exp
        _left_shift_digits(second, x)  # bring up value
    elif second.exp > first.exp:
        x = second.exp-first.exp
        _left_shift_digits(first, x)  # bring up value
    return _greater_than_digits(first, second)

cdef inline bool _eq_digits(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:  # only checks in-order
    cdef iterable_t i
    for i in range(MAX_LENGTH):
        if first.digits[i] == second.digits[i]:
            continue
        else:
            return False
    return True  # equal

cdef inline bool _eq_exp(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:  # does NOT normalize digits,
    return first.exp == second.exp

cdef inline bool _true_eq(_cydecimal_ptr first, _cydecimal_ptr second) noexcept nogil:  # DOES normalize digits
    cdef iterable_t x
    if first.exp > second.exp:  # bring up second, without _normalize as we have to normalize after precision and leading zero normalization ANYWAY
        x = first.exp-second.exp
        _left_shift_digits(second, x)  # bring up value
    elif second.exp > first.exp:
        x = second.exp-first.exp
        _left_shift_digits(first, x)  # bring up value
    else:
        return _eq_digits(first, second)
    return (first.exp == second.exp) and _eq_digits(first, second)

cdef inline bool _less_than_digits(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:  # only checks digits in-order
    cdef iterable_t i
    for i in range(MAX_LENGTH):
        if first.digits[i] < second.digits[i]:
            return True
        elif first.digits[i] > second.digits[i]:
            return False
    return False  # equal

cdef inline bool _less_than_exp(_cydecimal_ptr first, _cydecimal_ptr second) noexcept nogil:  # does NOT normalize digits
    return first.exp < second.exp

cdef inline bool _true_less_than(_cydecimal_ptr first, _cydecimal_ptr second) noexcept nogil:  # DOES normalize digits
    cdef iterable_t x
    if first.exp > second.exp:  # bring up second, without _normalize as we have to normalize after precision and leading zero normalization ANYWAY
        x = first.exp-second.exp
        _left_shift_digits(second, x)  # bring up value
    elif second.exp > first.exp:
        x = second.exp-first.exp
        _left_shift_digits(first, x)  # bring up value
    return _less_than_digits(first, second)

cdef inline iterable_t _n_precision(const _cydecimal_ptr first) noexcept nogil:
    cdef iterable_t i
    for i in range(MAX_INDICE, N_PRECISION_I-1, -1):
        if first.digits[i] != 0:
            return i-N_PRECISION_I
    return N_PRECISION  # all precision is taken up

cdef inline iterable_t _n_empty_zeros(const _cydecimal_ptr first) noexcept nogil:
    cdef iterable_t i  # warning: this function is not safe, just checks whole part, not decimal
    for i in range(N_DIGITS_I, -1, -1):  # essentially reversed _n_whole_digits
        if first.digits[i] != 0:
            return N_DIGITS-i
    return N_DIGITS  # none of whole part is take up

cdef inline iterable_t _n_digits(const _cydecimal_ptr first) noexcept nogil:
    return _n_precision(first)+_n_whole_digits(first) # lazy lmao

cdef inline iterable_t _n_whole_digits(const _cydecimal_ptr first) noexcept nogil:
    cdef iterable_t i
    for i in range(N_DIGITS):
        if first.digits[i] != 0:
            return N_DIGITS-i
    return N_DIGITS  # all whole part is taken up

cdef inline void _normalize_digits(_cydecimal_ptr first, const bool mode) noexcept nogil:
    cdef iterable_t i
    # mode==1 brings up decimal
    # mode==0 brings down exponent and mantissa if there are leading zeros (i.e after a mult)
    if mode:  # are there digits to the right of the decimal?
        i = _n_precision(first)
        _left_shift_digits(first, i)
        first.exp -= i  # move everything to full digits, change exponent
        return
    else:  # we wanna remove zeros at the end
        i = _n_empty_zeros(first)
        first.exp += i
        _right_shift_digits(first, i)
        return


cpdef inline _cydecimal new_decimal_from_string(const char* first) noexcept nogil:
    cdef _cydecimal res
    res = _decimal_from_string(first)
    return res

cpdef inline _cydecimal new_norm_decimal_from_string(const char* first) noexcept nogil:
    cdef _cydecimal res
    res = _norm_decimal_from_string(first)
    return res

cpdef inline _cydecimal norm_decimal_from_double(const double first) noexcept nogil:
    return _norm_decimal_from_double(first)

cpdef inline _cydecimal new_decimal_from_double(const double first) noexcept nogil:
    return _decimal_from_double(first)

cpdef inline _cydecimal new_decimal(bytes digits) noexcept:
    cdef char[MAX_LENGTH] d = <char*> digits
    return _decimal(&d)

cpdef inline _cydecimal new_decimal_from_int(int first) noexcept nogil:
    return _decimal_from_int(first)

cpdef inline _cydecimal normalize_digits(_cydecimal first, const bool mode) noexcept nogil:
    _normalize_digits(&first, mode)
    return first

cpdef inline _cydecimal right_shift_digits(_cydecimal first, const iterable_t num) noexcept nogil:
    _right_shift_digits(&first, num)
    return first

cpdef inline _cydecimal left_shift_digits(_cydecimal first, const iterable_t num) noexcept nogil:
    _left_shift_digits(&first, num)
    return first

cpdef inline bool greater_than_digits(const _cydecimal first, const _cydecimal second) noexcept nogil:
    return _greater_than_digits(&first, &second)

cpdef inline bool greater_than_exp(_cydecimal first, _cydecimal second) noexcept nogil:
    return _greater_than_exp(&first, &second)

cpdef inline bool true_greater_than(_cydecimal first, _cydecimal second) noexcept nogil:
    return _true_greater_than(&first, &second)

cpdef inline bool less_than_digits(const _cydecimal first, const _cydecimal second) noexcept nogil:
    return _less_than_digits(&first, &second)

cpdef inline bool less_than_exp(_cydecimal first, _cydecimal second) noexcept nogil:
    return _less_than_exp(&first, &second)

cpdef inline bool true_less_than(_cydecimal first, _cydecimal second) noexcept nogil:
    return _true_less_than(&first, &second)

cpdef inline bool eq_digits(const _cydecimal first, const _cydecimal second) noexcept nogil:
    return _eq_digits(&first, &second)


cpdef inline bool eq_exp(_cydecimal first, _cydecimal second) noexcept nogil:
    return _eq_exp(&first, &second)

cpdef inline bool true_eq(_cydecimal first, _cydecimal second) noexcept nogil:
    return _true_eq(&first, &second)

cpdef inline _cydecimal add_decimals(_cydecimal first, _cydecimal second) noexcept nogil:
    return _add_decimals(first, second)

cpdef inline _cydecimal subtract_decimals(_cydecimal first, _cydecimal second) noexcept nogil:
    return _subtract_decimals(first, second)

cpdef inline int n_precision(const _cydecimal first) noexcept nogil:
    return _n_precision(&first)

cpdef inline int n_digits(const _cydecimal first) noexcept nogil:
    return _n_digits(&first)

cpdef inline int n_whole_digits(const _cydecimal first) noexcept nogil:
    return _n_whole_digits(&first)

cpdef inline bytes dec_2_str(_cydecimal dec) noexcept:
    return _dec_2_str(&dec)

cpdef inline void printf_dec(const _cydecimal dec) noexcept nogil:
    _printf_dec(&dec)

cpdef inline void test() noexcept nogil:
    cdef _cydecimal test = _norm_decimal_from_string((b'1251.18239'))
    cdef iterable_t i
    #_printf_dec(&test)
    #_printf_dec(&test1)
    test = _subtract_decimals(test, test)
    #_printf_dec(&test)
    # -578.996009