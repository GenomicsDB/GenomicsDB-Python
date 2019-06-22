# distutils: language = c++
# cython: language_level=3

from libcpp.pair cimport pair
from libcpp.string cimport string
from libcpp.vector cimport vector
from libc.stdint cimport (int64_t, uint64_t, uintptr_t)

from cpython.bytes cimport (PyBytes_GET_SIZE,
                            PyBytes_AS_STRING,
                            PyBytes_Size,
                            PyBytes_FromString,
                            PyBytes_FromStringAndSize)

from cpython.version cimport PY_MAJOR_VERSION

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

cdef extern from "genomicsdb.h":
	cdef string genomicsdb_version()

	cdef cppclass GenomicsDB:
		GenomicsDB(string, string, string, string, vector[string], uint64_t) except +
		GenomicsDB(string, string, int) except +

	pass

def version():
	version_string = genomicsdb_version()
	return version_string

def connect(workspace, callset_mapping_file, vid_mapping_file, reference_genome, attributes, segment_size):
#	cdef string s = PyBytes_AS_STRING(to_unicode(workspace).encode('UTF-
	cdef vector[string] attributes_vec 

	gdb = new GenomicsDB(as_string(workspace), 
											 as_string(callset_mapping_file), 
											 as_string(vid_mapping_file),
											 as_string(reference_genome),
											 attributes_vec, 
											 segment_size)
	print("Got instance of Genomicsdb")

def disconnect(gdb):
	del gdb



