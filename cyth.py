from setuptools import setup, Extension
import setuptools
from Cython.Build import cythonize
import sys
include = ['src', *sys.path]
# cd = {'language_level' : "3"}
# args = ['/O2', '/fp:fast', '/Qfast_transcendentals'] # args for MSVC

args = ['-Ofast', '-funsafe-math-optimizations', '-mtune=native', '-march=native', '-ffinite-math-only', '-freciprocal-math', '-shared', '-DNPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION', '-std=c++20', '-fno-trapping-math', '-fno-math-errno', '-fno-signed-zeros', '-falign-loops'] # args for GCC
link_args = ['-static-libgcc', '-static-libstdc++', '-W','-Bstatic','--whole-file', '-lpthread']

setup(
    ext_modules=cythonize([Extension("src.fractions", sources=["src/fractions.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
)], nthreads=12, show_all_warnings=1, annotate=1),
    zip_safe=False, include_dirs=include
)

setup(
    ext_modules=cythonize([Extension("src.test", sources=["src/test.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
)], nthreads=12, show_all_warnings=1, annotate=1),
    zip_safe=False, include_dirs=include
)

setup(
    ext_modules=cythonize([Extension("src.mandelbrot", sources=["src/mandelbrot.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
)], nthreads=12, show_all_warnings=1, annotate=1),
    zip_safe=False, include_dirs=include
)

setup(
    ext_modules=cythonize([Extension("src.fractional_mandelbrot", sources=["src/fractional_mandelbrot.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
)], nthreads=12, show_all_warnings=1, annotate=1),
    zip_safe=False, include_dirs=include
)
