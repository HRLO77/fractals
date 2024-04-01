# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True
# disutils: language=c
from os import add_dll_directory
add_dll_directory('/MinGW/bin/')
import time
from cpython.pycapsule cimport PyCapsule_Import, PyCapsule_GetPointer, PyCapsule_GetName
from libc.stdio cimport puts, printf
import src.mandelbrot_decimal as mandelbrot_decimal
#import src.mandelbrot as mandelbrot
import tests.precision_mandelbrot as mdt
from tests.cynum cimport _norm_decimal_from_string, _cydecimal, iterable_t, exponent_t, _destruct_decimal
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import decimal
decimal.getcontext().prec = 80
import time
import numpy as np
import imageio
import asyncio
import warnings
import time
# real, imag = -0.76157365, -0.0847596
#cdef _cydecimal real = _norm_decimal_from_string(b'0.2505845176040427718957771316508473905552515740661571423212687174479167'), imag = _norm_decimal_from_string(b'0.00002276281458802574942404639696751451557095909568791588147481282552083')
# other possible zooms,  (-1.62917,-0.0203968)  (0.42884,-0.231345)
# data = np.rot90(new_video.main(-2, 0.5, -1.3, 0, 500, 250, 100))
# w = imageio.get_writer('mandelbrot.mp4', format='FFMPEG', mode='I', fps=30, output_params=['-preset', 'ultrafast', '-tune', 'zerolatency', '-an'], macro_block_size=16, )
cdef int iterations = 700
cdef _cydecimal xmin = _norm_decimal_from_string(b'-2.0')
cdef _cydecimal xmax = _norm_decimal_from_string(b'0.5')
cdef _cydecimal ymin = _norm_decimal_from_string(b'-1.4')
cdef _cydecimal ymax = _norm_decimal_from_string(b'1.4')
#cdef _cydecimal zoom_const = _norm_decimal_from_string(b'0.95') # 0.665625 / 0.95
cdef _cydecimal x_recip = _norm_decimal_from_string(b'0.002') # 0.259375 / 0.005
cdef _cydecimal y_recip = _norm_decimal_from_string(b'0.002')
ctypedef list (*func_t)(
    const _cydecimal xmin,
    const _cydecimal xmax,
    const _cydecimal ymin,
    const _cydecimal ymax,
    const _cydecimal x_recip,
    const _cydecimal y_recip,
    iterable_t width,
    iterable_t height,
    iterable_t maxiter
)
'''ctypedef unsigned int (*func_t)(
    const _cydecimal creal,
    const _cydecimal cimag,
    const unsigned int maxiter
)'''
#print(type(mdt.__pyx_capi__['main']))
#print(mdt.__pyx_capi__['main'])
#printf("TESTING TESTING %s \n", PyCapsule_GetName(mdt.__pyx_capi__['main']))
cdef func_t main = <func_t>PyCapsule_GetPointer(mdt.__pyx_capi__['main'], PyCapsule_GetName(mdt.__pyx_capi__['main']))
cdef int b=time.perf_counter()
cdef object data = main((xmin), (xmax), (ymin), (ymax), x_recip, y_recip, 500, 500, 100)
'''_destruct_decimal(&x_recip)
_destruct_decimal(&xmax)
_destruct_decimal(&xmin)
_destruct_decimal(&ymax)
_destruct_decimal(&ymin)
_destruct_decimal(&y_recip)'''
print('out1')

globals()['_data'] = data