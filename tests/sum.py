import numpy as np
import gmpy2
from gmpy2 import mpc, mpfr, mpq, mpz, set_context, context, get_context

# set_context(context())


X = np.linspace(0,3, 3, dtype=object)/mpfr(1)

Y = np.linspace(-3,0,3, dtype=object)/mpfr(1)


print(X[None:,]+Y[:,None]*1j)