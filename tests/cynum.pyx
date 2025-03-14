# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True, profile=True, linetrace=True
# disutils: language=c
from libc.math cimport fabs, floor, ceil
from libc.stdlib cimport malloc, free, realloc, calloc, abs as cabs
from libc.string cimport memcpy, strcpy as _strcpy, strlen as _strlen, strrchr as _strrchr, strtok as _strtok, strcat as _strcat, strpbrk as _strpbrk, memset as _memset
from .cynum cimport N_DIGITS, N_PRECISION, N_DIGITS_I, N_PRECISION_I, MAX_INDICE, MAX_LENGTH, _cydecimal, _empty_char_arr, exponent_t, iterable_t, _normalize_digits, _decimal, CAPITAL_E, ZERO, NEGATIVE, PERIOD, TERMINATOR, _cydecimal_ptr, _empty_decimal, _abs_dec, _printf_dec, norm_decimal_from_string, new_decimal_from_string, norm_decimal_from_int, norm_decimal_from_double, new_decimal_from_int, new_decimal_from_double, new_decimal, empty_decimal, _negate, ZERO_ARRAY, _n_whole_digits_inner
from cython.operator cimport preincrement, postincrement, dereference, predecrement, postdecrement

cdef extern from * nogil:
    '''

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

    '''
    const _cydecimal _decimal_from_double(const double first) noexcept nogil
    const _cydecimal _norm_decimal_from_double(const double first) noexcept nogil
    const _cydecimal _norm_decimal_from_string(const char* first) noexcept nogil
    const _cydecimal _decimal_from_string(const char* first) noexcept nogil
    const _cydecimal _decimal_from_int(int first) noexcept nogil
    const _cydecimal _norm_decimal_from_int(int first) noexcept nogil
    const _cydecimal _add_decimals(_cydecimal first, _cydecimal second) noexcept nogil
    const _cydecimal _subtract_decimals(_cydecimal first, _cydecimal second) noexcept nogil
    const _cydecimal _mult_decimals(const _cydecimal first, const _cydecimal second) noexcept nogil
    #const _cydecimal _mult_decimal_decimal_digit(const _cydecimal_ptr first, const _cydecimal_ptr second, const int number) noexcept nogil
    const _cydecimal _square_decimal(const _cydecimal first) noexcept nogil
#
    