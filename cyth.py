from setuptools import setup, Extension
import setuptools
from Cython.Build import cythonize
import Cython.Compiler.Options
Cython.Compiler.Options.fast_fail = False 
import sys
include = ['src', *sys.path]
cd = {'language_level' : "3"}
# args = ['/O2', '/fp:fast', '/Qfast_transcendentals'] # args for MSVC

# args = ['-Ofast', '-funsafe-math-optimizations', '-mtune=native', '-march=native', '-ffinite-math-only', '-freciprocal-math', '-shared', '-DNPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION', '-std=c++20', '-fno-trapping-math', '-fno-math-errno', '-fno-signed-zeros', '-falign-loops', '-ffp-contract=fast', '-ftree-vectorize', '-mavx', '-mavx2', '-ftree-vectorizer-verbose=5', '-fopenmp', '-faggressive-loop-optimizations', '-floop-nest-optimize', '-funroll-all-loops', '-ftree-parallelize-loops=5','-ftree-loop-optimize', '-floop-parallelize-all', '-ffinite-loops', '-Wwrite-strings', '-lgomp', '-fprefetch-loop-arrays']  # args for GCC
args = ['-O2']

link_args = ['-static-libgcc', '-static-libstdc++', '-W','-Bstatic','--whole-file', '-lwinpthread', '-fopenmp', '-shared', '-lgomp']


# setup(
    # ext_modules=cythonize([Extension("src.mandelbrot_decimal", sources=["src/mandelbrot_decimal.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
# )], nthreads=12, show_all_warnings=1, annotate=1),
    # zip_safe=False, include_dirs=include
# )

setup(
    ext_modules=cythonize([Extension("tests.cynum", sources=["tests/cynum.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
)], nthreads=12, show_all_warnings=1, annotate=1),
    zip_safe=False, include_dirs=include
)

setup(
    ext_modules=cythonize([Extension("tests.unittest", sources=["tests/unittest.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
)], nthreads=12, show_all_warnings=1, annotate=1),
    zip_safe=False, include_dirs=include
)


setup(
    ext_modules=cythonize([Extension("video_copy", sources=["video_copy.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
)], nthreads=12, show_all_warnings=1, annotate=1),
    zip_safe=False, include_dirs=include
)



setup(
    ext_modules=cythonize([Extension("tests.precision_mandelbrot", sources=["tests/precision_mandelbrot.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
)], nthreads=12, show_all_warnings=1, annotate=1),
    zip_safe=False, include_dirs=include
)
exit()
# setup(
#     ext_modules=cythonize([Extension("src.cydecimal", sources=["src/cydecimal.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
# )], nthreads=12, show_all_warnings=1, annotate=1),
#     zip_safe=False, include_dirs=include
# )

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

# setup(
#     ext_modules=cythonize([Extension("src.mandelbrot", sources=["src/mandelbrot.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
# )], nthreads=12, show_all_warnings=1, annotate=1),
#     zip_safe=False, include_dirs=include
# )

setup(
    ext_modules=cythonize([Extension("src.fractional_mandelbrot", sources=["src/fractional_mandelbrot.pyx"], include_dirs=include, extra_compile_args=args, extra_link_args=link_args,\
)], nthreads=12, show_all_warnings=1, annotate=1),
    zip_safe=False, include_dirs=include
)
