
#pragma once

#include "genomicsdb.h"

#include <algorithm>
#include <cstring>
#include <iostream>
#include <cmath>

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

#define STRING_FIELD(NAME, TYPE) (TYPE.is_string() || TYPE.is_char() || TYPE.num_elements > 1 || (NAME.compare("GT") == 0))
#define INT_FIELD(TYPE) (TYPE.is_int())
#define FLOAT_FIELD(TYPE) (TYPE.is_float())

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
  PyObject* construct_data_frame() {
    int dims = 1;
    npy_intp sizes[1] = { static_cast<npy_intp>(m_rows.size()) };
    PyObject *calls = PyDict_New();
    PyDict_SetItem(calls, PyUnicode_FromString("Row"), PyArray_SimpleNewFromData(dims, sizes, NPY_INT64, m_rows.data()));
    PyDict_SetItem(calls, PyUnicode_FromString("Col"), PyArray_SimpleNewFromData(dims, sizes, NPY_INT64, m_cols.data()));
    PyDict_SetItem(calls, PyUnicode_FromString("Sample"), PyArray_SimpleNewFromData(dims, sizes, NPY_OBJECT, m_sample_names.data()));
    PyDict_SetItem(calls, PyUnicode_FromString("CHROM"), PyArray_SimpleNewFromData(dims, sizes, NPY_OBJECT, m_chrom.data()));
    PyDict_SetItem(calls, PyUnicode_FromString("POS"), PyArray_SimpleNewFromData(dims, sizes, NPY_INT64, m_pos.data()));
    PyDict_SetItem(calls, PyUnicode_FromString("END"), PyArray_SimpleNewFromData(dims, sizes, NPY_INT64, m_end.data()));

    for (auto field_name: m_field_names) {
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
  
  std::vector<int64_t> m_rows;
  std::vector<int64_t> m_cols;
  std::vector<PyObject *> m_sample_names;
  std::vector<PyObject *> m_chrom;
  std::vector<uint64_t> m_pos;
  std::vector<uint64_t> m_end;
  std::vector<std::string> m_field_names;
  std::map<std::string, std::vector<PyObject *>> m_string_fields;
  std::map<std::string, std::vector<int>> m_int_fields;
  std::map<std::string, std::vector<float>> m_float_fields;
};
