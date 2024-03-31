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
from tests.precision_mandelbrot cimport mandelbrot
from tests.cynum cimport _norm_decimal_from_string, _cydecimal, iterable_t, exponent_t
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import decimal
decimal.getcontext().prec = 80
import time
import numpy as np
import imageio
import asyncio
import warnings
warnings.filterwarnings('ignore')
np.seterr(all="ignore", )
# real, imag = -0.76157365, -0.0847596
print('int')
cdef _cydecimal real = _norm_decimal_from_string(b'0.2505845176040427718957771316508473905552515740661571423212687174479167'), imag = _norm_decimal_from_string(b'0.00002276281458802574942404639696751451557095909568791588147481282552083')
# other possible zooms,  (-1.62917,-0.0203968)  (0.42884,-0.231345)
# data = np.rot90(new_video.main(-2, 0.5, -1.3, 0, 500, 250, 100))
# w = imageio.get_writer('mandelbrot.mp4', format='FFMPEG', mode='I', fps=30, output_params=['-preset', 'ultrafast', '-tune', 'zerolatency', '-an'], macro_block_size=16, )
cdef int iterations = 700
print('out')
cdef _cydecimal xmin = _norm_decimal_from_string(b'-2.0')
cdef _cydecimal xmax = _norm_decimal_from_string(b'0.5')
cdef _cydecimal ymin = _norm_decimal_from_string(b'-1.4')
cdef _cydecimal ymax = _norm_decimal_from_string(b'1.4')
cdef _cydecimal zoom_const = _norm_decimal_from_string(b'0.95') # 0.665625 / 0.95
cdef _cydecimal n_recip = _norm_decimal_from_string(b'0.005') # 0.259375 / 0.005
print('out')
ctypedef list (*func_t)(
    const _cydecimal xmin,
    const _cydecimal xmax,
    const _cydecimal ymin,
    const _cydecimal ymax,
    const _cydecimal n_recip,
    iterable_t width,
    iterable_t height,
    iterable_t maxiter
)
'''ctypedef unsigned int (*func_t)(
    const _cydecimal creal,
    const _cydecimal cimag,
    const unsigned int maxiter
)'''
print(type(mdt.__pyx_capi__['main']))
print(mdt.__pyx_capi__['main'])
printf("TESTING TESTING %s \n", PyCapsule_GetName(mdt.__pyx_capi__['main']))
cdef func_t main = <func_t>PyCapsule_GetPointer(mdt.__pyx_capi__['main'], PyCapsule_GetName(mdt.__pyx_capi__['main']))
cdef int b=time.perf_counter()
cdef list data = main((xmin), (xmax), (ymin), (ymax), n_recip, 400, 400, 200)
print('going in ')
#cdef unsigned int data = mandelbrot(zoom_const, n_recip, 100)
print('out1')
#print(data)
#print(data[0], data[100], data[200])
#exit()
plt.imshow(np.reshape((data), (400, 400)))
print(time.perf_counter()-b)
plt.show()
exit()
