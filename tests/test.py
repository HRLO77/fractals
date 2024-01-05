import math
import decimal
from decimal import Context
decimal.Context(500, None)
decimal.getcontext().prec = 5000
from src import fractions
one = decimal.Decimal("1",)
zero = decimal.Decimal("0",)
def float_to_fraction (x, error=zero):
    n = int(math.floor(x))
    x -= n
    if x < error:
        return (n, one)
    elif one - error < x:
        return (n+one, one)

    # The lower fraction is 0/1
    lower_n = zero
    lower_d = one
    # The upper fraction is 1/1
    upper_n = one
    upper_d = one
    while True:
        # The middle fraction is (lower_n + upper_n) / (lower_d + upper_d)
        middle_n = lower_n + upper_n
        middle_d = lower_d + upper_d
        # If x + error < middle
        if middle_d * (x + error) < middle_n:
            # middle is our new upper
            upper_n = middle_n
            upper_d = middle_d
        # Else If middle < x - error
        elif middle_n < (x - error) * middle_d:
            # middle is our new lower
            lower_n = middle_n
            lower_d = middle_d
        # Else middle is our best fraction
        else:
            return (n * middle_d + middle_n, middle_d)
        
print(float_to_fraction(decimal.Decimal("0.00002276281458802574942404639696751451557095909568791588147481282552083",), zero))


def gcd(n1, n2):
    if (n2 > zero):
        return gcd(n2, n1%n2)
    else:
        return n1

x = decimal.Decimal("365872806449259100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
y = decimal.Decimal("16073267435330382000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
z = (gcd(x, y))
f = fractions.fraction(365872806449259100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.0, 16073267435330382000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.0)
print(fractions.simplify_fraction(f))
