#include "genomicsdb.h"
#include "genomicsdb_processor.h"

VariantCallProcessor::VariantCallProcessor() {
  initialize_interval();
}

VariantCallProcessor::~VariantCallProcessor() {
  finalize_interval();
}

void VariantCallProcessor::set_root(PyObject *intervals_list) {
  _intervals_list = intervals_list;
}

void VariantCallProcessor::process(const interval_t& interval) {
  finalize_interval();
  _current_interval = interval;
}

void VariantCallProcessor::initialize_interval() {
  errno = 0;
  _current_calls_list = PyList_New(0);
  if (!_current_calls_list) {
    THROW_GENOMICSDB_EXCEPTION("Could not instantiate python list");
  }
}

PyObject* wrap_field(genomic_field_t field, genomic_field_type_t field_type, uint64_t offset) {
  PyObject* py_object;
  if (field_type.is_char()) {
    py_object =  PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, ((char *)field.ptr)+offset, 1);
  } else if (field_type.is_int()) {
    py_object = PyLong_FromLong(field.int_value_at(offset));
  } else if (field_type.is_float()) {
    py_object = PyFloat_FromDouble(field.float_value_at(offset));
  } else if (field_type.is_string()) {
    assert(offset == 0);
    py_object = PyUnicode_FromString(field.to_string(field_type).c_str());
  } else {
    THROW_GENOMICSDB_EXCEPTION("Failed to recognize the genomic field type");
  }
  if (py_object == Py_None) {
    THROW_GENOMICSDB_EXCEPTION("Could not construct Python Object for genomic fields");
  }
  return py_object;
}

int VariantCallProcessor::wrap_fields(PyObject* call, std::vector<genomic_field_t> fields) {
  int rc = 0;
  for (auto field: fields) {
    if (field.num_elements == 1 || get_genomic_field_type(field.name).is_string()) {
      rc = rc || PyDict_SetItem(call, PyUnicode_FromString(field.name.c_str()), wrap_field(field, get_genomic_field_type(field.name), 0));
    } else if (field.name.compare("GT") == 0) {
      // Treat genotypes separately
      PyDict_SetItem(call, PyUnicode_FromString("GT"), PyUnicode_FromString(field.to_string(get_genomic_field_type(field.name)).c_str()));
    } else {
      PyObject *list = PyList_New(field.num_elements);
      for (auto i=0ul; i<field.num_elements; i++) {
        PyList_SetItem(list, i, wrap_field(field, get_genomic_field_type(field.name), i));
      }
      PyDict_SetItem(call, PyUnicode_FromString(field.name.c_str()), list);
    }
  }
  return rc;
}

void VariantCallProcessor::process(const std::string& sample_name,
               const int64_t* coordinates,
               const genomic_interval_t& genomic_interval,
               const std::vector<genomic_field_t>& fields) {
  errno = 0;
  PyObject *call = PyDict_New();
  if (call) {
    int rc = PyDict_SetItem(call, PyUnicode_FromString("Row"), PyLong_FromLongLong(coordinates[0])) ||
        PyDict_SetItem(call, PyUnicode_FromString("Col"), PyLong_FromLongLong(coordinates[1])) ||
        PyDict_SetItem(call, PyUnicode_FromString("Sample"), PyUnicode_FromString(sample_name.c_str())) ||
        PyDict_SetItem(call, PyUnicode_FromString("CHROM"), PyUnicode_FromString(genomic_interval.contig_name.c_str())) ||
        PyDict_SetItem(call, PyUnicode_FromString("POS"), PyLong_FromLong(genomic_interval.interval.first)) ||
        PyDict_SetItem(call, PyUnicode_FromString("END"), PyLong_FromLong(genomic_interval.interval.second)) ||
        wrap_fields(call, fields);
    if (rc ) {
      THROW_GENOMICSDB_EXCEPTION("Could not set up Python Dictionary for calls. rc=" + std::to_string(rc));
    }
    
    // Add to current list
    if (PyList_Append( _current_calls_list, call)) {
      THROW_GENOMICSDB_EXCEPTION("Failed to append to python list");
    }
    
    // Decrement refcount as PyList_Append does not steal the reference from call
    Py_DECREF(call);
  } else {
    THROW_GENOMICSDB_EXCEPTION("Could not instantiate Python Dictionary for calls");
  }
}

void VariantCallProcessor::finalize_interval() {
  errno = 0;
  if (PyObject_Length(_current_calls_list) > 0) {
    PyObject *interval = PyTuple_New(3);
    if (interval) {
      if (PyTuple_SetItem(interval, 0, PyLong_FromLong(_current_interval.first))
          || PyTuple_SetItem(interval, 1, PyLong_FromLong(_current_interval.second))
          || PyTuple_SetItem(interval, 2, _current_calls_list)) {
        THROW_GENOMICSDB_EXCEPTION("Failed to setup python tuples");
      }
      if (_intervals_list) {
        if (PyList_Append(_intervals_list, interval)) {
           THROW_GENOMICSDB_EXCEPTION("Failed to append to python list");
        }
        // Decrement refcount as PyList_Append does not steal the reference from interval
        Py_DECREF(interval);
      }
      initialize_interval();
    } else {
      THROW_GENOMICSDB_EXCEPTION("Could not instantiate python list");
    }
  }
}


