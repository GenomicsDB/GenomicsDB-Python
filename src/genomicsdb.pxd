# distutils: language = c++
# cython: language_level=3

from libcpp.string cimport string

cdef extern from "genomicsdb.h":
	cdef string genomicsdb_version()

	cdef cppclass GenomicsDB:
		GenomicsDB(string, string, string, string, vector[string], uint64_t) except +
		GenomicsDB(string, string, int) except +

	pass
