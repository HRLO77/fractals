# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True, profile=True, linetrace=True
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
#include <string.h>
#include <stdio.h>
#include <stdbool.h>
#include <math.h>
#include <stdlib.h>

static struct _cydecimal _square_decimal(struct _cydecimal first);
static struct _cydecimal _mult_decimals(struct _cydecimal first, struct _cydecimal second);
static struct _cydecimal _decimal_from_double(double first);
static struct _cydecimal _norm_decimal_from_double(double first);
static struct _cydecimal _norm_decimal_from_string(const char* first);
static struct _cydecimal _decimal_from_string(const char* first);
static struct _cydecimal _decimal_from_int(int first);
static struct _cydecimal _norm_decimal_from_int(int first);
static struct _cydecimal _subtract_decimals(struct _cydecimal first, struct _cydecimal second);
static struct _cydecimal _add_decimals(struct _cydecimal first, struct _cydecimal second);


typedef short exponent_t; //  formerly short
typedef unsigned short iterable_t;  // formerly ushort

#define N_DIGITS ((iterable_t)80)
#define N_PRECISION ((iterable_t)5)
#define N_DIGITS_I ((iterable_t)(N_DIGITS-1))
#define MAX_INDICE ((iterable_t)(N_DIGITS+N_PRECISION-1))
#define MAX_LENGTH ((iterable_t)(N_DIGITS+N_PRECISION))
#define N_PRECISION_I ((N_DIGITS_I))
#define HALF_DIGITS ((N_DIGITS/2))
#define CAPITAL_E 'E'
#define ZERO '0'
#define PERIOD '.'
#define NEGATIVE '-'
#define TERMINATOR '\0'

const char ZERO_ARRAY[MAX_LENGTH] = {0};


struct _cydecimal {
    char digits[MAX_LENGTH];
    exponent_t exp; 
    bool negative;
    iterable_t wdigits;
    iterable_t pdigits;
};

typedef struct _cydecimal* _cydecimal_ptr;

static void inline _right_shift_digits( _cydecimal_ptr first, exponent_t shift);
static inline exponent_t fast_compare(const char ptr0[MAX_LENGTH], const char ptr1[MAX_LENGTH]);
static void inline _left_shift_digits( _cydecimal_ptr first, exponent_t shift);
static char* _dec_2_str(const _cydecimal_ptr dec);
static void _printf_dec(const _cydecimal_ptr dec);
static inline bool _greater_than_digits(const struct _cydecimal first, const struct _cydecimal second);
static inline bool _less_than_digits(const struct _cydecimal first, const struct _cydecimal second);
static inline bool _eq_digits(const struct _cydecimal first, const struct _cydecimal second);
static inline bool _true_less_than( struct _cydecimal first, struct _cydecimal second);
static inline bool _true_greater_than( struct _cydecimal first, struct _cydecimal second);
static inline bool _true_eq( struct _cydecimal first, struct _cydecimal second);
static inline iterable_t _n_precision(const _cydecimal_ptr first);
static inline iterable_t _n_empty_zeros(const _cydecimal_ptr first);
static inline iterable_t _n_whole_digits_inner(const _cydecimal_ptr first);
static inline iterable_t _n_precision_inner(const _cydecimal_ptr first);
static inline struct _cydecimal _decimal(const char digits[MAX_LENGTH], const exponent_t exp, const bool negative);
static inline iterable_t _n_whole_digits(const _cydecimal_ptr first);
static inline iterable_t _n_digits(const _cydecimal_ptr first);
static inline void _normalize_digits(_cydecimal_ptr first, const bool mode);
static inline void _empty_char_arr(char first[MAX_LENGTH]);
static inline struct _cydecimal _empty_decimal();
static inline struct _cydecimal _abs_dec(struct _cydecimal first);
static inline void _negate(_cydecimal_ptr first);
static inline bool _is_zero(const _cydecimal_ptr first);
static double _decimal_2_double(struct _cydecimal first);
static inline void _round_decimal(_cydecimal_ptr first, unsigned char mode);


// fast_compare function code by https://github.com/mgronhol. previous
static inline exponent_t fast_compare(const char ptr0[MAX_LENGTH], const char ptr1[MAX_LENGTH]) {
    iterable_t i;
    for (i=0;i<MAX_LENGTH;i++){
        if (ptr0[i]^ptr1[i]){
            return (ptr0[i]-ptr1[i]);
        }
    }
    return 0;
}


static void inline _left_shift_digits( _cydecimal_ptr first, exponent_t shift) {
    if (shift < 0){
        _right_shift_digits(first, abs(shift));
        return;
    }
    memmove(first->digits, first->digits + shift, MAX_LENGTH - shift);
    memset(first->digits + MAX_LENGTH - shift, 0, shift);
    first->exp -= (shift);
    
    first->pdigits -= shift;
    if ((first->pdigits) < 0){
        first->pdigits = 0;
    }
    first->wdigits = _n_whole_digits_inner(&first);
    return;
}

static void inline _right_shift_digits( _cydecimal_ptr first, exponent_t shift) { // never assuming that the shift is going to push to empty it! i.e rightshfit until only zeros!
    if (shift < 0){
        _left_shift_digits(first, abs(shift));
        return;
    }
    memmove(first->digits + shift, first->digits, MAX_LENGTH - shift); // this will probably result in errors, switch with memmove if so
    memset(first->digits, 0, shift);
    first->exp += (shift);
    first->wdigits -= (shift);
    if ((first->wdigits) < 0){
        first->wdigits = 0;
    }
    first->pdigits = _n_precision_inner(&first);
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
    return fast_compare(first.digits, second.digits)>0;
    // iterable_t i;
    // for (i = 0; i < MAX_LENGTH; i++) {
    //     if (first.digits[i] > second.digits[i]) {
    //         return (first.negative) ? false : true;
    //     } else if (first.digits[i] < second.digits[i]) {
    //         return (first.negative) ? true : false;
    //     }
    // }
    // return false;
}

static inline bool _true_greater_than(struct _cydecimal first, struct _cydecimal second){
    if ((!first.negative) && (second.negative)){// if first is positive & second is negative
        return true;
    }
    else if ((first.negative) && (!second.negative)){ // if first is negative and second is positive :)
        return false;
    }

    if (first.exp > second.exp) { // minimize exp i.e BRING DIGITS TO THE LEFT OF THE DECIMAL
        if ((first.exp - second.exp) > N_DIGITS_I){ // if pushed suuuuper far back
            return true;
        }
        _left_shift_digits(&first, first.exp - second.exp);
    } else if (second.exp > first.exp) {
        if ((second.exp - first.exp) > N_DIGITS_I){
            return false;
        }
        //if (first.digits[N_DIGITS_I]==9 && (first.exp==-60 && second.exp==0) ){
            //printf("testing here %s %s\\n", _dec_2_str(&second), _dec_2_str(&first));
            //_left_shift_digits(&second, second.exp - first.exp);
            //printf("testing once more %s %s\\n", _dec_2_str(&second), _dec_2_str(&first));
        //}
        _left_shift_digits(&second, second.exp - first.exp);
    }
    return _greater_than_digits(first, second);
}

static inline bool _eq_digits(const struct _cydecimal first, const struct _cydecimal second){
    
    if (first.negative != second.negative){
        return false;
    }
    return fast_compare(first.digits, second.digits)==0;
    // iterable_t i;
    // for (i = 0; i < MAX_LENGTH; i++) {
    //     if (first.digits[i] != second.digits[i]) {
    //         return false;
    //     }
    // }
    // return true;
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
    // to improve this function, we can check lengths. like wdigits wdigits, and pdigits and pdigits. simply account for precision digits and exponenents feb 27th 25
    return fast_compare(first.digits, second.digits)<0;
    // iterable_t i;
    // for (i = 0; i < MAX_LENGTH; i++) {
    //     if (first.digits[i] < second.digits[i]) {
    //         return (first.negative) ? false : true;
    //     } else if (first.digits[i] > second.digits[i]) {
    //         return (first.negative) ? true : false;
    //     }
    // }
    // return false;
}


static inline bool _true_less_than(struct _cydecimal first, struct _cydecimal second){
    if ((!first.negative) && (second.negative)){
        return false;
    }
    else if ((first.negative) && (!second.negative)){
        return true;
    }
    if (first.exp > second.exp) {
        if ((first.exp - second.exp) > N_DIGITS_I){
            return true;
        }
        _left_shift_digits(&first, first.exp - second.exp);
    } else if (second.exp > first.exp) {
        if ((second.exp - first.exp) > N_DIGITS_I){ // havent actually checked out this math
            return false;
        }
        _left_shift_digits(&second, second.exp - first.exp);
    }
    return _less_than_digits(first, second);
}

static inline iterable_t _n_precision(const _cydecimal_ptr first){
    return first->pdigits;
}

// static inline iterable_t _n_precision(const _cydecimal_ptr first) {
//     const char* digits = first->digits;
//     iterable_t i = MAX_INDICE;

//     // Unroll the loop for faster iteration
//     for (; i >= N_PRECISION_I + 3; i -= 4) {
//         if (digits[i] != 0) return i - N_PRECISION_I;
//         if (digits[i - 1] != 0) return i - N_PRECISION_I - 1;
//         if (digits[i - 2] != 0) return i - N_PRECISION_I - 2;
//         if (digits[i - 3] != 0) return i - N_PRECISION_I - 3;
//     }

//     // Process remaining elements in the array
//     for (; i >= N_PRECISION_I; i--) {
//         if (digits[i] != 0) return i - N_PRECISION_I;
//     }

//     return 0; // No non-zero precision digits found
// }


static inline iterable_t _n_empty_zeros(const _cydecimal_ptr first){
    iterable_t i;
    for (i = N_DIGITS; i > 0; i--) {
        if (first->digits[i-1] != 0) {
            return N_DIGITS - i;
        }
    }
    return 0; // means that the entire leftside is zero
}



static inline iterable_t _n_whole_digits_inner(const _cydecimal_ptr first){
    iterable_t i; // first.digits is a char*

    for (i = 0; i < N_DIGITS; i++) {
        if (first->digits[i] != 0) { // i need to find the number of digits that it actually takes up (char* represents a number string)
            return N_DIGITS - i;
        }
    }
    return 0; // no whole digits lmao // if i find none i return 0
}

static inline iterable_t _n_precision_inner(const _cydecimal_ptr first){
    iterable_t i; // first.digits is a char*
    for (i = MAX_LENGTH; i > N_DIGITS; i--) { // shouldnt overflow hopefully :)
        if (first->digits[i-1] != 0) { // i need to find the number of digits that it actually takes up (char* represents a number string)
            return i - N_DIGITS;
        }
    }
    return 0; // no whole digits lmao // if i find none i return 0
}

static inline struct _cydecimal _decimal(const char digits[MAX_LENGTH], const exponent_t exp, const bool negative){
    struct _cydecimal res;
    memcpy(&res.digits, digits, sizeof(digits));
    res.exp = exp;
    res.negative=negative;
    res.wdigits = _n_whole_digits_inner(&res);
    res.pdigits = _n_precision_inner(&res);
    return res;
}

// static inline iterable_t _n_whole_digits_inner(const _cydecimal_ptr first) {
//     const char* digits = first->digits;
//     iterable_t i = 0;

//     // Unroll the loop for faster iteration
//     for (; i < N_DIGITS - 3; i += 4) {
//         if (digits[i] != 0) return N_DIGITS - i;
//         if (digits[i + 1] != 0) return N_DIGITS - (i + 1);
//         if (digits[i + 2] != 0) return N_DIGITS - (i + 2);
//         if (digits[i + 3] != 0) return N_DIGITS - (i + 3);
//     }

//     // Process remaining elements in the array
//     for (; i < N_DIGITS; i++) {
//         if (digits[i] != 0) return N_DIGITS - i;
//     }

//     return 0; // No whole digits found
// }

static inline iterable_t _n_whole_digits(const _cydecimal_ptr first){
    return first->wdigits;
}

static inline iterable_t _n_digits(const _cydecimal_ptr first){
    return (_n_precision(first)) + (_n_whole_digits(&first));
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
    struct _cydecimal res = {(char*)malloc(MAX_LENGTH*sizeof(char)), 0, false, 0, 0};
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

static inline bool _is_zero(const _cydecimal_ptr first){
    return fast_compare(first->digits, ZERO_ARRAY)==0; // easier tbh
}

static double _decimal_2_double(struct _cydecimal first){
    if (first.exp < 0){
        _right_shift_digits(&first, abs(first.exp));
    }
    const iterable_t LEN = (((int)first.negative)+1+MAX_LENGTH);
    char* digits = malloc(sizeof(char)*LEN);
    char* copy = digits;
    memcpy(digits, _dec_2_str(&first), LEN);
    const double x = atof(digits);
    free(copy);
    return x;
}

static inline void _round_decimal(_cydecimal_ptr first, unsigned char mode){ // assuming that overflow is occurring 
    // mode may be 0=ROUND TO 1/3, 1=ROUND TO 1/2, 2=ROUND TO 2/3. Any mode not listed here nullifies the function
    iterable_t i = N_DIGITS_I+(first->pdigits);
    char x=first->digits[i], sub;
    first->digits[i] = 0;
    sub = (x>=5); // sub = 1
    i--;
    for (i=i;i>0;i--){
        x = first->digits[i]+sub;
        
        if (x==10){ // safer option would be x>9, but that realistically wont happen
            sub = 1;
            first->digits[i] = 0;
        }
        else{break;}

    }
}

// mar 1st 2025, commented out the truncating function, actually going to round now (rounding will be a bit broken)
//     mode = mode-3;
//     if ((mode) < 253){ // i.e values other than 0-2 (all inclusive) were entered
//         return;
//     }
//     iterable_t j;
//     mode = mode+3;
//     if (mode==0){
//         j = N_DIGITS/3;
//     }
//     else if (mode==1){
//         j = HALF_DIGITS;
//     }
//     else{
//         j = (N_DIGITS/3);
//         j += j; // j*2;
//     }
    
//     //first->digits[j] += ((first->digits[j+1])>4) ? 1 : 0;

//     if ((first->wdigits+(first->pdigits))>j){
//         _right_shift_digits(first, (first->wdigits+(first->pdigits))-j);
//         return;
//     }
// }

    '''
    ctypedef unsigned short iterable_t
    ctypedef short exponent_t
    const iterable_t N_DIGITS
    const iterable_t N_PRECISION
    const iterable_t N_DIGITS_I
    const iterable_t N_PRECISION_I
    const iterable_t HALF_DIGITS
    const char CAPITAL_E
    const char ZERO
    const char PERIOD
    const char NEGATIVE
    const char TERMINATOR
    const iterable_t MAX_INDICE
    const iterable_t MAX_LENGTH
    const char[MAX_LENGTH] ZERO_ARRAY
    
    cdef struct _cydecimal:
        char[MAX_LENGTH] digits
        exponent_t exp
        bool negative
        iterable_t wdigits
        iterable_t pdigits
        
    ctypedef (_cydecimal*) _cydecimal_ptr

    const bool _is_zero(const _cydecimal_ptr first) noexcept nogil
    const exponent_t fast_compare(const char[MAX_LENGTH] ptr0, const char[MAX_LENGTH] ptr1) noexcept nogil
    const _cydecimal _abs_dec(_cydecimal first) noexcept nogil
    const void _left_shift_digits(_cydecimal_ptr first, const exponent_t shift) noexcept nogil
    const void _right_shift_digits(_cydecimal_ptr first, const exponent_t shift) noexcept nogil
    const _cydecimal _decimal(const char[MAX_LENGTH]* digits, const exponent_t exp, const bool negative) noexcept nogil
    const void _destruct_decimal(_cydecimal_ptr first) noexcept nogil
    const void _printf_dec(const _cydecimal_ptr dec) noexcept nogil
    const bool _greater_than_digits(const _cydecimal first, const _cydecimal second) noexcept nogil
    const bool _true_greater_than(_cydecimal first, _cydecimal second) noexcept nogil
    const bool _eq_digits(const _cydecimal first,  const _cydecimal second) noexcept nogil
    const bool _true_eq(_cydecimal first, _cydecimal second) noexcept nogil
    const void _empty_char_arr(char* first) noexcept nogil
    const bool _less_than_digits(const _cydecimal first, const _cydecimal second) noexcept nogil
    const bool _true_less_than(_cydecimal first, _cydecimal second) noexcept nogil
    const iterable_t _n_precision(const _cydecimal_ptr first) noexcept nogil
    const iterable_t _n_empty_zeros(const _cydecimal_ptr first) noexcept nogil
    const iterable_t _n_digits(const _cydecimal_ptr first) noexcept nogil
    const iterable_t _n_whole_digits(const _cydecimal_ptr first) noexcept nogil
    const iterable_t _n_whole_digits_inner(const _cydecimal_ptr first) noexcept nogil
    const void _normalize_digits(_cydecimal_ptr first, const bool mode) noexcept nogil
    const char* _dec_2_str(const _cydecimal_ptr dec) noexcept nogil
    const _cydecimal _empty_decimal() noexcept nogil
    const void _negate(_cydecimal_ptr first) noexcept nogil
    const bool _is_zero(_cydecimal_ptr first) noexcept nogil
    const void _round_decimal(_cydecimal_ptr first, const unsigned char mode) noexcept nogil
    const double _decimal_2_double(_cydecimal first) noexcept nogil


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

cpdef inline bool is_zero(const _cydecimal first) noexcept nogil:
    return _is_zero(&first);

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

cpdef inline bool true_greater_than(_cydecimal first, _cydecimal second) noexcept nogil:
    return _true_greater_than(first, second)

cpdef inline bool less_than_digits(const _cydecimal first, const _cydecimal second) noexcept nogil:
    return _less_than_digits(first, second)


cpdef inline bool true_less_than(_cydecimal first, _cydecimal second) noexcept nogil:
    return _true_less_than(first, second)

cpdef inline bool eq_digits(const _cydecimal first, const _cydecimal second) noexcept nogil:
    return _eq_digits(first, second)

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

cpdef inline dict empty_decimal() noexcept:
    return _format_decimal(_empty_decimal()) 

cdef inline dict _format_decimal(const _cydecimal res) noexcept:
    cdef bytes x = res.digits[:MAX_LENGTH]
    return {'exp': res.exp, 'negative': res.negative, 'digits': x, 'wdigits': res.wdigits, 'pdigits': res.pdigits}

cpdef inline void testing():
    cdef int i
    cdef _cydecimal x
    for i in range(1000000):
        x = _decimal_from_int(20)
        x = _square_decimal(x)
        x = _add_decimals(x, x)