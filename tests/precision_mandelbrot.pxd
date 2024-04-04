# cython: language_level=3, binding=False, infer_types=False, wraparound=False, boundscheck=False, cdivision=True, overflowcheck=False, overflowcheck.fold=False, nonecheck=False, initializedcheck=False, always_allow_keywords=False, c_api_binop_methods=True, warn.undeclared=True, CYTHON_ASSUME_SAFE_MACROS=True, CYTHON_FAST_GIL=True, CYTHON_USE_DICT_VERSIONS=True, CYTHON_ASSUME_SAFE_SIZE=True, CYTHON_USE_UNICODE_WRITER=True, CYTHON_UNPACK_METHODS=True, CYTHON_USE_PYLONG_INTERNALS=True, CYTHON_USE_PYLIST_INTERNALS=True, CYTHON_USE_UNICODE_INTERNALS=True, CYTHON_USE_PYTYPE_LOOKUP=True
# disutils: language=c
from .cynum cimport _cydecimal

cdef inline list main(const _cydecimal xmin, const _cydecimal xmax, const _cydecimal ymin, const _cydecimal ymax, const _cydecimal x_recip,const _cydecimal y_recip, const unsigned int width, const unsigned int height, const unsigned int maxiter) noexcept
