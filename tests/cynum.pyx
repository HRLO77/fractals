# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c
from libc.math cimport fabs, floor, ceil
from libc.stdlib cimport malloc, free, realloc, calloc, abs as cabs
from libc.string cimport memcpy, strcpy as _strcpy, strlen as _strlen, strrchr as _strrchr, strtok as _strtok, strcat as _strcat, strpbrk as _strpbrk, memset as _memset
from .cynum cimport N_DIGITS, N_PRECISION, N_DIGITS_I, N_PRECISION_I, MAX_INDICE, MAX_LENGTH, _cydecimal, _cydecimal_ptr, _cydecimal_ptr_2_cydecimal, _empty_char_arr, exponent_t, iterable_t, likely, unlikely


cdef char* _dec_2_str(const _cydecimal_ptr dec) noexcept nogil:
    cdef char* string = <char*>malloc(((MAX_LENGTH)+25)*sizeof(char))
    cdef iterable_t i, x = 0, temp = cabs(dec.exp), temp2
    if temp != 0:
        temp2 = <iterable_t>floor(log10((temp))+1)
    else:
        temp2 = 1
    for i in range(MAX_LENGTH):
        if i == N_DIGITS:
            string[i+x] = <char>46  # .
            x += 1
        if dec.digits[i] >= 0:
            string[i+x] = dec.digits[i]+<char>48
            pass
        else:
            string[i] = <char>45
            x+=1
            string[i+x] = (-(dec.digits[i]))+<char>48
    string[MAX_LENGTH+x] = <char>69 # E
    x += 1
    if temp != 0:
        if dec.exp < 0:
            string[MAX_LENGTH+x] = <char>45  # -
            x += 1
        for i in range(temp2):  # n of digits
            string[MAX_LENGTH+x+i] = (temp%10)+<char>48
            temp = <exponent_t>temp//10
    else:
        string[MAX_LENGTH+x] = <char>48  # set to zero
    #realloc(string, sizeof(char)*(MAX_LENGTH+temp2+x+1))
    string[MAX_LENGTH+temp2+x] = <char>0
    return string

cdef _cydecimal _norm_decimal_from_string(const char* first) noexcept nogil:  # use in cases where you want to store the actual decimal by itself
    cdef _cydecimal res
    cdef iterable_t length = _strlen(first)
    cdef char* strtok_backup = <char*>malloc(length*sizeof(char))
    memcpy(strtok_backup, first, sizeof(first))
    cdef char* small = <char*>malloc(sizeof(char)*length)
    cdef char* small_copy = small
    small = _strrchr(first, b'.')
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
        res.digits[N_DIGITS_I-i] = large[(large_len)-1-i]-<char>48
    free(large_copy)
    
    #memcpy(&res.digits, digits, sizeof(digits))
    return res

cdef _cydecimal _decimal_from_string(const char* first) noexcept nogil:  # use in cases where you want to store the actual decimal by itself
    cdef _cydecimal res
    cdef iterable_t length = _strlen(first)
    res.exp = 0
    cdef char* strtok_backup = <char*>malloc(length*sizeof(char))
    memcpy(strtok_backup, first, sizeof(first))
    cdef char* small = <char*>malloc(sizeof(char)*length)
    cdef char* small_copy = small
    small = _strrchr(first, b'.')
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
        res.digits[N_DIGITS_I-i] = large[large_len-1-i]-<char>48
    
    free(large_copy)
    for i in range(small_len):
        res.digits[N_DIGITS+i] = small[i]-<char>48
    free(small_copy)
    
    #memcpy(&res.digits, digits, sizeof(digits))
    return res

cdef _cydecimal _decimal_from_int(int first) noexcept nogil:
    cdef iterable_t i, large_lim = <int>floor(log10(cabs(first))+1)
    cdef _cydecimal res
    res.exp = 0
    memcpy(&res.digits, <char*>calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH)
    # test: 8204.172
    for i in range(N_DIGITS):
        if i <= large_lim:
            res.digits[N_DIGITS_I-i] = first%10
            first = first//10
        else:
            break
    return res

cdef _cydecimal _norm_decimal_from_double(const double first) noexcept nogil:  # use if want to normalize to (x>=0)&&(x<=0) (no precision part)
    cdef double temp=first
    cdef iterable_t i, large_lim
    cdef _cydecimal res
    res.exp = 0
    memcpy(&res.digits, <char*>calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH)
    while (ceil(fabs(temp))!=fabs(temp)):
        res.exp += 1
        temp = temp*10
    large_lim = (<iterable_t>floor(log10(fabs(temp))+1))
    if unlikely(large_lim > N_DIGITS):
        large_lim = N_DIGITS_I
    # test: 8204.172
    for i in range(large_lim):
        res.digits[N_DIGITS_I-i] = <char>fmod(temp, 10)
        temp = floor(temp*0.1)
    return res

cdef _cydecimal _decimal_from_double(const double first) noexcept nogil:  # use if there is enough PRECISION storage (will be truncated if no)
    cdef double large = floor(first), small, temp
    small = first-large  # decimal portion
    temp = large
    cdef iterable_t i, large_lim = (<iterable_t>floor(log10(fabs(large))+1))
    if unlikely(large_lim > N_DIGITS):
        large_lim = N_DIGITS_I
    cdef _cydecimal res
    res.exp = 0
    memcpy(&res.digits, <char*>calloc(MAX_LENGTH, sizeof(char)), MAX_LENGTH)
    # test: 8204.172
    for i in range(large_lim):
        res.digits[N_DIGITS_I-i] = <char>fmod(temp, 10)
        temp = floor(temp*0.1)
    temp = small
    i = N_PRECISION
    while (fabs(temp)!=ceil(fabs(temp))):
        temp = (temp*10)
        res.digits[i] = <char>fmod(floor(temp), 10)
        i += 1
        if i > MAX_INDICE:
            break
    return res

cdef _cydecimal _add_decimals(_cydecimal first, _cydecimal second) noexcept nogil:
    cdef iterable_t i, x
    if first.exp > second.exp:  # bring up second, without _normalize as we have to normalize after precision and leading zero normalization ANYWAY
        x = first.exp-second.exp
        _left_shift_digits(&second, x)  # bring up value
    elif second.exp > first.exp:
        x = second.exp-first.exp
        _left_shift_digits(&first, x)  # bring up value
    cdef char overflow = 0, res = 0
    for i in range(MAX_INDICE, -1, -1):
        res = first.digits[i] + second.digits[i] + overflow
        overflow = res
        if overflow > 9:
            overflow = overflow%10
        first.digits[i] = overflow  # get the last digit
        overflow = <char>((res-overflow)*0.1)
    return first

cdef _cydecimal _subtract_decimals(_cydecimal first, _cydecimal second) noexcept nogil:
    cdef iterable_t i, index = 0, t
    cdef char x, y
    if first.exp > second.exp:  # bring up second, without _normalize as we have to normalize after precision and leading zero normalization ANYWAY
        t = first.exp-second.exp
        _left_shift_digits(&second, t)  # bring up value
    elif second.exp > first.exp:
        t = second.exp-first.exp
        _left_shift_digits(&first, t)  # bring up value
    cdef char res = 0
    cdef bool small = False, negate=False
    cdef _cydecimal temp

    if _less_than_digits(&first, &second):
        temp = second
        second = first
        first = temp # swap
        negate = True
    if _eq_digits(&first, &second):  # is this really worth it?
        return _decimal_from_int(0)

    for i in range(MAX_INDICE-1, -1, -1):
        x = first.digits[i] - res
        y = second.digits[i]

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

        res = (1*small)
        #print(overflow, 'overflow', res, small, (<char>small), <char>((res-overflow)*0.1), x, y)
    if negate:
        first.digits[index] = -first.digits[index]
    return first