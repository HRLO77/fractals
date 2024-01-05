import math
import decimal
from decimal import Context
decimal.Context(500, None)
decimal.getcontext().prec = 5000
one = decimal.Decimal("1", Context(5000, None))
zero = decimal.Decimal("0", Context(5000, None))
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
        
print(float_to_fraction(decimal.Decimal("0.00002276281458802574942404639696751451557095909568791588147481282552083", Context(5000, None)), zero))

0.25058451760404277189577713169633296659134110469742451172446815720634771824937033688154636587293626982678995859601753061821325157518250355932434105740284155163149477888875663044839368498220412554672887693224051547359126054243265543041538328553828105222610130051154348796504216650549679675785767790167810527642882283736320195441512100105146856569843819285239720259894813001714410204879020849545487149450975692417905811784155232671918169369163643577935685860169944995799039667061326655445714352884988266

0.2505845176040427718957771316508473905552515740661571423212687174479167