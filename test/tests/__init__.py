from ..src import fractions as cfractions
import fractions

frac1 = cfractions.fraction(numerator=12935189273, denominator=23451, negative=False)
frac2 = cfractions.fraction(numerator=1544353451212332142, denominator=2312, negative=False)
print(frac1, frac2)

frac1 = cfractions._add_fractions(frac1, frac2)

print(frac1, frac2)

# frac2 = cfractions._div_fractions(frac2, frac1)

# print(cfractions._simplify_fraction(frac1), cfractions._simplify_fraction(frac2))


print(cfractions._as_double(frac1), cfractions._as_double(frac2))

frac1 = fractions.Fraction(12935189273, 23451)
frac2 = fractions.Fraction(1544353451212332142, 2312)

frac1 = frac1+frac2

print(frac1.numerator/frac1.denominator, frac2.numerator/frac2.denominator)
