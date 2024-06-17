#
# CMakeLists.txt
#
# The MIT License
#
# Copyright (c) 2023-2024 dātma, inc™
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

# Using PyCapsule for interoperabilty with the (Nano)Arrow C Interface
# See https://arrow.apache.org/docs/format/CDataInterface/PyCapsuleInterface.html
from cpython.pycapsule cimport (PyCapsule_New, PyCapsule_GetPointer, PyCapsule_IsValid)

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


# Arrow based Utilities that use PyCapsule for interoperabilty with the (Nano)Arrow C Interface
# See https://arrow.apache.org/docs/format/CDataInterface/PyCapsuleInterface.html

cdef void  pycapsule_delete_arrow_schema(object schema_capsule) noexcept:
  genomicsdb_cleanup_arrow_schema(PyCapsule_GetPointer(schema_capsule, 'arrow_schema'))

cdef void pycapsule_delete_arrow_array(object array_capsule) noexcept:
  genomicsdb_cleanup_arrow_array(PyCapsule_GetPointer(array_capsule, 'arrow_array'))

cdef object pycapsule_get_arrow_schema(void *schema):
  return PyCapsule_New(<ArrowSchema*>schema, "arrow_schema", &pycapsule_delete_arrow_schema);

cdef object pycapsule_get_arrow_array(void *array):
  return PyCapsule_New(<ArrowArray*>array, "arrow_array", &pycapsule_delete_arrow_array);

def c_arrow_type_from_format(format):
  # schema format types supported by GenomicsDB
  if format == b'u':
    return pa.string()
  elif format == b'L':
    return pa.uint64()
  elif format == b'i':
    return pa.int32()
  elif format == b'f':
    return pa.float32()
  else:
    return pa.null()

cdef class _ArrowSchemaWrapper:
  cdef object _base
  cdef ArrowSchema* _schema_ptr
  
  def __cinit__(self, object base, uintptr_t schema_ptr):
    self._base = base
    self._schema_ptr = <ArrowSchema*>schema_ptr;
    
  @staticmethod
  def _import_from_c_capsule(schema_capsule):
    return _ArrowSchemaWrapper(schema_capsule,
                              <uintptr_t>PyCapsule_GetPointer(schema_capsule, 'arrow_schema'))

  cdef __arrow_c_schema__(self):
    cdef ArrowSchema* arrow_schema
    genomicsdb_allocate_arrow_schema(&arrow_schema, self._schema_ptr)
    return PyCapsule_New(arrow_schema, 'arrow_schema', &pycapsule_delete_arrow_schema)

  @property
  def n_children(self):
    return self._schema_ptr.n_children

  def child(self, int64_t i):
    return _ArrowSchemaWrapper(self._base,
                               <uintptr_t>self._schema_ptr.children[i])

  @property
  def children_schema(self):
    return list((self._schema_ptr.children[i].name.decode("UTF-8"),
                 c_arrow_type_from_format(self._schema_ptr.children[i].format))
                for i in range(self.n_children))
  

cdef class _ArrowArrayWrapper:
  cdef object _base
  cdef ArrowArray* _array_ptr
  cdef _ArrowSchemaWrapper _schema

  def __cinit__(self, object base, uintptr_t array_ptr, _ArrowSchemaWrapper schema):
    self._base = base
    self._array_ptr = <ArrowArray*>array_ptr
    self._schema = schema
    
  @staticmethod
  def _import_from_c_capsule(schema_capsule, array_capsule):
    schema = _ArrowSchemaWrapper._import_from_c_capsule(schema_capsule)
    return  _ArrowArrayWrapper(array_capsule,
                               <uintptr_t>PyCapsule_GetPointer(array_capsule, 'arrow_array'),
                               schema)
      
  def __arrow_c_array__(self, requested_schema=None):
    #if requested_schema is not None:
    #  raise NotImplementedError("requested_schema as an argument not supported in _import_from_c_capsule")
    return self._schema.__arrow_c_schema__(), self._base
  
  @property
  def n_children(self):
    return self._array_ptr.n_children

  def child(self, int64_t i):
    schema_capsule = self._schema.child(i)
    array_capsule = pycapsule_get_arrow_array(self._array_ptr.children[i])
    return _ArrowArrayWrapper(array_capsule,
                              <uintptr_t>self._array_ptr.children[i],
                              self._schema.child(i))

  @property
  def children(self):
    for i in range(self.n_children):
      yield self.child[i]
