# distutils: language = c++
# cython: language_level=3

from libcpp.pair cimport pair
from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.functional cimport function
from libc.stdint cimport (int32_t, uint32_t, int64_t, uint64_t, uintptr_t, INT64_MAX)
from libc.stdlib cimport malloc, free

from cpython cimport (PyObject, PyList_New)

cdef extern from "genomicsdb.h":
    cdef string genomicsdb_version()

#   GenomicsDB typedefs
    ctypedef pair[uint64_t, uint64_t] interval_t;

    cdef struct genomic_interval_t:
        string contig_name
        interval_t interval
        genomic_interval_t(string, interval_t)

    ctypedef pair[string, string] genomic_field_t

    cdef struct genomicsdb_variant_t:
        pass

    cdef struct genomicsdb_variant_call_t:
        pass

    ctypedef vector[pair[int64_t, int64_t]] genomicsdb_ranges_t;

    cdef cppclass GenomicsDBResults[T]:
        GenomicsDBResults(vector[T]*) except +
        size_t size()
        const T* at(size_t)
        inline const T* next()
        void free()

    ctypedef GenomicsDBResults[genomicsdb_variant_t] GenomicsDBVariants
    ctypedef GenomicsDBResults[genomicsdb_variant_call_t] GenomicsDBVariantCalls

    cdef cppclass GenomicsDBVariantCallProcessor:
        GenomicsDBVariantCallProcessor() except +
        void process(interval_t)
        void process(uint32_t, genomic_interval_t, vector[genomic_field_t])

    cdef enum query_config_type_t "GenomicsDB::query_config_type_t":
        GENOMICSDB_JSON_FILE "GenomicsDB::JSON_FILE",
        GENOMICSDB_JSON_STRING "GenomicsDB::JSON_STRING",
        GENOMICSDB_PROTOBUF_BINARY_STRING "GenomicsDB::PROTOBUF_BINARY_STRING"

#   GenomicsDB Class

    cdef cppclass GenomicsDB:
        GenomicsDB(string, string, string, vector[string], uint64_t) except +
        GenomicsDB(string, string, string, vector[string]) except +
        GenomicsDB(string, string, string) except +
        GenomicsDB(string, query_config_type_t, string, int) except +
        GenomicsDB(string, query_config_type_t, string) except +
        GenomicsDB(string, query_config_type_t) except +
        GenomicsDB(string) except +
        GenomicsDBVariants query_variants(string, genomicsdb_ranges_t, genomicsdb_ranges_t) except +
        GenomicsDBVariants query_variants()
        GenomicsDBVariantCalls query_variant_calls(GenomicsDBVariantCallProcessor, string, genomicsdb_ranges_t, genomicsdb_ranges_t) except +
        GenomicsDBVariantCalls query_variant_calls(string, genomicsdb_ranges_t, genomicsdb_ranges_t) except +
        GenomicsDBVariantCalls query_variant_calls(GenomicsDBVariantCallProcessor, string, genomicsdb_ranges_t) except +
        GenomicsDBVariantCalls query_variant_calls(string, genomicsdb_ranges_t) except +
        GenomicsDBVariantCalls query_variant_calls(GenomicsDBVariantCallProcessor, string) except +
        GenomicsDBVariantCalls query_variant_calls(string) except +
        GenomicsDBVariantCalls query_variant_calls(GenomicsDBVariantCallProcessor) except +
        GenomicsDBVariantCalls query_variant_calls() except +
        void generate_vcf(string, genomicsdb_ranges_t, genomicsdb_ranges_t, string, string, string, string, bool) except +
        void generate_vcf(string, genomicsdb_ranges_t, genomicsdb_ranges_t, string, string, string, string) except +
        void generate_vcf(string, genomicsdb_ranges_t, genomicsdb_ranges_t, string, string, string) except +
        void generate_vcf(string, genomicsdb_ranges_t, genomicsdb_ranges_t, string, string) except +
        void generate_vcf(string, genomicsdb_ranges_t, genomicsdb_ranges_t, string) except +
        void generate_vcf(string, genomicsdb_ranges_t, genomicsdb_ranges_t) except +
        void generate_vcf(string, string, bool) except +
        void generate_vcf(string, string) except +
        void generate_vcf(string) except +
        void generate_vcf() except +
        pass

#   GenomicsDB Helper Utilities

    cdef interval_t get_interval(genomicsdb_variant_t*)
    cdef interval_t get_interval(genomicsdb_variant_call_t*)
    cdef genomic_interval_t get_genomic_interval(genomicsdb_variant_t*)
    cdef genomic_interval_t get_genomic_interval(genomicsdb_variant_call_t*)
    cdef vector[genomic_field_t] get_genomic_fields(string, genomicsdb_variant_t*)
    cdef vector[genomic_field_t] get_genomic_fields(string, genomicsdb_variant_call_t*)
    cdef GenomicsDBVariantCalls get_variant_calls(genomicsdb_variant_t*)
    cdef int64_t get_row(genomicsdb_variant_call_t*)
    pass

cdef extern from "genomicsdb_processor.h":
    cdef cppclass VariantCallProcessor(GenomicsDBVariantCallProcessor):
        VariantCallProcessor() except +
        void set_root(object)
        void process(interval_t) except +
        void process(uint32_t, genomic_interval_t, vector[genomic_field_t]) except +
        void finalize() except +
        pass

    cdef cppclass ColumnarVariantCallProcessor(GenomicsDBVariantCallProcessor):
        ColumnarVariantCallProcessor() except +
        void process(interval_t) except +
        void process(uint32_t, genomic_interval_t, vector[genomic_field_t]) except +
        object construct_data_frame() except +
        pass

# Filesystem and other Utilities
cdef extern from "genomicsdb_utils.h":
    cdef string c_version "genomicsdb::version"()
    cdef bint c_is_file "genomicsdb::is_file"(string)
    cdef ssize_t c_file_size "genomicsdb::file_size"(string)
    cdef int c_read_entire_file "genomicsdb::read_entire_file"(string, void**, size_t*)
    pass

