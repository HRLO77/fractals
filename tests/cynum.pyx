# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c
from libc.math cimport fabs, floor, ceil
from libc.stdlib cimport malloc, free, realloc, calloc, abs as cabs
from libc.string cimport memcpy, strcpy as _strcpy, strlen as _strlen, strrchr as _strrchr, strtok as _strtok, strcat as _strcat, strpbrk as _strpbrk, memset as _memset
from .cynum cimport N_DIGITS, N_PRECISION, N_DIGITS_I, N_PRECISION_I, MAX_INDICE, MAX_LENGTH, _cydecimal, _cydecimal_ptr_2_cydecimal, _empty_char_arr, exponent_t, iterable_t, _normalize_digits, _decimal, CAPITAL_E, ZERO, NEGATIVE, PERIOD, TERMINATOR, _cydecimal_ptr, _is_negative, _empty_decimal, _abs_dec, _printf_dec, norm_decimal_from_string, new_decimal_from_string, norm_decimal_from_int, norm_decimal_from_double, new_decimal_from_int, new_decimal_from_double, new_decimal, empty_decimal
from cython.operator cimport preincrement, postincrement, dereference, predecrement, postdecrement

cdef extern from * nogil:
    '''

static struct _cydecimal _mult_decimals(const _cydecimal_ptr first, const _cydecimal_ptr second) {
    exponent_t i, j, place_val=0;
    bool negate = first->negative ^ second->negative;
    unsigned char overflow, x, y;
    struct _cydecimal result = _empty_decimal();
    
    _normalize_digits(first, true);
    _normalize_digits(second, true);

    result.exp = first->exp + second->exp;
    result.negative = negate;

    for (i = N_DIGITS_I; i > -1; i--) {
        overflow = 0;
        x = first->digits[i];
        if (first->negative) {
            if ((x > 9)) {
                x = -x;
            }
        }

        if (x != 0) {
            for (j = N_DIGITS_I; j > -1; j--) {
                y = second->digits[j];
                if (first->negative) {
                    if ((y > 9)) {
                        y = -y;
                    }
                }

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

            ++place_val;  // This line adds the carry-over to the next digit
        }
    }

    if (negate) {
        for (i = 0; i < MAX_LENGTH; i++) {
            if ((result.digits[i] != 0)) { // may have to change if working with huge values :|
                result.digits[i] = -result.digits[i];
                break;
            }
        }
    }

    _normalize_digits(&result, false);
    return result;
}

static struct _cydecimal _decimal_from_double(const double first) {
    double large = floor(first), small, temp;
    small = first - large;  // decimal portion
    temp = large;
    iterable_t i;
    unsigned char large_lim = (unsigned char)(floor(log10(fabs(large))) + 1);

    if ((large_lim > N_DIGITS)) {
        large_lim = N_DIGITS;
    }

    struct _cydecimal res;
    res.negative = first < 0;
    res.exp = 0;
    memset(&res.digits, 0, MAX_LENGTH);

    for (i = 0; i < large_lim; i++) {
        res.digits[N_DIGITS_I - i] = (char)fmod(temp, 10);
        temp = (temp * 0.1);
    }

    temp = small;
    i = N_PRECISION;

    while (fabs(temp) != ceil(fabs(temp))) {
        temp = (temp * 10);
        res.digits[i] = (char)fmod(floor(temp), 10);
        i++;

        if (i > MAX_INDICE) {
            break;
        }
    }

    return res;
}


static struct _cydecimal _norm_decimal_from_double(const double first) {
    double temp = abs(first);
    iterable_t i;
    unsigned char large_lim;
    struct _cydecimal res;
    res.exp = 0;
    res.negative = first < 0;
    memset(res.digits, 0, MAX_LENGTH);

    while (ceil(fabs(temp)) != fabs(temp)) {
        res.exp++;
        temp = temp * 10;
    }

    large_lim = (unsigned char)ceil(log10(fabs(temp)) + 1);

    if (large_lim > N_DIGITS) {
        large_lim = N_DIGITS_I;
    }

    for (i = 0; i < large_lim; i++) {
        res.digits[N_DIGITS_I - i] = (char)fmod(temp, 10);
        temp = temp*0.1;
    }

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
    memcpy(large_copy, large_norm, length * sizeof(char));
    free(large_norm_copy);

    strcat(large_copy, small);
    free(small_copy);

    res.exp = small_len;

    memcpy(res.digits, calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH * sizeof(char));
    char x;
    for (i = 0; i < large_len; i++) {
        x = large_copy[large_len - 1 - i];
        if (x=='-'){ // just check for negative :)
            res.digits[N_DIGITS_I - i+1] = -res.digits[N_DIGITS_I - i+1];
            continue;
        }
        res.digits[N_DIGITS_I - i] = large_copy[large_len - 1 - i] - ZERO;
    }

    free(large_copy);

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
    small = small + 1;


    char* large = (char*)malloc(sizeof(char)*length);
    char* large_copy = large;
    large = strtok(strtok_backup, ".");


    free(strtok_backup);

    iterable_t i;
    unsigned char large_len = strlen(large), small_len = strlen(small);

    memcpy(&res.digits, calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH * sizeof(char));
    char x;
    for (i = 0; i < large_len; i++) {
        x = large[large_len - 1 - i];
        if (x=='-'){
            res.digits[N_DIGITS_I - i+1] = -res.digits[N_DIGITS_I - i+1];
            continue;
        };
        res.digits[N_DIGITS_I - i] = x - ZERO;
    }

    free(large_copy);
    for (i = 0; i < small_len; i++) {
        res.digits[N_DIGITS + i] = small[i] - ZERO;
    }

    free(small_copy);
    return res;
}

static struct _cydecimal _decimal_from_int(int first) {
    iterable_t i;
    unsigned char large_lim = (unsigned char)floor(log10(abs(first)) + 1);
    struct _cydecimal res;
    res.exp = 0;
    res.negative = first < 0;
    memcpy(&res.digits, calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH);
    
    // test: 8204.172
    i = 0;
    while(i<=large_lim){
        res.digits[N_DIGITS_I - i] = abs(first) % 10;
        first = (int)(first*0.1);
        i++;
    };
    if (first < 0){
        res.digits[N_DIGITS-i] = -(res.digits[N_DIGITS-i]);
    };
    return res;
}

static struct _cydecimal _norm_decimal_from_int(int first) {
    iterable_t i;
    unsigned char large_lim = (unsigned char)floor(log10(abs(first)) + 1);
    struct _cydecimal res;
    res.negative = first < 0;
    res.exp = 0;

    memcpy(&res.digits, calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH);
    
    // test: 8204.172
    i = 0;
    while(i<=large_lim){
        res.digits[N_DIGITS_I - i] = abs(first) % 10;
        first = (int)(first*0.1);
        i++;
    };
    if (first < 0){
        res.digits[N_DIGITS-i] = -(res.digits[N_DIGITS-i]);
    };
    _normalize_digits(&res, false);
    return res;
}

static struct _cydecimal _add_decimals();

static struct _cydecimal _subtract_decimals(struct _cydecimal first, struct _cydecimal second) {
    iterable_t i, index = 0;
    char x, y, res=0;
    bool small = 0, negate = 0;
    struct _cydecimal temp;
    if ((second.negative) && (!first.negative)){
        second = _abs_dec(second);
        return _add_decimals(first, second);  // more efficient
    }
    if (first.exp > second.exp){  // bring up second, without _normalize as we have to normalize after precision and leading zero normalization ANYWAY
        _left_shift_digits(&second, first.exp-second.exp);  // bring up value
    }
    else if (second.exp > first.exp){
        _left_shift_digits(&first, second.exp-first.exp);  // bring up value
        temp = second;
        second = first;
        first = temp;  // swap
        negate = true;
    }
    else if (_less_than_digits(&first, &second)){
        temp = second;
        second = first;
        first = temp;  // swap
        negate = true;
    }
    else if (_eq_digits(&first, &second)){
        return _empty_decimal();
    };
    for (i = MAX_LENGTH; i > 0; i--){
        y = second.digits[i-1];
        x = first.digits[i-1];
        
        if ((res == 1) || ((x!=0) || (y!=0))) {
            x = x - res;
            y = y;

            small = x < y;
            if (small){
                x++;
            };
            res = (x) - y;

            if (res > 9) {
                res = ((res) % 10);
            } else {
                res = res;
            }

            if (negate) {
                if (res != 0) {
                    index = i;
                };
            };

            first.digits[i-1] = res;  // always positive

            res = small;
        }
    }

    index--;
    if (negate) {
        first.digits[index] = -first.digits[index];
        first.negative = true;
    }
    return first;
}

static struct _cydecimal _add_decimals(struct _cydecimal first, struct _cydecimal second) {
    iterable_t i;
    
    if (first.exp > second.exp) {
        _left_shift_digits(&second, first.exp - second.exp);
    } else if (second.exp > first.exp) {
        _left_shift_digits(&first, second.exp - first.exp);
    }
    
    if (first.negative || second.negative){
        return _subtract_decimals(first, second);
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

    return first;
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
    const _cydecimal _mult_decimals(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil

cdef char* _dec_2_str_cy(const _cydecimal_ptr dec) noexcept nogil:
    cdef char* string = <char*>malloc(((MAX_LENGTH)+25)*sizeof(char))
    cdef iterable_t i, x = 0, temp = cabs(dec.exp), temp2
    if temp != 0:
        temp2 = <iterable_t>floor(log10((temp))+1)
    else:
        temp2 = 1
    for i in range(MAX_LENGTH):
        if i == N_DIGITS:
            string[i+x] = b'.'  # .
            postincrement(x)
        if dec.digits[i] >= 0:
            string[i+x] = dec.digits[i]+ZERO
            pass
        else:
            string[i] = NEGATIVE
            postincrement(x)
            string[i+x] = (-(dec.digits[i]))+ZERO
    string[MAX_LENGTH+x] = CAPITAL_E # E
    postincrement(x)
    if temp != 0:
        if dec.exp < 0:
            string[MAX_LENGTH+x] = NEGATIVE  # -
            postincrement(x)
        for i in range(temp2):  # n of digits
            string[MAX_LENGTH+x+i] = (temp%10)+ZERO
            temp = <iterable_t>temp//10
    else:
        string[MAX_LENGTH+x] = ZERO  # set to zero
    #realloc(string, sizeof(char)*(MAX_LENGTH+temp2+x+1))
    string[MAX_LENGTH+temp2+x] = TERMINATOR
    return string

cdef _cydecimal _norm_decimal_from_string_cy(const char* first) noexcept nogil:  # use in cases where you want to store the actual decimal by itself
    cdef _cydecimal res
    cdef iterable_t length = _strlen(first)
    cdef char* strtok_backup = <char*>malloc(length*sizeof(char))
    memcpy(strtok_backup, first, sizeof(first))
    cdef char* small = <char*>malloc(sizeof(char)*length)
    cdef char* small_copy = small
    small = _strrchr(first, PERIOD)
    small = small+1
    cdef char* large = <char*>malloc(sizeof(char)*length)
    cdef char* large_copy = large
    large = _strtok(strtok_backup, b'.')
    cdef char* large_norm = <char*>malloc(sizeof(char)*length)
    cdef char* large_norm_copy = large_norm
    large_norm = large
    free(strtok_backup)
    
    cdef iterable_t i, large_len = _strlen(large), small_len = _strlen(small)
    if large_len > N_DIGITS:
        large_len = N_DIGITS  # prefer larger value over smaller, more precise
    if (small_len+large_len) > N_DIGITS:
        i = N_DIGITS-large_len
        if small_len > i:
            small_len = i # save any remaining space for the precise digits
    free(large_copy)
    large_len = large_len+small_len
    large = <char*>malloc(sizeof(char)*(large_len))
    large_copy = large
    memcpy(&large, &large_norm, (length))
    free(large_norm_copy)
    _strcat(large, small)
    free(small_copy)
    res.exp = small_len  # increase precise digits
    #cdef char[MAX_LENGTH] digits = <char*>malloc(sizeof(char)*MAX_LENGTH)   # alloc
    #for i in range(MAX_LENGTH):
    #    digits[i] = 0
    
    memcpy(&res.digits, <char*>calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH*sizeof(char))
    
    for i in range((large_len)-1, -1, -1):
        res.digits[N_DIGITS_I-i] = large[(large_len)-1-i]-ZERO
    free(large_copy)
    
    #memcpy(&res.digits, digits, sizeof(digits))
    return res

cdef _cydecimal _decimal_from_string_cy(const char* first) noexcept nogil:  # use in cases where you want to store the actual decimal by itself
    cdef _cydecimal res
    cdef iterable_t length = _strlen(first)
    res.exp = 0
    cdef char* strtok_backup = <char*>malloc(length*sizeof(char))
    memcpy(strtok_backup, first, sizeof(first))
    cdef char* small = <char*>malloc(sizeof(char)*length)
    cdef char* small_copy = small
    small = _strrchr(first, PERIOD)
    small = small+1
    cdef char* large = <char*>malloc(sizeof(char)*length)
    cdef char* large_copy = large
    large = _strtok(strtok_backup, b'.')
    free(strtok_backup)
    
    cdef iterable_t i, large_len = _strlen(large), small_len = _strlen(small)
    #cdef char[MAX_LENGTH] digits = <char*>malloc(sizeof(char)*MAX_LENGTH)   # alloc
    #for i in range(MAX_LENGTH):
    #    digits[i] = 0
    memcpy(&res.digits, <char*>calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH*sizeof(char))
    _empty_char_arr(res.digits)
    for i in range(large_len-1, -1, -1):
        res.digits[N_DIGITS_I-i] = large[large_len-1-i]-ZERO
    
    free(large_copy)
    for i in range(small_len):
        res.digits[N_DIGITS+i] = small[i]-ZERO
    free(small_copy)
    
    #memcpy(&res.digits, digits, sizeof(digits))
    return res

cdef _cydecimal _decimal_from_int_cy(int first) noexcept nogil:
    cdef iterable_t i
    cdef unsigned char large_lim = <int>floor(log10(cabs(first))+1)
    cdef _cydecimal res
    res.exp = 0
    memcpy(&res.digits, <char*>calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH)
    # test: 8204.172
    for i in range(N_DIGITS):
        if i <= large_lim:
            res.digits[N_DIGITS_I-i] = cabs(first)%10
            first = first//10
        else:
            break
    if first < 0:
        res.digits[N_DIGITS_I-i] = -(res.digits[N_DIGITS_I-i])
    return res

cdef _cydecimal _norm_decimal_from_int_cy(int first) noexcept nogil:
    cdef iterable_t i
    cdef unsigned char large_lim = <int>floor(log10(cabs(first))+1)
    cdef _cydecimal res
    res.exp = 0
    memcpy(&res.digits, <char*>calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH)
    # test: 8204.172
    for i in range(N_DIGITS):
        if i <= large_lim:
            res.digits[N_DIGITS_I-i] = cabs(first)%10
            first = first//10
        else:
            break
    if first < 0:
        res.digits[N_DIGITS_I-i] = -(res.digits[N_DIGITS_I-i])
    _normalize_digits(&res, False)
    return res

cdef _cydecimal _norm_decimal_from_double_cy(const double first) noexcept nogil:  # use if want to normalize to (x>=0)&&(x<=0) (no precision part)
    cdef double temp=first
    cdef iterable_t i
    cdef unsigned char large_lim
    cdef _cydecimal res
    res.exp = 0
    memcpy(&res.digits, <char*>calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH)
    while (ceil(fabs(temp))!=fabs(temp)):
        postincrement(res.exp)
        temp = temp*10
    large_lim = (<iterable_t>floor(log10(fabs(temp))+1))
    if (large_lim > N_DIGITS):
        large_lim = N_DIGITS_I
    # test: 8204.172
    for i in range(large_lim):
        res.digits[N_DIGITS_I-i] = <char>fmod(temp, 10)
        temp = (temp*0.1)
    return res

cdef _cydecimal _decimal_from_double_cy(const double first) noexcept nogil:  # use if there is enough PRECISION storage (will be truncated if no)
    cdef double large = floor(first), small, temp
    small = first-large  # decimal portion
    temp = large
    cdef iterable_t i
    cdef unsigned char large_lim = (<unsigned char>floor(log10(fabs(large))+1))
    if (large_lim > N_DIGITS):
        large_lim = N_DIGITS_I
    cdef _cydecimal res
    res.exp = 0
    memcpy(&res.digits, <char*>calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH)
    # test: 8204.172
    for i in range(large_lim):
        res.digits[N_DIGITS_I-i] = <char>fmod(temp, 10)
        temp = (temp*0.1)
    temp = small
    i = N_PRECISION
    while (fabs(temp)!=ceil(fabs(temp))):
        temp = (temp*10)
        res.digits[i] = <char>fmod(floor(temp), 10)
        postincrement(i)
        if i > MAX_INDICE:
            break
    return res

cdef _cydecimal _add_decimals_cy(_cydecimal first, _cydecimal second) noexcept nogil:
    cdef iterable_t i, x
    if first.exp > second.exp:  # bring up second, without _normalize as we have to normalize after precision and leading zero normalization ANYWAY
        x = first.exp-second.exp
        _left_shift_digits(&second, x)  # bring up value
    elif second.exp > first.exp:
        x = second.exp-first.exp
        _left_shift_digits(&first, x)  # bring up value
    cdef char overflow = 0, res = 0, z, y
    for i in range(MAX_INDICE, -1, -1):
        y = second.digits[i]
        z = first.digits[i]
        if ((overflow!=0) or (x!=0 or y!=0)):
            res = z + y + overflow
            overflow = res
            if overflow > 9:
                overflow = overflow%10
            first.digits[i] = overflow  # get the last digit
            overflow = <char>((res-overflow)*0.1)
    return first

cdef _cydecimal _subtract_decimals_cy(_cydecimal first, _cydecimal second) noexcept nogil:
    cdef iterable_t i, index = 0, t
    cdef char x, y, res=0
    cdef bool small = False, negate=False
    cdef _cydecimal temp
    cdef char[MAX_LENGTH] data
    if first.exp > second.exp:  # bring up second, without _normalize as we have to normalize after precision and leading zero normalization ANYWAY
        _left_shift_digits(&second, first.exp-second.exp)  # bring up value
    elif second.exp > first.exp:
        _left_shift_digits(&first, second.exp-first.exp)  # bring up value
        temp = second
        second = first
        first = temp # swap
        negate = True
    elif _less_than_digits(&first, &second):
        temp = second
        second = first
        first = temp # swap
        negate = True
    elif _eq_digits(&first, &second):  # is this really worth it?
        data = <char*>calloc(MAX_LENGTH, sizeof(char))
        return _decimal(&data, 0, False)
        free(data)
    for i in range(MAX_INDICE, -1, -1):
        y = second.digits[i]
        x = first.digits[i]
        if ((res!=0) or (x!=0 or y!=0)):
            x = x - res
            y = y

            small = x < y
            if small:x+=10
            res = (x) - y 
            if res > 9:
                res = ((res)%10)
            else:
                res=res
            if negate:
                if res!=0:
                    index=i
            first.digits[i] = res  # always positive

            res = small
            #print(overflow, 'overflow', res, small, (<char>small), <char>((res-overflow)*0.1), x, y)
    if negate:
        first.digits[index] = -first.digits[index]
    return first
    
cdef _cydecimal _mult_decimal_cy(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept nogil:
    cdef exponent_t i, j, place_val=0
    cdef bool negate = first.negative ^ second.negative  # 492.665453712
    cdef unsigned char overflow, x, y
    cdef _cydecimal result = _empty_decimal()
    _normalize_digits(first, True)
    _normalize_digits(second, True)
    result.exp = first.exp + second.exp
    result.negative = negate

    for i in range(N_DIGITS_I, -1, -1):
        overflow = 0
        x = first.digits[i]
        if first.negative:
            if x > 9:
                x = -x

        if x != 0:
            for j in range(N_DIGITS_I, -1, -1):
                y = second.digits[j]
                if first.negative:
                    if y > 9:  # overflow lmao
                        y = -y

                if y == 0 and overflow == 0:
                    continue

                overflow = (x * y) + overflow + result.digits[j-place_val]
                if (overflow > 9):
                    result.digits[j-place_val] = overflow % 10
                    overflow = <unsigned char>(overflow*0.1)  # Integer division for carry-over
                else:
                    result.digits[j-place_val] = overflow
                    overflow=0

        postincrement(place_val)
            # This line adds the carry-over to the next digit

    if negate:
        for i in range(MAX_LENGTH):
            if result.digits[i] != 0:
                result.digits[i] = -result.digits[i]
                break
    _normalize_digits(&result, False)
    return result
                
    