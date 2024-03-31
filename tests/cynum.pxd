# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c

from libc.math cimport fabs, powf, fmod, floor, log10, ceil
from libc.stdlib cimport free, realloc, malloc, atoi as _atoi, atof as _atof, abs as cabs, abort as _abort, exit as _exit
from libc.string cimport memcpy, strcpy as _strcpy, strlen as _strlen, strrchr as _strrchr, strtok as _strtok, strcat as _strcat, strpbrk as _strpbrk, memset as _memset
from libc.stdio cimport printf, puts
from cython.operator cimport preincrement, postincrement, dereference, predecrement, postdecrement

# strtok is the first, strrchr is last
cdef extern from "<stdbool.h>" nogil:
    ctypedef bint bool

cdef extern from * nogil:
    '''

typedef short exponent_t; //  formerly short
typedef unsigned short iterable_t;  // formerly ushort

#define N_DIGITS ((iterable_t)50)
#define N_PRECISION ((iterable_t)50)
#define N_DIGITS_I ((iterable_t)(N_DIGITS-1))
#define MAX_INDICE ((iterable_t)(N_DIGITS+N_PRECISION-1))
#define MAX_LENGTH ((iterable_t)(N_DIGITS+N_PRECISION))
#define N_PRECISION_I ((N_DIGITS_I))
#define CAPITAL_E 'E'
#define ZERO '0'
#define PERIOD '.'
#define NEGATIVE '-'
#define TERMINATOR '\0'


struct _cydecimal {
    char digits[MAX_LENGTH];
    exponent_t exp; 
    bool negative;
};

typedef struct _cydecimal* _cydecimal_ptr;

static bool inline _greater_than_char(const char first[MAX_LENGTH], const char second[MAX_LENGTH]){
    iterable_t i;
    char x, y;
    for (i=0;i<MAX_LENGTH;i++){
        x = first[i];
        y = second[i];
        if (x > y){
            return true;
        }
        else if(x < y){
            return false;
        };
    };
    return false;
}

static bool inline _less_than_char(const char first[MAX_LENGTH], const char second[MAX_LENGTH]){
    iterable_t i;
    char x, y;
    for (i=0;i<MAX_LENGTH;i++){
        x = first[i];
        y = second[i];
        if (x < y){
            return true;
        }
        else if(x > y){
            return false;
        };
    };
    return false;
}

static bool inline _eq_char(const char first[MAX_LENGTH], const char second[MAX_LENGTH]){
    iterable_t i;
    char x, y;
    for (i=0;i<MAX_LENGTH;i++){
        x = first[i];
        y = second[i];
        if (x!=y){
            return false;
        };
    };
    return true;
}

static void inline _right_shift_digits( _cydecimal_ptr first, exponent_t shift);

static void inline _left_shift_digits( _cydecimal_ptr first, exponent_t shift) {
    if (shift < 0){
        _right_shift_digits(first, abs(shift));
        return;
    }
    memmove(first->digits, first->digits + shift, MAX_LENGTH - shift);
    memset(first->digits + MAX_LENGTH - shift, 0, shift);
    first->exp -= (shift);
}

static void inline _right_shift_digits( _cydecimal_ptr first, exponent_t shift) {
    if (shift < 0){
        _left_shift_digits(first, abs(shift));
        return;
    }
    memmove(first->digits + shift, first->digits, MAX_LENGTH - shift); // this will probably result in errors, switch with memmove if so
    memset(first->digits, 0, shift);
    first->exp += (shift);
}

static void inline _program_error(char* err){
    err[strlen(err)-1] = 0;
    printf(err);
}

static inline struct _cydecimal _decimal(const char digits[MAX_LENGTH], const exponent_t exp, const bool negative){
    struct _cydecimal res;
    memcpy(&res.digits, digits, sizeof(digits));
    res.exp = exp;
    res.negative=negative;
    return res;
}

static inline void _destruct_decimal(_cydecimal_ptr first){
    free(first->digits);
}

static char* _dec_2_str(const _cydecimal_ptr dec) {
    char* string = (char*)malloc((MAX_LENGTH + 20) * sizeof(char));
    exponent_t i, x = 0;
    iterable_t temp = abs(dec->exp);
    iterable_t temp2;
    if (temp != 0) {
        temp2 = (iterable_t)floor(log10((double)temp) + 1);
    } else {
        temp2 = 1;
    }
    if (dec->negative){
        string[0] = NEGATIVE;
        x++;
    }
    for (i = 0; i < MAX_LENGTH; i++) {
        if (i == N_DIGITS) {
            string[i + x] = PERIOD;  // .
            x++;
        }
        string[i + x] = dec->digits[i] + '0';
        //} else {
        //
        //    string[i + x] = -(dec->digits[i]) + '0';
        //}
    }

    string[MAX_LENGTH + x] = CAPITAL_E; // from here, working on exp
    x++;
    if (temp != 0) {
        if (dec->exp < 0) {
            string[MAX_LENGTH + x] = NEGATIVE;
            x++;
        }

        for (i = temp2; i > 0; i--) {
            string[MAX_LENGTH + x + i-1] = (temp % 10) + '0';
            temp = (iterable_t)(temp*0.1);
        }

    } else {
        string[MAX_LENGTH + x] = ZERO;
    }

    string[MAX_LENGTH + temp2 + x] = TERMINATOR;
    return string;
}

static void _printf_dec(const _cydecimal_ptr dec){
    printf("%s\\n", _dec_2_str(dec));
}

static inline bool _greater_than_digits(const struct _cydecimal first, const struct _cydecimal second){
    if ((!first.negative) && (second.negative)){
        return true;
    }
    else if ((first.negative) && (!second.negative)){
        return false;
    }
    iterable_t i;
    for (i = 0; i < MAX_LENGTH; i++) {
        if (first.digits[i] > second.digits[i]) {
            return (first.negative) ? false : true;
        } else if (first.digits[i] < second.digits[i]) {
            return (first.negative) ? true : false;
        }
    }
    return false;
}

static inline bool _greater_than_exp(const struct _cydecimal first, const struct _cydecimal second){
    return first.exp > second.exp;
}

static inline bool _true_greater_than(struct _cydecimal first, struct _cydecimal second){
    if ((!first.negative) && (second.negative)){// if first is positive & second is negative
        return true;
    }
    else if ((first.negative) && (!second.negative)){ // if first is negative and second is positive :)
        return false;
    }

    if (first.exp > second.exp) { // minimize exp i.e BRING DIGITS TO THE LEFT OF THE DECIMAL
        _left_shift_digits(&first, first.exp - second.exp);
    } else if (second.exp > first.exp) {
        _left_shift_digits(&second, second.exp - first.exp);
    }
    return _greater_than_digits(first, second);
}

static inline bool _eq_digits(const struct _cydecimal first, const struct _cydecimal second){
    iterable_t i;
    if (first.negative != second.negative){
        return false;
    }
    for (i = 0; i < MAX_LENGTH; i++) {
        if (first.digits[i] != second.digits[i]) {
            return false;
        }
    }
    return true;
}

static inline bool _eq_exp(const struct _cydecimal first, const struct _cydecimal second){
    return first.exp == second.exp;
}

static inline bool _true_eq(struct _cydecimal first, struct _cydecimal second){
    if (first.exp > second.exp) {
        _left_shift_digits(&first, first.exp - second.exp);
    } else if (second.exp > first.exp) {
        _left_shift_digits(&second, second.exp - first.exp);
    } else {
        return _eq_digits(first, second);
    }
    return (first.exp == second.exp) && _eq_digits(first, second);
}

static inline bool _less_than_digits(const struct _cydecimal first, const struct _cydecimal second){
    if ((!first.negative) && (second.negative)){
        return false;
    }
    else if ((first.negative) && (!second.negative)){
        return true;
    }
    iterable_t i;
    for (i = 0; i < MAX_LENGTH; i++) {
        if (first.digits[i] < second.digits[i]) {
            return (first.negative) ? false : true;
        } else if (first.digits[i] > second.digits[i]) {
            return (first.negative) ? true : false;
        }
    }
    return false;
}

static inline bool _less_than_exp(const struct _cydecimal first, const struct _cydecimal second){
    return first.exp < second.exp;
}

static inline bool _true_less_than(struct _cydecimal first, struct _cydecimal second){
    if ((!first.negative) && (second.negative)){
        return false;
    }
    else if ((first.negative) && (!second.negative)){
        return true;
    }
    if (first.exp > second.exp) {
        _left_shift_digits(&first, first.exp - second.exp);
    } else if (second.exp > first.exp) {
        _left_shift_digits(&second, second.exp - first.exp);
    }
    return _less_than_digits(first, second);
}

static inline iterable_t _n_precision(const _cydecimal_ptr first){
    iterable_t i;
    for (i = MAX_INDICE; i >= N_PRECISION_I; i--) {
        if (first->digits[i] != 0) {
            return i - N_PRECISION_I;
        }
    }
    return 0;
}

static inline iterable_t _n_empty_zeros(const _cydecimal_ptr first){
    iterable_t i;
    for (i = N_DIGITS; i > 0; i--) {
        if (first->digits[i-1] != 0) {
            return N_DIGITS - i;
        }
    }
    return N_DIGITS;
}

static inline iterable_t _n_whole_digits(const _cydecimal_ptr first){
    iterable_t i;
    for (i = 0; i < N_DIGITS; i++) {
        if (first->digits[i] != 0) {
            return N_DIGITS - i;
        }
    }
    return N_DIGITS;
}

static inline iterable_t _n_digits(const _cydecimal_ptr first){
    return (iterable_t)(_n_precision(first)) + (iterable_t)(_n_whole_digits(first));
}

static inline void _normalize_digits(_cydecimal_ptr first, const bool mode){
    exponent_t i;
     if (mode) {
        i = _n_precision(first);
        if (i !=0){_left_shift_digits(first, i);};
        return;
    } else {
        i = _n_empty_zeros(first);
        if (i!=0){_right_shift_digits(first, i);};
        return;
    }
}

static inline void _empty_char_arr(char first[MAX_LENGTH]){
    memset(first, 0, MAX_LENGTH);
}
static inline struct _cydecimal _empty_decimal(){
    struct _cydecimal res = {(char*)malloc(MAX_LENGTH*sizeof(char)), 0, false};
    memset(&res.digits, 0, MAX_LENGTH);
    return res;
}

static inline struct _cydecimal _abs_dec(struct _cydecimal first){
    first.negative = false;
    return first;
}

static inline void _negate(_cydecimal_ptr first){
    first->negative = !(first->negative);
}

static inline char _close_zero(const _cydecimal_ptr first){
    exponent_t temp;
    if (first->exp < -(MAX_INDICE)){ // may lose a digit of precision :/
        return 1;  // if the exponent is super slow i.e practically zero
    } // 1 means YES - NUMBER IS ZERO
    else if (first->exp < -(N_DIGITS)){
        _normalize_digits(first, false);
        temp = ((first->exp)-_n_whole_digits(first)); // this is ignoring the decimal portion of the array - will check later
        if (temp < -(N_DIGITS)){ 
            return 0; // YES - NUMBER CLOSE TO ZERO, NO CALCULATIONS CAN BE FURTHER PERFORMED BUT THERE MAY STILL BE SPACE TO THE RIGHT
        }
        else{
            _normalize_digits(first, true); // maybe pushy (i.e removing beginning digits)
            temp = ((first->exp)-_n_precision(first));
            if (temp < -(N_PRECISION)){ 
                return 0; // YES - NUMBER CLOSE TO ZERO, NO CALCULATIONS CAN BE FURTHER PERFORMED BUT THERE MAY STILL BE SPACE TO THE RIGHT
            }
        }
    }
    return -1;  // NO - NUMBER DID NOT FILL UP ENTIRELY OR THE N_DIGITS SPACE
}

static inline bool _is_zero(const _cydecimal_ptr first){
    exponent_t i;
    for (i=MAX_INDICE; i > -1;i--){
        if (first->digits[i]!=0){
            return false;
        }
    }
    return true;
}


    '''
    ctypedef unsigned short iterable_t
    ctypedef short exponent_t
    const iterable_t N_DIGITS
    const iterable_t N_PRECISION
    const iterable_t N_DIGITS_I
    const iterable_t N_PRECISION_I
    const char CAPITAL_E
    const char ZERO
    const char PERIOD
    const char NEGATIVE
    const char TERMINATOR
    const iterable_t MAX_INDICE
    const iterable_t MAX_LENGTH
    
    cdef struct _cydecimal:
        char[MAX_LENGTH] digits
        exponent_t exp
        bool negative
    ctypedef (_cydecimal*) _cydecimal_ptr

    const _cydecimal _abs_dec(_cydecimal first) noexcept nogil
    const void _left_shift_digits(_cydecimal_ptr first, const exponent_t shift) noexcept nogil
    const void _right_shift_digits(_cydecimal_ptr first, const exponent_t shift) noexcept nogil
    const void _program_error(const char* err) noexcept nogil
    const _cydecimal _decimal(const char[MAX_LENGTH]* digits, const exponent_t exp, const bool negative) noexcept nogil
    const void _destruct_decimal(_cydecimal_ptr first) noexcept nogil
    const void _printf_dec(const _cydecimal_ptr dec) noexcept nogil
    const bool _greater_than_digits(const _cydecimal first, const _cydecimal second) noexcept nogil
    const bool _greater_than_exp(const _cydecimal first, const _cydecimal second) noexcept nogil
    const bool _true_greater_than(_cydecimal first, _cydecimal second) noexcept nogil
    const bool _eq_digits(const _cydecimal first,  const _cydecimal second) noexcept nogil
    const bool _eq_exp(const _cydecimal first, const _cydecimal second) noexcept nogil
    const bool _true_eq(_cydecimal first, _cydecimal second) noexcept nogil
    const void _empty_char_arr(char* first) noexcept nogil
    const bool _less_than_digits(const _cydecimal first, const _cydecimal second) noexcept nogil
    const bool _less_than_exp(const _cydecimal first, const _cydecimal second) noexcept nogil
    const bool _true_less_than(_cydecimal first, _cydecimal second) noexcept nogil
    const iterable_t _n_precision(const _cydecimal_ptr first) noexcept nogil
    const iterable_t _n_empty_zeros(const _cydecimal_ptr first) noexcept nogil
    const iterable_t _n_digits(const _cydecimal_ptr first) noexcept nogil
    const iterable_t _n_whole_digits(const _cydecimal_ptr first) noexcept nogil
    const void _normalize_digits(_cydecimal_ptr first, const bool mode) noexcept nogil
    const char* _dec_2_str(const _cydecimal_ptr dec) noexcept nogil
    const bool _greater_than_char(const char[MAX_LENGTH] first, const char[MAX_LENGTH] second) noexcept nogil
    const bool _less_than_char(const char[MAX_LENGTH] first, const char[MAX_LENGTH] second) noexcept nogil
    const bool _eq_char(const char[MAX_LENGTH] first, const char[MAX_LENGTH] second) noexcept nogil
    const _cydecimal _empty_decimal() noexcept nogil
    const void _negate(_cydecimal_ptr first) noexcept nogil
    const char _close_zero(_cydecimal_ptr first) noexcept nogil
    const bool _is_zero(_cydecimal_ptr first) noexcept nogil
cdef inline _cydecimal _norm_decimal_from_double(const double first) noexcept nogil
cdef inline _cydecimal _decimal_from_string(const char* first) noexcept nogil
cdef inline _cydecimal _norm_decimal_from_string(const char* first) noexcept nogil
cdef inline _cydecimal _decimal_from_int(int first) noexcept nogil
cdef inline _cydecimal _norm_decimal_from_int(int first) noexcept nogil
cdef inline _cydecimal _decimal_from_double(const double first) noexcept nogil
cdef inline _cydecimal _subtract_decimals(_cydecimal first, _cydecimal second) noexcept nogil
cdef inline _cydecimal _add_decimals(_cydecimal first, _cydecimal second) noexcept nogil
cdef inline _cydecimal _mult_decimals(const _cydecimal first, const _cydecimal second) noexcept nogil
cdef inline _cydecimal _square_decimal(const _cydecimal first) noexcept nogil
cdef inline _cydecimal _mult_decimal_decimal_digit(const _cydecimal_ptr first, const _cydecimal_ptr second, const int number) noexcept nogil
'''
cdef inline _cydecimal _cydecimal_ptr_2_cydecimal(_cydecimal_ptr first) noexcept nogil:
    return dereference(first)

cdef inline _cydecimal _decimal_cy(const char[MAX_LENGTH]* digits, const exponent_t exp, const bool negative) noexcept nogil:
    cdef _cydecimal res
    memcpy(&res.digits, digits, sizeof(digits))
    res.exp = exp
    res.negative = negative
    return res

cdef inline void _destruct_decimal_cy(_cydecimal_ptr first) noexcept nogil:
    free(first.digits)

cdef inline void _printf_dec_cy(const _cydecimal_ptr dec) noexcept nogil:
    #cdef char* data = <char*>malloc(sizeof(char)*MAX_LENGTH+25)
    #cdef char* temp = data
    #data = _dec_2_str(dec)
    printf("%s\n",_dec_2_str(dec))
    #free(temp)

cdef inline bool _greater_than_digits_cy(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:  # only checks digits in-order
    cdef iterable_t i
    for i in range(MAX_LENGTH):
        if first.digits[i] > second.digits[i]:
            return True
        elif first.digits[i] < second.digits[i]:
            return False
    return False  # equal

cdef inline bool _greater_than_exp_cy(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:  # does NOT normalize digits,
    return first.exp > second.exp

cdef inline bool _true_greater_than_cy(_cydecimal_ptr first, _cydecimal_ptr second) noexcept nogil:  # DOES normalize digits
    if first.exp > second.exp:  # bring up second, without _normalize as we have to normalize after precision and leading zero normalization ANYWAY
        _left_shift_digits(second, first.exp-second.exp)  # bring up value
    elif second.exp > first.exp:
        _left_shift_digits(first, second.exp-first.exp)  # bring up value
    return _greater_than_digits(first, second)

cdef inline bool _eq_digits_cy(_cydecimal * const first,  _cydecimal * const second) noexcept nogil:  # only checks in-order
    cdef iterable_t i
    for i in range(MAX_LENGTH):
        if first.digits[i] == second.digits[i]:
            continue
        else:
            return False
    return True  # equal

cdef inline bool _eq_exp_cy(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:  # does NOT normalize digits,
    return first.exp == second.exp

cdef inline bool _true_eq_cy(_cydecimal_ptr first, _cydecimal_ptr second) noexcept nogil:  # DOES normalize digits
    if first.exp > second.exp:  # bring up second, without _normalize as we have to normalize after precision and leading zero normalization ANYWAY
        _left_shift_digits(second, first.exp-second.exp)  # bring up value
    elif second.exp > first.exp:
        _left_shift_digits(first, second.exp-first.exp)  # bring up value
    else:
        return _eq_digits(first, second)
    return (first.exp == second.exp) and _eq_digits(first, second)

cdef inline bool _less_than_digits_cy(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:  # only checks digits in-order
    cdef iterable_t i
    for i in range(MAX_LENGTH):
        if first.digits[i] < second.digits[i]:
            return True
        elif first.digits[i] > second.digits[i]:
            return False
    return False  # equal

cdef inline bool _less_than_exp_cy(_cydecimal_ptr first, _cydecimal_ptr second) noexcept nogil:  # does NOT normalize digits
    return first.exp < second.exp

cdef inline bool _true_less_than_cy(_cydecimal_ptr first, _cydecimal_ptr second) noexcept nogil:  # DOES normalize digits
    if first.exp > second.exp:  # bring up second, without _normalize as we have to normalize after precision and leading zero normalization ANYWAY
        _left_shift_digits(second, first.exp-second.exp)  # bring up value
    elif second.exp > first.exp:
        _left_shift_digits(first, second.exp-first.exp)  # bring up value
    return _less_than_digits(first, second)

cdef inline iterable_t _n_precision_cy(const _cydecimal_ptr first) noexcept nogil:
    cdef iterable_t i
    for i in range(MAX_INDICE, N_PRECISION_I-1, -1):
        if first.digits[i] != 0:
            return i-N_PRECISION_I
    return N_PRECISION  # all precision is taken up

cdef inline iterable_t _n_empty_zeros_cy(const _cydecimal_ptr first) noexcept nogil:
    cdef iterable_t i  # warning: this function is not safe, just checks whole part, not decimal
    for i in range(N_DIGITS_I, -1, -1):  # essentially reversed _n_whole_digits
        if first.digits[i] != 0:
            return N_DIGITS-i
    return N_DIGITS  # none of whole part is take up

cdef inline iterable_t _n_digits_cy(const _cydecimal_ptr first) noexcept nogil:
    return _n_precision(first)+_n_whole_digits(first) # lazy lmao

cdef inline iterable_t _n_whole_digits_cy(const _cydecimal_ptr first) noexcept nogil:
    cdef iterable_t i
    for i in range(N_DIGITS):
        if first.digits[i] != 0:
            return N_DIGITS-i
    return N_DIGITS  # all whole part is taken up

cdef inline void _normalize_digits_cy(_cydecimal_ptr first, const bool mode) noexcept nogil:
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
'''

cpdef inline dict new_decimal_from_string(const char* first) noexcept:
    return _format_decimal(_decimal_from_string(first)) 

cpdef inline dict norm_decimal_from_string(const char* first) noexcept:
    return _format_decimal(_norm_decimal_from_string(first))  

cpdef inline dict norm_decimal_from_double(const double first) noexcept:
    return _format_decimal(_norm_decimal_from_double(first)) 

cpdef inline dict new_decimal_from_double(const double first) noexcept:
    return _format_decimal(_decimal_from_double(first)) 

cpdef inline dict new_decimal(bytes digits, const exponent_t exp, const bool t) noexcept:
    cdef char[MAX_LENGTH] d = <char*> digits
    cdef dict i = _format_decimal(_decimal(&d, exp, t))
    free(d)
    
    return i 
    
cpdef inline dict norm_decimal_from_int(int first) noexcept:
    return _format_decimal(_norm_decimal_from_int(first)) 

cpdef inline dict new_decimal_from_int(int first) noexcept:
    return _format_decimal(_decimal_from_int(first)) 

cpdef inline dict normalize_digits(_cydecimal res, const bool mode) noexcept:
    _normalize_digits(&res, mode)
    return _format_decimal(res) 

cpdef inline dict right_shift_digits(_cydecimal res, const iterable_t num) noexcept:
    _right_shift_digits(&res, num)
    return _format_decimal(res) 

cpdef inline dict left_shift_digits(_cydecimal res, const iterable_t num) noexcept:
    _left_shift_digits(&res, num)
    return _format_decimal(res) 

cpdef inline bool greater_than_digits(const _cydecimal first, const _cydecimal second) noexcept nogil:
    return _greater_than_digits(first, second)

cpdef inline bool greater_than_exp(_cydecimal first, _cydecimal second) noexcept nogil:
    return _greater_than_exp(first, second)

cpdef inline bool true_greater_than(_cydecimal first, _cydecimal second) noexcept nogil:
    return _true_greater_than(first, second)

cpdef inline bool less_than_digits(const _cydecimal first, const _cydecimal second) noexcept nogil:
    return _less_than_digits(first, second)

cpdef inline bool less_than_exp(_cydecimal first, _cydecimal second) noexcept nogil:
    return _less_than_exp(first, second)

cpdef inline bool true_less_than(_cydecimal first, _cydecimal second) noexcept nogil:
    return _true_less_than(first, second)

cpdef inline bool eq_digits(const _cydecimal first, const _cydecimal second) noexcept nogil:
    return _eq_digits(first, second)


cpdef inline bool eq_exp(_cydecimal first, _cydecimal second) noexcept nogil:
    return _eq_exp(first, second)

cpdef inline bool true_eq(_cydecimal first, _cydecimal second) noexcept nogil:
    return _true_eq(first, second)

cpdef inline dict add_decimals(_cydecimal first, _cydecimal second) noexcept:
    return _format_decimal(_add_decimals(first, second)) 

cpdef inline dict subtract_decimals(_cydecimal first, _cydecimal second) noexcept:
    cdef dict i = _format_decimal(_subtract_decimals(first, second))
    
    return i 

cpdef inline iterable_t n_precision(const _cydecimal first) noexcept nogil:
    return _n_precision(&first)

cpdef inline iterable_t n_digits(const _cydecimal first) noexcept nogil:
    return _n_digits(&first)

cpdef inline iterable_t n_whole_digits(const _cydecimal first) noexcept nogil:
    return _n_whole_digits(&first)

cpdef inline str dec_2_str(_cydecimal dec) noexcept:
    s = (_dec_2_str(&dec)).decode()
    truth  =  s[0] == '-'
    ind = s.index('E')
    s = s[:ind].lstrip('0')+s[ind:]
    if truth:
        s = '-'+(s[1:].lstrip('0'))
    return s

cpdef inline void printf_dec(const _cydecimal dec) noexcept nogil:
    _printf_dec(&dec)

cpdef inline dict square_decimal(const _cydecimal first) noexcept:
    return _format_decimal(_square_decimal(first)) 

cpdef inline dict mult_decimals(const _cydecimal first, const _cydecimal second) noexcept:
    return _format_decimal(_mult_decimals(first, second)) 

cpdef inline dict mult_decimal_decimal_digit(const _cydecimal first, const _cydecimal second, const unsigned int x) noexcept:
    return _format_decimal(_mult_decimal_decimal_digit(&first, &second, x))

cpdef inline dict empty_decimal() noexcept:
    return _format_decimal(_empty_decimal()) 

cdef inline dict _format_decimal(const _cydecimal res) noexcept:
    cdef bytes x = res.digits[:MAX_LENGTH]
    return {'exp': res.exp, 'negative': res.negative, 'digits': x}