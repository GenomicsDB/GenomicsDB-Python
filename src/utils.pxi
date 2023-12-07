#
# CMakeLists.txt
#
# The MIT License
#
# Copyright (c) 2023 dātma, inc™
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Description : Common cython utility functions
#

# distutils: language = c++
# cython: language_level=3

cimport cython

from libcpp.utility cimport pair
from libcpp.string cimport string
from libcpp.vector cimport vector
from libc.stdint cimport (int64_t, uint64_t, uintptr_t)


from cpython.version cimport PY_MAJOR_VERSION

from cpython.bytes cimport (PyBytes_GET_SIZE,
                            PyBytes_AS_STRING,
                            PyBytes_Size,
                            PyBytes_FromString,
                            PyBytes_FromStringAndSize)

cdef unicode to_unicode(s):
    if type(s) is unicode:
        # Fast path for most common case(s).
        return <unicode>s
    elif PY_MAJOR_VERSION < 3 and isinstance(s, bytes):
        # Only accept byte strings as text input in Python 2.x, not in Py3.
        return (<bytes>s).decode('ascii')
    elif isinstance(s, unicode):
        # We know from the fast path above that 's' can only be a subtype here.
        # An evil cast to <unicode> might still work in some(!) cases,
        # depending on what the further processing does.  To be safe,
        # we can always create a copy instead.
        return unicode(s)
    else:
        raise TypeError("Could not convert to unicode.")

cdef string as_string(s):
    return PyBytes_AS_STRING(to_unicode(s).encode('UTF-8'))

cdef string as_protobuf_string(s):
    return s

cdef vector[string] as_vector(l):
    cdef vector[string] v
    if l is not None:
        for s in l:
            v.push_back(as_string(s))
    return v

cdef genomicsdb_ranges_t as_ranges(l_ranges):
    cdef vector[pair[int64_t, int64_t]] ranges
    if l_ranges is not None and len(l_ranges) > 0:
        for low, high in l_ranges:
            ranges.push_back(pair[int64_t, int64_t](low, high))
    return ranges

cdef genomicsdb_ranges_t scan_full():
    cdef vector[pair[int64_t, int64_t]] ranges
    ranges.push_back(pair[int64_t, int64_t](0, INT64_MAX-1))
    return ranges
