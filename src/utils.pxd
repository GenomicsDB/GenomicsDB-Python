# distutils: language = c++
# cython: language_level=3

from libcpp.string cimport string

from cpython.bytes cimport (PyBytes_GET_SIZE,
                            PyBytes_AS_STRING,
                            PyBytes_Size,
                            PyBytes_FromString,
                            PyBytes_FromStringAndSize)

cdef string as_string(s)
