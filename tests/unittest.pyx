from .cynum cimport _subtract_decimals, _add_decimals, _norm_decimal_from_string, _mult_decimals, _square_decimal, _abs_dec, _dec_2_str, dec_2_str, _printf_dec, printf_dec, _cydecimal, add_decimals, subtract_decimals, mult_decimals, square_decimal, _decimal_from_double, _round_decimal, _normalize_digits, _decimal_from_string, _decimal_2_double
from libc.stdio cimport printf, puts

cpdef inline str dec_str(_cydecimal dec) noexcept:
    return dec_2_str(dec)

cpdef public int main():
    cdef double first_d = 103.192
    cdef double second_d = -9301.2
    cdef double third_d = -103.192
    cdef double fourth_d = 9301.2
    
    # combinations - first-second, first-third, first-fourth, second-third, second-fourth, third-fourth

    cdef _cydecimal first_cy = _norm_decimal_from_string(b'103.192')
    cdef _cydecimal second_cy = _norm_decimal_from_string(b'-9301.2')
    cdef _cydecimal third_cy = _norm_decimal_from_string(b'-103.192')
    cdef _cydecimal fourth_cy = _norm_decimal_from_string(b'9301.2')

    print(f"\n\nInstantiation test\nExpected: {first_d} {second_d} {third_d} {fourth_d}")
    print(f"Tested: {dec_str(first_cy)} {dec_str(second_cy)} {dec_str(third_cy)} {dec_str(fourth_cy)}\n")

    print(f"\naddition test\nExpected: {first_d+second_d} {first_d+third_d} {first_d+fourth_d} {second_d+third_d} {second_d+fourth_d} {third_d+fourth_d}")
    print(f"Tested: {dec_str(_add_decimals(first_cy, second_cy))} {dec_str(_add_decimals(first_cy, third_cy))} {dec_str(_add_decimals(first_cy, fourth_cy))} {dec_str(_add_decimals(second_cy, third_cy))} {dec_str(_add_decimals(second_cy, fourth_cy))} {dec_str(_add_decimals(third_cy, fourth_cy))}\n")

    print(f"\naddition test 2\nExpected: {first_d+second_d} {first_d+third_d} {first_d+fourth_d} {second_d+third_d} {second_d+fourth_d} {third_d+fourth_d}")
    print(f"Tested: {dec_str(_add_decimals(second_cy, first_cy))} {dec_str(_add_decimals(third_cy, first_cy))} {dec_str(_add_decimals(fourth_cy, first_cy))} {dec_str(_add_decimals(third_cy, second_cy))} {dec_str(_add_decimals(fourth_cy, second_cy))} {dec_str(_add_decimals(fourth_cy, third_cy))}\n")

    print(f"\nsubtraction test\nExpected: {first_d-second_d} {first_d-third_d} {first_d-fourth_d} {second_d-third_d} {second_d-fourth_d} {third_d-fourth_d}")
    print(f"Tested: {dec_str(_subtract_decimals(first_cy, second_cy))} {dec_str(_subtract_decimals(first_cy, third_cy))} {dec_str(_subtract_decimals(first_cy, fourth_cy))} {dec_str(_subtract_decimals(second_cy, third_cy))} {dec_str(_subtract_decimals(second_cy, fourth_cy))} {dec_str(_subtract_decimals(third_cy, fourth_cy))}\n")

    print(f"\subtraction test 2\nExpected: {second_d-first_d} {third_d-first_d} {fourth_d-first_d} {third_d-second_d} {fourth_d-second_d} {fourth_d-third_d}")
    print(f"Tested: {dec_str(_subtract_decimals(second_cy, first_cy))} {dec_str(_subtract_decimals(third_cy, first_cy))} {dec_str(_subtract_decimals(fourth_cy, first_cy))} {dec_str(_subtract_decimals(third_cy, second_cy))} {dec_str(_subtract_decimals(fourth_cy, second_cy))} {dec_str(_subtract_decimals(fourth_cy, third_cy))}\n")

    print(f"\nmultiplication test\nExpected: {first_d*first_d} {first_d*second_d} {second_d*third_d}")
    print(f"Tested: {dec_str(_mult_decimals(first_cy, first_cy))} {dec_str(_mult_decimals(first_cy, second_cy))} {dec_str(_mult_decimals(second_cy, third_cy))}")

    print(f"\nmultiplication test 2\nExpected: {first_d*first_d} {first_d*second_d} {second_d*third_d}")
    print(f"Tested: {dec_str(_mult_decimals(first_cy, first_cy))} {dec_str(_mult_decimals(second_cy, first_cy))} {dec_str(_mult_decimals(third_cy, second_cy))}")

    print(f"\nsquare test\nExpected: {first_d*first_d}, {second_d*second_d}")
    print(f"Tested: {dec_str(_square_decimal(first_cy))} {dec_str(_square_decimal(second_cy))}")

    print(f"\nExtra test: {_decimal_2_double(_subtract_decimals(second_cy, fourth_cy))}")
    #cdef _cydecimal misc = _norm_decimal_from_string(b'1.9829888229814911026715994787309821739823578934723984723')
    #printf("%f float\n", _decimal_2_double(misc))

'''
Re: -0.16
Im: -1.03
'''