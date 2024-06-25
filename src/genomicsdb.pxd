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
# Description : Python bindings to the native GenomicsDB Library
#

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

    cdef string resolve_gt(vector[genomic_field_t])

    cdef cppclass GenomicsDBVariantCallProcessor:
        GenomicsDBVariantCallProcessor() except +
        void process(interval_t)
        void process(uint32_t, genomic_interval_t, vector[genomic_field_t])

    cdef enum payload_t "JSONVariantCallProcessor::payload_t":
        PAYLOAD_ALL " JSONVariantCallProcessor::all",
        PAYLOAD_ALL_BY_CALLS "JSONVariantCallProcessor::all_by_calls",
        PAYLOAD_SAMPLES_WITH_NUM_CALLS "JSONVariantCallProcessor::samples_with_ncalls",
        PAYLOAD_SAMPLES "JSONVariantCallProcessor::just_samples",
        PAYLOAD_NUM_CALLS "JSONVariantCallProcessor::just_ncalls",

    cdef cppclass JSONVariantCallProcessor(GenomicsDBVariantCallProcessor):
        JSONVariantCallProcessor() except +
        JSONVariantCallProcessor(payload_t) except +
        void set_payload_mode(payload_t)
        void process(interval_t) except +
        void process(uint32_t, genomic_interval_t, vector[genomic_field_t]) except +
        string construct_json_output() except +
        pass

    cdef cppclass ArrowVariantCallProcessor(GenomicsDBVariantCallProcessor):
        ArrowVariantCallProcessor() except +
        ArrowVariantCallProcessor(bool) except +
        void set_batching(bool)
        void* arrow_schema() except + nogil
        void* arrow_array() except + nogil
        pass

    cdef enum query_config_type_t "GenomicsDB::query_config_type_t":
        GENOMICSDB_NONE "GenomicsDB::NONE",
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

        # query_variant_calls(const std::string& array, genomicsdb_ranges_t column_ranges=SCAN_FULL, genomicsdb_ranges_t row_ranges={});
        GenomicsDBVariantCalls query_variant_calls(string, genomicsdb_ranges_t, genomicsdb_ranges_t) except + nogil
        GenomicsDBVariantCalls query_variant_calls(string, genomicsdb_ranges_t) except + nogil
        GenomicsDBVariantCalls query_variant_calls(string) except + nogil

        GenomicsDBVariantCalls query_variant_calls() except + nogil

        # query_variant_calls(GenomicsDBVariantCallProcessor& processor, const std::string& array,
        #                       genomicsdb_ranges_t column_ranges=SCAN_FULL, genomicsdb_ranges_t row_ranges={});
        GenomicsDBVariantCalls query_variant_calls(GenomicsDBVariantCallProcessor, string, genomicsdb_ranges_t, genomicsdb_ranges_t) except + nogil
        GenomicsDBVariantCalls query_variant_calls(GenomicsDBVariantCallProcessor, string, genomicsdb_ranges_t) except + nogil

        # query_variant_calls(GenomicsDBVariantCallProcessor& processor, const std::string& query_configuration,
        #                                                                const query_config_type_t query_configuration_type);
        GenomicsDBVariantCalls query_variant_calls(GenomicsDBVariantCallProcessor, string, query_config_type_t) except + nogil

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

#   Apache Arrow C data structures so we do not have to import (nano)arrow_c

    cdef struct ArrowSchema:
        const char* format
        const char* name
        const char* metadata
        int64_t flags
        int64_t n_children
        ArrowSchema** children
        ArrowSchema* dictionary
        void (*release)(ArrowSchema*)
        pass

    cdef struct ArrowArray:
         int64_t length
         int64_t null_count
         int64_t offset
         int64_t n_buffers
         int64_t n_children;
         const void** buffers
         ArrowArray** children
         ArrowArray* dictionary
         void (*release)(ArrowArray*)
         pass

    cdef enum ArrowType:
        NANOARROW_TYPE_UNINITIALIZED = 0
        NANOARROW_TYPE_NA = 1
        NANOARROW_TYPE_BOOL
        NANOARROW_TYPE_UINT8
        NANOARROW_TYPE_INT8
        NANOARROW_TYPE_UINT16
        NANOARROW_TYPE_INT16
        NANOARROW_TYPE_UINT32
        NANOARROW_TYPE_INT32
        NANOARROW_TYPE_UINT64
        NANOARROW_TYPE_INT64
        NANOARROW_TYPE_HALF_FLOAT
        NANOARROW_TYPE_FLOAT
        NANOARROW_TYPE_DOUBLE
        NANOARROW_TYPE_STRING
        NANOARROW_TYPE_BINARY
        NANOARROW_TYPE_FIXED_SIZE_BINARY
        NANOARROW_TYPE_DATE32
        NANOARROW_TYPE_DATE64
        NANOARROW_TYPE_TIMESTAMP
        NANOARROW_TYPE_TIME32
        NANOARROW_TYPE_TIME64
        NANOARROW_TYPE_INTERVAL_MONTHS
        NANOARROW_TYPE_INTERVAL_DAY_TIME
        NANOARROW_TYPE_DECIMAL128
        NANOARROW_TYPE_DECIMAL256
        NANOARROW_TYPE_LIST
        NANOARROW_TYPE_STRUCT
        NANOARROW_TYPE_SPARSE_UNION
        NANOARROW_TYPE_DENSE_UNION
        NANOARROW_TYPE_DICTIONARY
        NANOARROW_TYPE_MAP
        NANOARROW_TYPE_EXTENSION
        NANOARROW_TYPE_FIXED_SIZE_LIST
        NANOARROW_TYPE_DURATION
        NANOARROW_TYPE_LARGE_STRING
        NANOARROW_TYPE_LARGE_BINARY
        NANOARROW_TYPE_LARGE_LIST
        NANOARROW_TYPE_INTERVAL_MONTH_DAY_NANO

    # Apache Arrow wrappers to (nano)arrow functionality via genomicsdb libraries

    cdef void genomicsdb_cleanup_arrow_schema(void*)
    cdef void genomicsdb_cleanup_arrow_array(void*)
    cdef int genomicsdb_allocate_arrow_schema(ArrowSchema**, ArrowSchema*)

# Filesystem and other Utilities
cdef extern from "genomicsdb_utils.h":
    cdef string c_version "genomicsdb::version"()
    cdef bint c_is_file "genomicsdb::is_file"(string)
    cdef ssize_t c_file_size "genomicsdb::file_size"(string)
    cdef int c_read_entire_file "genomicsdb::read_entire_file"(string, void**, size_t*)
    pass

