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
  void process(const interval_t);
  void process(const std::string& sample_name,
               const uint32_t row,
               const genomic_interval_t& genomic_interval,
               const std::vector<genomic_field_t>& genomic_fields);
      //  void process(const std::string&, const uint32_t, const genomic_interval_t, const std::vector<genomic_field_t>&);
 private:
  void initialize_interval();
  void finalize_interval();
  interval_t _current_interval;
  PyObject* _current_calls_list = NULL;
  PyObject* _intervals_list = NULL;
};
