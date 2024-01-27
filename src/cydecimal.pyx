# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c
from libc.math cimport fabs, floor, ceil
from libc.stdlib cimport malloc, free, realloc, calloc, abs as cabs
from libc.string cimport memcpy
from cython.parallel cimport parallel, prange
from .cydecimal cimport N_DIGITS, N_PRECISION, N_DIGITS_I, N_PRECISION_I, MAX_INDICE, MAX_LENGTH, _cydecimal, _cydecimal_ptr, _cydecimal_ptr_2_cydecimal, _empty_char_arr

cdef char* _dec_2_str(_cydecimal dec) noexcept nogil:
    cdef char* string = <char*>malloc(sizeof(char)*(MAX_LENGTH+3))
    cdef unsigned int i, x = 0
    for i in range(MAX_LENGTH):
        if i == N_DIGITS:
            string[i+x] = b'.'
            x += 1
        if dec.digits[i] >= 0:
            string[i+x] = dec.digits[i]+<char>48
        else:
            string[i] = 45
            x+=1
            string[i+x] = (-(dec.digits[i]))+<char>48
            
    string[_strlen(string)-1] = b'\0'
    return string

cdef _cydecimal _new_decimal_from_string(const char* first) noexcept nogil:
    cdef _cydecimal res
    cdef char* strtok_backup = <char*>malloc(_strlen(first)*sizeof(char))
    memcpy(strtok_backup, first, sizeof(first))
    cdef char* small = _strrchr(first, b'.')
    small = small+1
    cdef char* large = _strtok(strtok_backup, b'.')
    cdef unsigned int i, large_len = _strlen(large), small_len = _strlen(small)
    cdef char[MAX_LENGTH] digits = <char*>malloc(sizeof(char)*MAX_LENGTH)   # alloc
    for i in range(MAX_LENGTH):
        digits[i] = 0
    for i in range(large_len-1, -1, -1):
        digits[N_DIGITS_I-i] = large[large_len-1-i]-<char>48
    for i in range(small_len):
        digits[N_PRECISION+i] = small[i]-<char>48
    # test: 8204.172
    memcpy(&res.digits, digits, sizeof(digits))
    return res

cdef _cydecimal _new_decimal_from_int(int first) noexcept nogil:
    cdef unsigned int i, large_lim = <int>ceil(log10(cabs(first)))
    cdef _cydecimal res
    cdef char[MAX_LENGTH] digits = <char*>malloc(sizeof(char)*MAX_LENGTH)  # alloc
    # test: 8204.172
    for i in range(N_DIGITS):
        if i <= large_lim:
            digits[N_DIGITS_I-i] = first%10
            first = first//10
        else:
            digits[N_DIGITS_I-i] = 0
    for i in range(N_PRECISION):
        digits[N_PRECISION+i] = 0
    memcpy(&res.digits, digits, sizeof(digits))
    return res

cdef _cydecimal _new_decimal_from_large_double(const double first) noexcept nogil:
    cdef double large = floor(first), small, temp
    small = first-large  # decimal portion
    temp = large
    cdef unsigned int i, large_lim = <int>ceil(log10(fabs(large)))
    cdef _cydecimal res
    cdef char[MAX_LENGTH] digits = <char*>malloc(sizeof(char)*MAX_LENGTH)  # alloc
    # test: 8204.172
    for i in range(N_DIGITS):
        if i <= large_lim:
            digits[N_DIGITS_I-i] = <char>fmod(temp, 10)
            temp = floor(temp*0.1)
        else:
            digits[N_DIGITS_I-i] = 0
    temp = small
    for i in range(N_PRECISION):
        if temp != ceil(temp):
            temp = (temp*10)
            digits[N_PRECISION+i] = <char>fmod(floor(temp), 10)
        else:
            digits[N_PRECISION+i] = 0
    memcpy(&res.digits, digits, sizeof(digits))
    return res

cdef _cydecimal _add_decimals(_cydecimal first, const _cydecimal_ptr second) noexcept nogil:
    cdef unsigned int i
    cdef char overflow = 0, res = 0
    for i in range(MAX_INDICE, -1, -1):
        res = first.digits[i] + second.digits[i] + overflow
        if overflow > 9:
            overflow = res%10
        else:
            overflow = res
        first.digits[i] = overflow  # get the last digit
        overflow = <char>((res-overflow)*0.1)
    return first

cdef _cydecimal _mult_decimals(const _cydecimal_ptr first, const _cydecimal_ptr second) noexcept:       
    cdef int i, j, overflow=0, effective_i=0, effective_j=0
    print('loaded1')
    cdef char[MAX_LENGTH] arr = <char*>malloc(sizeof(char)*MAX_LENGTH)
    
    print('loaded2')
    cdef _cydecimal res = _new_decimal(&arr)
    memcpy(&res.digits, &arr, sizeof(arr))
    _empty_char_arr(&res.digits)
    print('freeing')
    print('loaded')
    for i in range(MAX_INDICE, -1, -1):
        overflow=0
        effective_i+=1
        effective_j = 0
        for j in range(MAX_INDICE, -1, -1):
            if (first.digits[i]!=0 and second.digits[j]!=0) or overflow!=0:
                effective_j+=1
                res.digits[j] += overflow
                overflow = (first.digits[i])*(second.digits[j])
                if cabs(overflow) > 9:
                    res.digits[j] += (overflow)%(10 if overflow > 0 else -10)
                else:
                    res.digits[j] += (overflow)
                if cabs(res.digits[j]) > 9:
                    overflow += res.digits[j]
                    res.digits[j] = (res.digits[j])%(10 if res.digits[j] > 0 else -10)
                if cabs(overflow)>9:overflow = overflow//10
                print(overflow, first.digits[i], second.digits[j], res.digits[j], j)
    return res  # 123.27*312.86

cdef _cydecimal _subtract_decimals(_cydecimal first, _cydecimal second) noexcept nogil:
    cdef int i, x, y, index = 0
    cdef char overflow = 0, res = 0
    cdef bool small = False, negate=False
    cdef _cydecimal temp

    if _less_than_decimal(&first, &second):
        temp = second
        second = first
        first = temp # swap
        negate = True
    if _eq_decimal(&first, &second):
        return _new_decimal_from_int(0)

    for i in range(MAX_INDICE-1, -1, -1):
        x = first.digits[i] - overflow
        y = second.digits[i]

        small = x < y
        res = (x+10 if small else x) - y 
        if res > 9:
            overflow = ((res)%10)
        else:
            overflow=res
        if negate:
            if overflow!=0:
                index=i
        first.digits[i] = overflow  # always positive

        overflow = 1 if small else 0
        #print(overflow, 'overflow', res, small, (<char>small), <char>((res-overflow)*0.1), x, y)
    if negate:
        first.digits[index] = -first.digits[index]
    return first