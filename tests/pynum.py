from .cynum import *

class cydecimal:
    '''Class wrapper for the _cydecimal struct and functions to operate on it.'''

    def __init__(self, init: bytes|str|int|float, norm: bool|None=True):
        if isinstance(init, bytes) or isinstance(init, str):
            if isinstance(init, str):
                init = init.encode()
            if norm: # normalized\
                self.mynum = (norm_decimal_from_string(init))
            else:
                self.mynum = (new_decimal_from_string(init))
        elif isinstance(init, int):
            if norm:
                self.mynum = (norm_decimal_from_int(init))
            else:
                self.mynum = (new_decimal_from_int(init))
        elif isinstance(init, float):
            if norm:
                self.mynum = (norm_decimal_from_double(init))
            else:
                self.mynum = (new_decimal_from_double(init))
        

    @staticmethod
    def new_empty_decimal():
        return (empty_decimal())

    @staticmethod
    def decimal(init:bytes|str, exponent: int|None=0, negative: bool|None=False):
        if isinstance(init, str):
            init = init.encode()
        assert len(init)==MAX_LENGTH, f"Provided init string must be {MAX_LENGTH} in length (NULL padded, decimal at indice {N_DIGITS})"
        return (new_decimal(init, exponent, negative))


    def __add__(self, other):
        result = add_decimals((self.mynum), (other.mynum))
        return (result)

    def __sub__(self, other):
        result = add_decimals((self.mynum), (other.mynum))
        return (result)

    def __mul__(self, other):
        result = mult_decimals((self.mynum), (other.mynum))
        return (result)

    def __pow__(self, i):
        assert i==2, "Only squaring is currently supported"
        return square_decimal(self.mynum)
    
    def __del__(self):
        self.mynum['exp']=0
        self.mynum['negative']=False
        self.mynum['digits'] = b'1'