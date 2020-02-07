#include "genomicsdb.h"

#include <cstring>
#include <iostream>
#include <Python.h>
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
