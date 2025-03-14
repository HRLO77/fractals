#include <string.h>
#include <stdio.h>
#include <stdbool.h>
#include <math.h>
#include <stdlib.h>

int main();

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
#define N_PRECISION ((iterable_t)2)
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
    printf("%s\n", _dec_2_str(dec));
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






static struct _cydecimal _decimal_from_double(double first) {
    struct _cydecimal res;
    res.negative = first < 0;
    first = fabs(first);
    double large = floor(first), small, temp;
    small = first - large;  // decimal portion
    temp = large;
    iterable_t i;
    unsigned char large_lim = (unsigned char)(floor(log10(fabs(large))) + 1);

    if ((large_lim > N_DIGITS)) {
        large_lim = N_DIGITS;
    }

    
    
    res.exp = 0;
    memset(&res.digits, 0, MAX_LENGTH);

    for (i = 0; i < large_lim; i++) {
        res.digits[N_DIGITS_I - i] = (char)fmod(temp, 10);
        temp = floor(temp * 0.1);
    }

    temp = fabs(small);
    i = N_PRECISION;
    while ((temp) != ceil((temp))) {
        temp = (temp * 10);
        res.digits[i] = (char)fmod(floor(temp), 10);
        i++;

        if (i > MAX_INDICE) {
            break;
        }
    }
    res.wdigits = _n_whole_digits_inner(&res);
    res.pdigits = _n_precision_inner(&res);
    return res;
}


static struct _cydecimal _norm_decimal_from_double(double first) {
    struct _cydecimal res;
    res.negative = first < 0;
    first = fabs(first);
    iterable_t i;
    unsigned char large_lim;
    
    res.exp = 0;
    
    memset(res.digits, 0, MAX_LENGTH);

    while (ceil(first) != first) {
        res.exp--;
        first = first * 10;
    }

    large_lim = (unsigned char)ceil(log10(first) + 1);

    if (large_lim > N_DIGITS) {
        large_lim = N_DIGITS_I;
    }

    for (i = 0; i < large_lim; i++) {
        res.digits[N_DIGITS_I - i] = (char)fmod(first, 10);
        first = floor(first*0.1);
    }

    res.wdigits = _n_whole_digits_inner(&res);
    res.pdigits = 0;
    return res;
}

static struct _cydecimal _norm_decimal_from_string(const char* first) {
    struct _cydecimal res;
    iterable_t length = strlen(first);
    char* strtok_backup = (char*)malloc(length * sizeof(char));
    memcpy(strtok_backup, first, length * sizeof(char));

    char* small = (char*)malloc(sizeof(char)*length);
    char* small_copy = small;
    small = strrchr(first, PERIOD);
    
    small = small + 1;

    char* large = (char*)malloc(sizeof(char)*length);
    char* large_copy = large;
    large = strtok(strtok_backup, ".");

    unsigned char large_len = strlen(large), small_len = strlen(small);

    char* large_norm = (char*)malloc(sizeof(char)*length);
    char* large_norm_copy = large_norm;
    large_norm = large;
    free(strtok_backup);

    iterable_t i;
    

    if (large_len > N_DIGITS) {
        large_len = N_DIGITS;
    }

    if ((small_len + large_len) > N_DIGITS) {
        i = N_DIGITS - large_len;

        if (small_len > i) {
            small_len = i;
        }
    }

    free(large_copy);
    large_len = large_len + small_len;

    large_copy = (char*)malloc(large_len * sizeof(char));
    char* final_large_cpy = large_copy;
    memcpy(large_copy, large_norm, length * sizeof(char));
    free(large_norm_copy);

    strcat(large_copy, small);
    free(small_copy);

    res.exp = -small_len;

    memcpy(res.digits, (char*)calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH * sizeof(char));
    char x;
    res.negative=false;
    if (large_copy[0] == '-'){
        res.negative=true;
        large_copy++;
        large_len--;
    }
    for (i = 0; i < large_len; i++) {
        x = large_copy[large_len - 1 - i];
        //if (x=='-'){ // just check for negative :)
            //res.negative=true;
            //res.digits[N_DIGITS_I - i+1] = -res.digits[N_DIGITS_I - i+1];
            //continue;
        //}
        res.digits[N_DIGITS_I - i] = large_copy[large_len - 1 - i] - ZERO;
    }

    free(final_large_cpy);

    res.wdigits = large_len;
    res.pdigits = 0;
    return res;
}


static struct _cydecimal _decimal_from_string(const char* first) {  // TODO: FIX THIS FUNCTION AND ABOVE, MEMORY ISSUES
    struct _cydecimal res;
    iterable_t length = strlen(first);
    res.exp = 0;


    char* strtok_backup = (char*)malloc(length * sizeof(char));
    memcpy(strtok_backup, first, length * sizeof(char));

    char* small = (char*)malloc(sizeof(char)*length);
    char* small_copy = small;
    small = strrchr(first, PERIOD);
    small++;


    char* large = (char*)malloc(sizeof(char)*length);
    char* large_copy = large;
    large = strtok(strtok_backup, ".");


    free(strtok_backup);
    iterable_t i;
    unsigned char large_len = strlen(large), small_len = strlen(small);

    memcpy(res.digits, (char*)calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH * sizeof(char));
    res.negative=false;
    if (large[0]=='-'){
        large++;
        res.negative=true;
        large_len--;
    }
    for (i = 0; i < large_len; i++) {
        //if (x=='-'){
        //    res.digits[N_DIGITS_I - i+1] = -res.digits[N_DIGITS_I - i+1];
        //    continue;
        //};
        res.digits[N_DIGITS_I - i] = large[large_len - 1 - i] - ZERO;
    }
    free(large_copy);
    for (i = 0; i < small_len; i++) {
        res.digits[N_DIGITS + i] = small[i] - ZERO;
    }

    free(small_copy);
    res.wdigits = large_len;
    res.pdigits = small_len;
    return res;
}

static struct _cydecimal _decimal_from_int(int first) {
    struct _cydecimal res;
    res.negative = first < 0;
    res.exp = 0;
    iterable_t i;
    first = abs(first);
    iterable_t large_lim = (iterable_t)floor(log10(first) + 1);


    memcpy(&res.digits, calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH);
    
    // test: 8204.172
    for (i=0;i<large_lim;i++){
        res.digits[N_DIGITS_I - i] = first % 10;
        first = first/10;
    };
    res.wdigits = large_lim;
    res.pdigits = 0;
    return res;
}

static struct _cydecimal _norm_decimal_from_int(int first) {
    iterable_t i;
    struct _cydecimal res;
    res.negative = first < 0;
    res.exp = 0;
    first = abs(first);
    iterable_t large_lim = (iterable_t)floor(log10(first) + 1);


    memcpy(&res.digits, calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH);
    
    // test: 8204.172
    for (i=0;i<large_lim;i++){
        res.digits[N_DIGITS_I - i] = first % 10;
        first = first/10;
    };
    _normalize_digits(&res, false);
    res.wdigits = _n_whole_digits_inner(&res);
    res.pdigits = 0;
    return res;
}

static struct _cydecimal _subtract_decimals(struct _cydecimal first, struct _cydecimal second) {
    exponent_t i;
    char x, y, res=0;
    bool small = false, negate = false, both=(first.negative && second.negative);
    struct _cydecimal temp;

    iterable_t  dig2 = second.wdigits;
    iterable_t dig1 = first.wdigits;
    // NOTE : TODO : revamp this system to also account for the length of digits - with _subtract_decimals too
    const bool dig1_b = ((dig1 >= MAX_INDICE) && (abs(first.exp) >= abs(MAX_INDICE-dig1)));
    const bool dig2_b = ((dig2 >= MAX_INDICE) && (abs(second.exp) >= abs(MAX_INDICE-dig2)));
    const exponent_t to_move = (abs(abs(first.exp)-abs(second.exp)));
    
    if (dig1_b || dig2_b){
        if (dig1_b && dig2_b){
            _round_decimal(&first, 1);
            _round_decimal(&second, 1);
        }
        else if (dig1_b){
            i=to_move;
            if (i > (dig1-dig2)) i=(dig1-dig2);
            _left_shift_digits(&second, (i)/2); // make the second one left shifted and the first one right shifted halfway
            _right_shift_digits(&first, (i)/2);
        }
        else{ // second is too large
            i=to_move;
            if (i > (dig2-dig1)) i=(dig2-dig1);
            _left_shift_digits(&first, (i)/2); // make the second one left shifted and the first one right shifted halfway
            _right_shift_digits(&second, (i)/2);
        } // this function should handle very large cases
    }

    if (first.exp > second.exp){  // we want to BRING ALL DIGITS TO THE LEFT OF THE DECIMAL NOW
        _left_shift_digits(&first, first.exp-second.exp);  // bring up value
    }
    else if (second.exp > first.exp){
        _left_shift_digits(&second, second.exp-first.exp);  // bring up value, bring down exponent
        //temp = second;
        //second = first;
        //first = temp;  // swap
        //negate = true;
    }
    if (_less_than_digits(first, second) && (!both)){
        temp = second;
        second = first;
        first = temp;  // swap
        negate = true;
    }
    else if (_eq_digits(first, second)){
        return _empty_decimal();
    };

    if ((second.negative) && (!first.negative)){  // second is negative, first is positive, add values instead
        _negate(&second); // used to be abs_dec
        first = _add_decimals(first, second);
        if (negate){
            _negate(&first);
        }
        return first;  // more efficient
    }
    else if (first.negative && (!second.negative)){ // first is negative, second is positive -> add and returns negated value
        //second = _abs_dec(second);
        _negate(&first); // used to be abs_dec
        first = _add_decimals(first, second);
        _negate(&first);
        
        return first;
    }
    else if(both){
        _negate(&second); // changed this on the 23rd mar, may have to switch back
        _negate(&first);
        //first = _subtract_decimals(second, first);
        return _subtract_decimals(second, first);
    }

    //printf("Subtract called!\\n");
    //printf("%s %s %d %d testing lmao\\n", _dec_2_str(&first), _dec_2_str(&second), first.negative, second.negative);
    for (i = MAX_INDICE; i > -1; i--){
        y = second.digits[i];
        x = first.digits[i];
        
        if ((res == 1) || ((x!=0) || (y!=0))) {
            x = x - res;
            y = y;

            small = x < y;
            if (small){
                x+=10;
            };
            res = (x) - y;

            if (res > 9) {
                res = ((res) % 10);
            } else {
                res = res;
            }

            // if (negate) {
            //     if (res != 0) {
            //         index = i;
            //     };
            // };

            first.digits[i] = res;  // always positive

            res = small;
        }
    }

    first.negative = negate;
    // const char r = _close_zero(&first);
    // if (r==1){
    //     return _empty_decimal();
    // }
    // else if(r==0){
    //     _round_decimal(&first, 2);
    // }
    first.pdigits = _n_precision_inner(&first);
    first.wdigits = _n_whole_digits_inner(&first);
    return first;
}

// mar 1st 25, this is the broke subtract, above is the older subtract
// static struct _cydecimal _subtract_decimals(struct _cydecimal first, struct _cydecimal second) {
//     iterable_t i;
//     char x, y, res=0;
//     bool small = false, negate = false, both=(first.negative && second.negative);
//     struct _cydecimal temp;

//     iterable_t dig2 = second.wdigits;
//     iterable_t dig1 = first.wdigits;
//     // NOTE : TODO : revamp this system to also account for the length of digits - with _subtract_decimals too
//     const bool dig1_b = ((dig1 >= MAX_INDICE) && (abs(first.exp) >= abs(MAX_INDICE-dig1))); // coming back after june 19th 2024, wtf is this shit???
//     const bool dig2_b = ((dig2 >= MAX_INDICE) && (abs(second.exp) >= abs(MAX_INDICE-dig2)));
//     const exponent_t to_move = (abs(abs(first.exp)-abs(second.exp)));
    
//     if (dig1_b || dig2_b){
//         if (dig1_b && dig2_b){
//             _round_decimal(&first, 2); //  changed mode from 1 to 2, june 19th 2024
//             _round_decimal(&second, 2);
//         }
//         else if (dig1_b){
//             i=to_move;
//             if (i > (dig1-dig2)) i=(dig1-dig2);
//             _left_shift_digits(&second, (i)/2); // make the second one left shifted and the first one right shifted halfway
//             _right_shift_digits(&first, (i)/2);
//         }
//         else{ // second is too large
//             i=to_move;
//             if (i > (dig2-dig1)) i=(dig2-dig1);
//             _left_shift_digits(&first, (i)/2); // make the second one left shifted and the first one right shifted halfway
//             _right_shift_digits(&second, (i)/2);
//         } // this function should handle very large cases
//     }

//     if (first.exp > second.exp){  // we want to BRING ALL DIGITS TO THE LEFT OF THE DECIMAL NOW
//         _left_shift_digits(&first, first.exp-second.exp);  // bring up value
//     }
//     else if (second.exp > first.exp){
//         _left_shift_digits(&second, second.exp-first.exp);  // bring up value, bring down exponent
//         //temp = second;
//         //second = first;
//         //first = temp;  // swap
//         //negate = true;
//     }
//     if (_less_than_digits(first, second) && (!both)){
//         temp = second;
//         second = first;
//         first = temp;  // swap
//         negate = true;
//     }
//     // else if (_eq_digits(first, second)){ commented out june 19th 2024 for optimization
//     //     return _empty_decimal();
//     // };

//     if ((second.negative) && (!first.negative)){  // second is negative, first is positive, add values instead
//         _negate(&second); // used to be abs_dec
//         first = _add_decimals(first, second);
//         if (negate){
//             _negate(&first);
//         }
//         return first;  // more efficient
//     }
//     else if (first.negative && (!second.negative)){ // first is negative, second is positive -> add and returns negated value
//         //second = _abs_dec(second);
//         _negate(&first); // used to be abs_dec
//         first = _add_decimals(first, second);
//         _negate(&first);
        
//         return first;
//     }
//     else if(both){
//         _negate(&second); // changed this on the 23rd mar, may have to switch back
//         _negate(&first);
//         //first = _subtract_decimals(second, first);
//         return _subtract_decimals(second, first);
//     }

//     //printf("Subtract called!\\n");
//     //printf("%s %s %d %d testing lmao\\n", _dec_2_str(&first), _dec_2_str(&second), first.negative, second.negative);
//     iterable_t break_comp = ((first.pdigits+first.wdigits) > (second.pdigits+second.wdigits)) ? (first.pdigits+first.wdigits+2) : (second.pdigits+second.wdigits+2);
//     for (i = MAX_INDICE; i < MAX_LENGTH; i--){ // essentially looking to overflow this on purpose
//         y = second.digits[i];
//         x = first.digits[i];
//         // if (((MAX_INDICE-i)>break_comp)&&(res==0)){ // if 
//         //    break;
//         // } idk what this does feb 27th 2025
//         x = x - res;
//         //y = y; // why the fuck is this code so retarded lol feb 27th 2025

//         if (x < y){
//             res = x-y+10;
//             first.digits[i] = res;  // always positive
//             res = small;
//         }
//         else{
//             res = (x) - y;
//             first.digits[i] = res;  // always positive
//         };

//         // if (res > 9) {
//         //     res = ((res) % 10);
//         // } else {
//         //     res = res;
//         // } redundant lol feb 27th 2025

//         // if (negate) {
//         //     if (res != 0) {
//         //         index = i;
//         //     };
//         // };

//     }

//     first.negative = true; // removed if (negate){} check feb 28th 2025
//     // const char r = _close_zero(&first);
//     // if (r==1){
//     //     return _empty_decimal();
//     // }
//     // else if(r==0){
//     //     _round_decimal(&first, 2);
//     // }

//     first.pdigits = _n_precision_inner(&first);
//     first.wdigits = _n_whole_digits_inner(&first);
//     return first;
// }

static struct _cydecimal _add_decimals(struct _cydecimal first, struct _cydecimal second) {
    iterable_t i;
    iterable_t  dig2 = second.wdigits;
    iterable_t dig1 = first.wdigits;
    // NOTE : TODO : revamp this system to also account for the length of digits - with _subtract_decimals too
    const bool dig1_b = ((dig1 >= MAX_INDICE) && (abs(first.exp) >= abs(MAX_INDICE-dig1)));
    const bool dig2_b = ((dig2 >= MAX_INDICE) && (abs(second.exp) >= abs(MAX_INDICE-dig2)));
    const exponent_t to_move = (abs(abs(first.exp)-abs(second.exp)));
    
    if (dig1_b || dig2_b){
        if (dig1_b && dig2_b){
            _round_decimal(&first, 1);
            _round_decimal(&second, 1);
        }
        else if (dig1_b){
            i=to_move;
            if (i > (dig1-dig2)) i=(dig1-dig2);
            _left_shift_digits(&second, (i)/2); // make the second one left shifted and the first one right shifted halfway
            _right_shift_digits(&first, (i)/2);
        }
        else{ // second is too large
            i=to_move;
            if (i > (dig2-dig1)) i=(dig2-dig1);
            _left_shift_digits(&first, (i)/2); // make the second one left shifted and the first one right shifted halfway
            _right_shift_digits(&second, (i)/2);
        } // this function should handle very large cases
    }
    if ((first.exp > second.exp)) {
        _left_shift_digits(&first, (first.exp - second.exp)); // trying to make first less - closer to second i.e minimize exp
    } else if (second.exp > first.exp) {
        _left_shift_digits(&second, second.exp - first.exp);
    }
    if (first.negative ^ second.negative){  // if either one is negative, essentially subtraction
        if (second.negative){
            _negate(&second);
            return _subtract_decimals(first, second);
        }
        else{
            _negate(&first);
            first = _subtract_decimals(first, second);
            _negate(&first);
            return first;
        }
    }
    else if (first.negative && second.negative){  // both are negative, add their absolute and returns its negative.

        first = _abs_dec(first);
        second = _abs_dec(second);

        first = (_add_decimals(first, second));
        _negate(&first);
        return first;
    }

    char overflow = 0, res = 0, z, y;
    
    for (i = MAX_LENGTH; i > 0; i--) {
        y = second.digits[i-1];
        z = first.digits[i-1];

        if ((overflow != 0) || ((z!=0) || (y!=0))) {
            res = z + y + overflow;
            overflow = res;

            if (overflow > 9) {
                overflow = overflow % 10;
            }

            first.digits[i-1] = overflow;
            overflow = (char)((res - overflow) * 0.1);
        }
    }
    // const char r = _close_zero(&first);
    // if (r==1){
    //     return _empty_decimal();
    // }
    // else if(r==0){
    //     _round_decimal(&first, 2);
    // }
    first.pdigits = _n_precision_inner(&first);
    first.wdigits = _n_whole_digits_inner(&first);
    return first;
}

// mar 1st 25, also commented out the broken addition
// static struct _cydecimal _add_decimals(struct _cydecimal first, struct _cydecimal second) {
//     iterable_t i;
//     iterable_t dig2 = _n_whole_digits(&second);
//     iterable_t dig1 = _n_whole_digits(&first);
//     // NOTE : TODO : revamp this system to also account for the length of digits - with _subtract_decimals too
//     const bool dig1_b = ((dig1 >= MAX_INDICE) && (abs(first.exp) >= abs(MAX_INDICE-dig1)));
//     const bool dig2_b = ((dig2 >= MAX_INDICE) && (abs(second.exp) >= abs(MAX_INDICE-dig2)));
//     const exponent_t to_move = (abs(abs(first.exp)-abs(second.exp)));
    
//     if (dig1_b || dig2_b){
//         if (dig1_b && dig2_b){
//             _round_decimal(&first, 2);
//             _round_decimal(&second, 2);
//         }
//         else if (dig1_b){
//             i=to_move;
//             if (i > (dig1-dig2)) i=(dig1-dig2);
//             _left_shift_digits(&second, (i)/2); // make the second one left shifted and the first one right shifted halfway
//             _right_shift_digits(&first, (i)/2);
//         }
//         else{ // second is too large
//             i=to_move;
//             if (i > (dig2-dig1)) i=(dig2-dig1);
//             _left_shift_digits(&first, (i)/2); // make the second one left shifted and the first one right shifted halfway
//             _right_shift_digits(&second, (i)/2);
//         } // this function should handle very large cases
//     }
//     if ((first.exp > second.exp)) {
//         _left_shift_digits(&first, (first.exp - second.exp)); // trying to make first less - closer to second i.e minimize exp
//     } else if (second.exp > first.exp) {
//         _left_shift_digits(&second, second.exp - first.exp);
//     }
//     if (first.negative ^ second.negative){  // if either one is negative, essentially subtraction
//         if (second.negative){
//             _negate(&second);
//             return _subtract_decimals(first, second);
//         }
//         else{
//             _negate(&first);
//             first = _subtract_decimals(first, second);
//             _negate(&first);
//             return first;
//         }
//     }
//     else if (first.negative && second.negative){  // both are negative, add their absolute and returns its negative.

//         first = _abs_dec(first);
//         second = _abs_dec(second);

//         first = (_add_decimals(first, second));
//         _negate(&first);
//         return first;
//     }

//     char overflow = 0, res = 0, z, y;
//     //iterable_t break_comp = ((first.pdigits+first.wdigits) > (second.pdigits+second.wdigits)) ? (first.pdigits+first.wdigits+1) : (second.pdigits+second.wdigits+1);
//     for (i = MAX_INDICE; i < MAX_LENGTH; i--) { // essentially looking to overflow this 
//         y = second.digits[i];
//         z = first.digits[i];
//         // if (((MAX_INDICE-i)>break_comp)&&(overflow==0)){ // removed +2 cycles, now just 1
//         //     break;
//         // } serious like whats the point of this opt?? feb 27th 2025
//         res = z + y + overflow;
//         overflow = res;

//         if (overflow > 9) {
//             //overflow = overflow % 10; feb 27th 2025 perhaps removing module will improve speed
//             res = res-10;
//             overflow = 1; // literally only possible to be one thing bruh feb 27th 2025
//         }

//         first.digits[i] = res;
//         //overflow = ((res - overflow)/10);
//     }
//     // const char r = _close_zero(&first);
//     // if (r==1){
//     //     return _empty_decimal();
//     // }
//     // else if(r==0){
//     //     _round_decimal(&first, 2);
//     // }
//     first.pdigits = _n_precision_inner(&first);
//     first.wdigits = _n_whole_digits_inner(&first);
//     return first;
// }

static struct _cydecimal _square_decimal(struct _cydecimal first) {
    exponent_t i, j=HALF_DIGITS, place_val=0;
    unsigned char overflow, x, y;
    struct _cydecimal result = _empty_decimal();
    bool reduce = false;
    _normalize_digits(&first, true); // remove the decimal portion, makes everything to the left side of the decimal
    //printf("%s test\\n", _dec_2_str(first));
    i = first.wdigits;
    
    if ((i) > j){ // exp is negative
        // whenever a number is squared, the len(digits of new num) <= len(digits_old_num)*2
        _right_shift_digits(&first, i-j+1); // move a little more than required just in case :)
        reduce = true;
    }
    result.exp = (first.exp + first.exp);
    // if (first->negative){
    //     result.exp = -(first->exp + first->exp);
    // }
    // else{
    //     result.exp = (first->exp + first->exp);
    // }
    result.negative = false; // always positive :)

    for (i = N_DIGITS_I; i > -1; i--) {
        overflow = 0;
        x = first.digits[i];
        //if (first.negative) {
        //    if ((x > 9)) {
        //        x = -x;
        //    }
        //}

        if (x != 0) {
            for (j = N_DIGITS_I; j > -1; j--) {
                y = first.digits[j];
                //if (first.negative) {
                //    if ((y > 9)) {
                //        y = -y;
                //    }
                //}

                if (y == 0 && overflow == 0) {
                    continue;
                }

                overflow = (x * y) + overflow + result.digits[j - place_val];
                if ((overflow > 9)) {
                    result.digits[j - place_val] = overflow % 10;
                    overflow = overflow / 10;  // Integer division for carry-over
                } else {
                    result.digits[j - place_val] = overflow;
                    overflow = 0;
                }
            }

            
        }
        ++place_val;  // This line adds the carry-over to the next digit
    }
    if ((first.wdigits)>1){
        result.wdigits = first.wdigits+first.wdigits-1; // just testing :)
    }
    else{
        result.wdigits = _n_whole_digits_inner(&result);
    }
    result.pdigits = 0;
    _normalize_digits(&result, false);
    // const char r = _close_zero(&result);
    // if (r==1){
    //     return _empty_decimal();
    // }
    // else if(r==0){
    //     _round_decimal(&result);
    // }
    _round_decimal(&result, 2);
    //if (reduce){ // NOTE: may have to add back
        
    //}

    return result;
}

static struct _cydecimal _mult_decimals(struct _cydecimal first, struct _cydecimal second) {
    exponent_t i, j, place_val=0;
    const bool negate = first.negative ^ second.negative;
    char overflow, x, y, temp;
    bool reduce=false;
    struct _cydecimal result;

    // Initialize result digits to zero
    //memset(result.digits, 0, sizeof(result.digits));
    
    //_normalize_digits(&first, true); // testing removing normalization, june 19th 2024
    //_normalize_digits(&second, true);

    i = _n_whole_digits(&first);
    j = _n_whole_digits(&second);
    if ((i+j)>MAX_INDICE){
        if (i>j){
            _right_shift_digits(&first, ((i)-HALF_DIGITS)); // experimental removal of +1, june 19th 2024
        }
        else{
            _right_shift_digits(&second, ((j)-HALF_DIGITS));
        }
    }

    // if (i>HALF_DIGITS){ // this code block was commented out june 19th 2024
    //     _right_shift_digits(&first, ((i)-HALF_DIGITS)+1);
    //     reduce=true;
    // }
    // if (j>HALF_DIGITS){
    //     _right_shift_digits(&second, ((j)-HALF_DIGITS)+1);
    //     reduce=true;
    // }
    // if (i+j > N_DIGITS){

    // }
    // if (i+j > (HALF_DIGITS)){ // (150+80)-75==155 && (150+80)==230
    //     if (j>i){ // swap, now first always has more digits
    //         result=first;
    //         first=second;
    //         second=result;
    //         place_val=i;
    //         i=j;
    //         j=i;
    //     }
    //     _right_shift_digits(&first, (i+j)-(HALF_DIGITS)+1); // the one with more digits loses em
    //     reduce = true;
    // }
    result = _empty_decimal();
    // apparently you dont have to match the exponents when multiplying or dividing?
    // if (second.exp < first.exp){ // we want to minimize the exp, so that it stays an integer
    //     _left_shift_digits(&first, (first.exp-second.exp));
    // }
    // else if (second.exp > first.exp){ // we want to minimize the exp, so that it stays an integer
    //     _left_shift_digits(&second, (second.exp-first.exp));
    // }
    result.exp = first.exp + second.exp;
    result.negative = negate;
    //printf("Printing... %s %s \\n", _dec_2_str(first), _dec_2_str(second));
    for (i = N_DIGITS_I; i > -1; i--) {
        overflow = 0;
        x = first.digits[i];

        if (x != 0) {
            for (j = N_DIGITS_I; j > -1; j--) {
                y = second.digits[j];

                if (y == 0 && overflow == 0) {
                    continue;
                }

                overflow = (x * y) + overflow + result.digits[j-place_val];
                temp = overflow;
                if ((overflow > 9)) {
                    result.digits[j - place_val] = overflow % 10;
                    overflow = overflow / 10;  // Integer division for carry-over
                    //result.digits[j - place_val-1] = overflow //trying this
                } else {
                    result.digits[j - place_val] = overflow;
                    overflow = 0;
                }
                //printf("overflow: %d temp: %d, res: %d, digits: %s, nums: %d * %d\\n", overflow, temp, result.digits[j - place_val], _dec_2_str(&result), x, y);
            }

           
        }
        ++place_val;  // This line adds the carry-over to the next digit
    }

    result.pdigits = 0; // because we shifted everything to left of decimal, no prec portion!
    if (((first.wdigits)>1) || (second.wdigits > 1)){
        result.wdigits = second.wdigits+first.wdigits-1; // just testing :)
    }
    else{
        result.wdigits = _n_whole_digits_inner(&result);
    }
    _normalize_digits(&result, false);
    // const char r = _close_zero(&result);
    // if (r==1){
    //     return _empty_decimal();
    // }
    // else if(r==0){
    //     _round_decimal(&result);
    // }
    _round_decimal(&result, 2);

    // if (reduce){ // NOTE: may have to add back
    //     _round_decimal(&result, 1); // to 2/3
    // }
    
    return result;
}

int main(){
    struct _cydecimal x;
    struct _cydecimal y;
    struct _cydecimal x1;
    struct _cydecimal y1;
    x1 = _decimal_from_int(1830);
    y1 = _norm_decimal_from_string("192.11282398");
    _round_decimal(&y1, 1);
    _printf_dec(&y1);
    int i;
    
    for (i=0;i<3;i++){
        x = x1;
        y = y1;
        x = _square_decimal(x);

        //_round_decimal(&x, 1);
        _printf_dec(&x);

        x = _add_decimals(x, y);
        
        //_round_decimal(&x, 1);
        _printf_dec(&x);

        x = _mult_decimals(x, y);

        //_round_decimal(&x, 1);
        _printf_dec(&x);

        x = _subtract_decimals(x, y);

        //_round_decimal(&x, 1);
        _printf_dec(&x);
    }
    return 0;
}

//sudo gcc -Wall -O0 --profile -pg code.c -o code
// ./code
//gprof code gmon.out
//gprof ./code.exe gmon.out > analysis.txt