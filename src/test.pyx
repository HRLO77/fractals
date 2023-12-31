# cython: language_level=3, binding=True, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c
from . cimport fractions as cfractions
import fractions
from time import perf_counter

cpdef public double test():
    cdef cfractions._fraction c1, c2, tempc1, tempc2
    cdef object f1, f2, tempf1, tempf2
    c1 = cfractions._fraction(12312, 345)
    c2 = cfractions._fraction(-134135, 765)
    f1 = fractions.Fraction(12312, 345)
    f2 = fractions.Fraction(-134135, 765)
    
    print('Following cfraction ouputs are NOT simplified unless otherwise stated - \n\n')

    # repr test

    print(f"Expected output: {f1.numerator/f1.denominator} {f2.numerator/f2.denominator}")
    print(f"Result: {cfractions._as_double(&c1)} {cfractions._as_double(&c2)}\n")

    # simplification test
    cfractions._simplify_fraction(&c2)
    cfractions._simplify_fraction(&c1)
    print(f"Expected output: {f1} {f2}")
    print(f"Simplified result: {c1} {c2}\n")

    # equity test
    tempc1 = cfractions._fraction(12312, 345)
    tempc2 = cfractions._fraction(-134135, 765)
    print(f"Expected output: {f1==fractions.Fraction(12312, 345)} {f2==fractions.Fraction(-134135, 765)}")
    print(f"Result: {cfractions._eq_fractions(&c1, &tempc1, False, True)} {cfractions._eq_fractions(&c2, &tempc2, False, True)}\n")


    # powers test
    print(f"Expected output: {f1**2} {f1**3} {f1**5} {f2**2} {f2**3} {f2**5}")
    print(f"Result: {cfractions._square(c1)} {cfractions._cube(c1)} {cfractions._n_power(c1, 5)} {cfractions._square(c2)} {cfractions._cube(c2)} {cfractions._n_power(c2, 5)}\n")

    # powers test
    print(f"Expected output: {f1**2} {f1**3} {f1**5} {f2**2} {f2**3} {f2**5}")
    print(f"Result: {cfractions._square(c1)} {cfractions._cube(c1)} {cfractions._n_power(c1, 5)} {cfractions._square(c2)} {cfractions._cube(c2)} {cfractions._n_power(c2, 5)}\n")
    
    # addition/subtraction test
    print(f"Expected output: {f1-f2} {f1+f1} {f2+72} {f2-15}")
    cfractions._set_num_den(&tempc1, c1.numerator, c1.denominator)
    print(f"Result: {cfractions._sub_fractions(c1, &c2)} {cfractions._add_fractions(c1, &tempc1)} {cfractions._add_fraction_double(c2, 72)} {cfractions._sub_fraction_double(c2, 15)}\n")
    
    # multiplication/division test
    print(f"Expected output: {f1/f2} {f1*f1} {f2/72} {f1*15} {f1/f1}")
    cfractions._set_num_den(&tempc1, c1.numerator, c1.denominator)
    print(f"Result: {cfractions._div_fractions(c1, &c2)} {cfractions._mult_fractions(c1, &tempc1)} {cfractions._div_fraction_double(c2, 72)} {cfractions._mult_fraction_double(c2, 15)} {cfractions._div_fractions(c1, &tempc1)}\n")

    # comparison
    cfractions._set_num_den(&tempc2, 3, 5)
    cfractions._set_num_den(&tempc1, 4, 6)
    
    print(f"Expected output: {f1 > f2}  {f2 < f1} {f2 < 123142142} {f1 > 3} {fractions.Fraction(3,5) < fractions.Fraction(4,6)}")
    print(f"Result: {cfractions._greater_than_fraction(&c1, &c2)} {cfractions._less_than_fraction(&c2, &c1)} {cfractions._less_than_double(&c2, 123142142)} {cfractions._greater_than_double(&c1, 3)} {cfractions._greater_than_fraction(&tempc2, &tempc1)}")

    