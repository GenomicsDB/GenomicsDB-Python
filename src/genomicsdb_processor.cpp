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

void VariantCallProcessor::process(const interval_t interval) {
  finalize_interval();
  _current_interval = interval;
}

PyObject* wrap_fields(const std::vector<genomic_field_t>& fields) {
  PyObject* dict_fields = PyDict_New();
  if (dict_fields) {
    for (auto field: fields) {
      if (PyDict_SetItemString(dict_fields,
                               field.first.c_str(),
                               PyUnicode_FromString(field.second.c_str()))) {
         THROW_GENOMICSDB_EXCEPTION("Failed to setup python dict");
      }
    }
  } else {
    THROW_GENOMICSDB_EXCEPTION("Could not instantiate python dict");
  }
  return dict_fields;
}

void VariantCallProcessor::process(const std::string& sample_name,
                                   const uint32_t row,
                                   const genomic_interval_t& genomic_interval,
                                   const std::vector<genomic_field_t>& genomic_fields) {
  errno = 0;
  PyObject *call = PyTuple_New(6);
  if (call) {
    if (PyTuple_SetItem(call, 0, PyUnicode_FromString(sample_name.c_str()))
        || PyTuple_SetItem(call, 1, PyLong_FromLong(row))
        || PyTuple_SetItem(call, 2, PyUnicode_FromString(genomic_interval.contig_name.c_str()))
        || PyTuple_SetItem(call, 3, PyLong_FromLong(genomic_interval.interval.first))
        ||PyTuple_SetItem(call, 4, PyLong_FromLong(genomic_interval.interval.second))) {

      THROW_GENOMICSDB_EXCEPTION("Failed to setup python tuples");
    }
    PyTuple_SetItem(call, 4, wrap_fields(genomic_fields));
    // Add to current list
    if (PyList_Append( _current_calls_list, call)) {
      THROW_GENOMICSDB_EXCEPTION("Failed to append to python list");
    }
    // Decrement refcount as PyList_Append does not steal the reference from call
    Py_DECREF(call);
  } else {
    THROW_GENOMICSDB_EXCEPTION("Could not instantiate python list");
  }
}

void VariantCallProcessor::initialize_interval() {
  errno = 0;
  _current_calls_list = PyList_New(0);
  if (!_current_calls_list) {
    THROW_GENOMICSDB_EXCEPTION("Could not instantiate python list");
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


