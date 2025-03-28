/**
 * @file genomicsdb_processor.h
 *
 * @section LICENSE
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2023 dātma, inc™
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * @section DESCRIPTION
 *
 * Specifications to the GenomicsDBVariantProcessors implemented in GenomicsDB-Python.
 * In addition, JSONVariantCallProcessor implemented in GenomicsDB is also used(see
 * genomicsdb.h)
 *
 **/

#pragma once

#include "genomicsdb.h"

#include <algorithm>
#include <cstring>
#include <iostream>
#include <cmath>
#include <semaphore>

#include <Python.h>

#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION
#include "numpy/arrayobject.h"

#include <stdio.h>

#define THROW_GENOMICSDB_EXCEPTION(MSG)                      \
do {                                                         \
    std::string errmsg = std::string("GenomicsDB-Python: (") \
        + __func__ + ") " + MSG;                             \
    if (errno > 0) {                                         \
      errmsg += "; errno=" + std::to_string(errno)           \
          + "(" + std::string(std::strerror(errno)) + ")";   \
    }                                                        \
    throw new GenomicsDBException(errmsg);                   \
  } while (false)


class VariantCallProcessor : public GenomicsDBVariantCallProcessor {
 public:
  VariantCallProcessor();
  ~VariantCallProcessor();
  void set_root(PyObject*);
  void initialize(const std::vector<genomic_field_type_t> genomic_field_types);
  void process(const interval_t&);
  void process(const std::string& sample_name,
               const int64_t* coordinates,
               const genomic_interval_t& genomic_interval,
               const std::vector<genomic_field_t>& genomic_fields);
 private:
  void initialize_interval();
  void finalize_interval();
  int wrap_fields(PyObject* dict, std::vector<genomic_field_t> fields);
  interval_t _current_interval;
  PyObject* _current_calls_list = NULL;
  PyObject* _intervals_list = NULL;
};

class ColumnarVariantCallProcessor : public GenomicsDBVariantCallProcessor {
 public:
  ColumnarVariantCallProcessor() {
    _import_array();
  }
  void process(const interval_t& interval);
  void process_fields(const std::vector<genomic_field_t>& genomic_fields);
  void process(const std::string& sample_name,
               const int64_t* coordinates,
               const genomic_interval_t& genomic_interval,
               const std::vector<genomic_field_t>& genomic_fields);
  void process_str_field(const std::string& field_name, PyObject *calls, int dims, npy_intp *sizes) {
    auto found = std::find(m_field_names.begin(), m_field_names.end(), field_name);
    if (found != m_field_names.end()) {
        PyDict_SetItem(calls, PyUnicode_FromString(field_name.c_str()),
                       PyArray_SimpleNewFromData(dims, sizes, NPY_OBJECT, m_string_fields[field_name].data()));
    }
  }
  PyObject* construct_data_frame() {
    int dims = 1;
    npy_intp sizes[1] = { static_cast<npy_intp>(m_sample_names.size()) };
    PyObject *calls = PyDict_New();
    PyDict_SetItem(calls, PyUnicode_FromString("Sample"), PyArray_SimpleNewFromData(dims, sizes, NPY_OBJECT, m_sample_names.data()));
    PyDict_SetItem(calls, PyUnicode_FromString("CHR"), PyArray_SimpleNewFromData(dims, sizes, NPY_OBJECT, m_chrom.data()));
    PyDict_SetItem(calls, PyUnicode_FromString("POS"), PyArray_SimpleNewFromData(dims, sizes, NPY_INT64, m_pos.data()));
    // Process REF, ALT and GT first.
    process_str_field("REF", calls, dims, sizes);
    process_str_field("ALT", calls, dims, sizes);
    process_str_field("GT", calls, dims, sizes);
    for (auto field_name: m_field_names) {
      if (field_name == "REF" || field_name == "ALT" || field_name == "GT") continue;
      if (m_string_fields.find(field_name) != m_string_fields.end()) {
        PyDict_SetItem(calls, PyUnicode_FromString(field_name.c_str()),
                       PyArray_SimpleNewFromData(dims, sizes, NPY_OBJECT, m_string_fields[field_name].data()));
      } else if (m_int_fields.find(field_name) != m_int_fields.end()) {
        PyDict_SetItem(calls, PyUnicode_FromString(field_name.c_str()),
                       PyArray_SimpleNewFromData(dims, sizes, NPY_INT, m_int_fields[field_name].data()));
      } else if (m_float_fields.find(field_name) != m_float_fields.end()) {
        PyDict_SetItem(calls, PyUnicode_FromString(field_name.c_str()),
                       PyArray_SimpleNewFromData(dims, sizes, NPY_FLOAT, m_float_fields[field_name].data()));
      } else {
        std::string msg = "Genomic field type for " + field_name + " not supported";
        THROW_GENOMICSDB_EXCEPTION(msg.c_str());
      }
    }
    return calls;
  }

 private:
  bool m_is_initialized = false;
  
  std::vector<PyObject *> m_sample_names;
  std::vector<PyObject *> m_chrom;
  std::vector<uint64_t> m_pos;
  std::vector<std::string> m_field_names;
  std::map<std::string, std::vector<PyObject *>> m_string_fields;
  std::map<std::string, std::vector<int>> m_int_fields;
  std::map<std::string, std::vector<float>> m_float_fields;
};

// Forward declarations for Arrow types
//struct ArrowSchema;
//struct ArrowArray;

struct ArrowSchema {
  // Array type description
  const char* format;
  const char* name;
  const char* metadata;
  int64_t flags;
  int64_t n_children;
  struct ArrowSchema** children;
  struct ArrowSchema* dictionary;

  // Release callback
  void (*release)(struct ArrowSchema*);
  // Opaque producer-specific data
  void* private_data;
};

struct ArrowArray {
  // Array data description
  int64_t length;
  int64_t null_count;
  int64_t offset;
  int64_t n_buffers;
  int64_t n_children;
  const void** buffers;
  struct ArrowArray** children;
  struct ArrowArray* dictionary;

  // Release callback
  void (*release)(struct ArrowArray*);
  // Opaque producer-specific data
  void* private_data;
};

enum ArrowType {
  NANOARROW_TYPE_UNINITIALIZED = 0,
  NANOARROW_TYPE_NA = 1,
  NANOARROW_TYPE_BOOL,
  NANOARROW_TYPE_UINT8,
  NANOARROW_TYPE_INT8,
  NANOARROW_TYPE_UINT16,
  NANOARROW_TYPE_INT16,
  NANOARROW_TYPE_UINT32,
  NANOARROW_TYPE_INT32,
  NANOARROW_TYPE_UINT64,
  NANOARROW_TYPE_INT64,
  NANOARROW_TYPE_HALF_FLOAT,
  NANOARROW_TYPE_FLOAT,
  NANOARROW_TYPE_DOUBLE,
  NANOARROW_TYPE_STRING,
  NANOARROW_TYPE_BINARY,
  NANOARROW_TYPE_FIXED_SIZE_BINARY,
  NANOARROW_TYPE_DATE32,
  NANOARROW_TYPE_DATE64,
  NANOARROW_TYPE_TIMESTAMP,
  NANOARROW_TYPE_TIME32,
  NANOARROW_TYPE_TIME64,
  NANOARROW_TYPE_INTERVAL_MONTHS,
  NANOARROW_TYPE_INTERVAL_DAY_TIME,
  NANOARROW_TYPE_DECIMAL128,
  NANOARROW_TYPE_DECIMAL256,
  NANOARROW_TYPE_LIST,
  NANOARROW_TYPE_STRUCT,
  NANOARROW_TYPE_SPARSE_UNION,
  NANOARROW_TYPE_DENSE_UNION,
  NANOARROW_TYPE_DICTIONARY,
  NANOARROW_TYPE_MAP,
  NANOARROW_TYPE_EXTENSION,
  NANOARROW_TYPE_FIXED_SIZE_LIST,
  NANOARROW_TYPE_DURATION,
  NANOARROW_TYPE_LARGE_STRING,
  NANOARROW_TYPE_LARGE_BINARY,
  NANOARROW_TYPE_LARGE_LIST,
  NANOARROW_TYPE_INTERVAL_MONTH_DAY_NANO
};
     
void genomicsdb_cleanup_arrow_schema(void *schema);
void genomicsdb_cleanup_arrow_array(void *array);
void genomicsdb_print_array_children(void *array);
int64_t get_nchildren(ArrowArray* array);
ArrowArray** get_children(ArrowArray* array);
int genomicsdb_allocate_arrow_schema(ArrowSchema** schema, ArrowSchema *src);
