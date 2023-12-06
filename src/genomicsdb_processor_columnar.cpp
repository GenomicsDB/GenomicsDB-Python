/**
 * @file genomicsdb_processor_columnar.cc
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
 * Implementation of GenomicsDBVariantCallProcessor whose output is a pandas
 * data frome backed by (columnar) numpy lists per genomic field
 *
 **/

#include "genomicsdb.h"
#include "genomicsdb_processor.h"

void ColumnarVariantCallProcessor::process(const interval_t& interval) {
  if (!m_is_initialized) {
    m_is_initialized = true;
    auto& genomic_field_types = get_genomic_field_types();
    for (auto& field_type_pair : *genomic_field_types) {
      std::string field_name = field_type_pair.first;
      genomic_field_type_t field_type = field_type_pair.second;
      if (!field_name.compare("END") || !field_name.compare("REF") || !field_name.compare("ALT")) {
        continue;
      }
      m_field_names.push_back(field_name);
      if (STRING_FIELD(field_name, field_type)) {
        std::vector<PyObject *> str_vector;
        m_string_fields.emplace(std::make_pair(field_name, std::move(str_vector))) ;
      } else if (INT_FIELD(field_type)) {
        std::vector<int> int_vector;
        m_int_fields.emplace(std::make_pair(field_name, std::move(int_vector)));
      } else if (FLOAT_FIELD(field_type)) {
        std::vector<float> float_vector;
        m_float_fields.emplace(std::make_pair(field_name, std::move(float_vector)));
      } else {
        std::string msg = "Genomic field type for " + field_name + " not supported";
        THROW_GENOMICSDB_EXCEPTION(msg.c_str());
      }
    }
  }
}

void ColumnarVariantCallProcessor::process_fields(const std::vector<genomic_field_t>& genomic_fields) {
  for (auto field_name: m_field_names) {
    auto field_type = get_genomic_field_types()->at(field_name);
      
    bool found = false;
    for (auto genomic_field: genomic_fields) {
      if (genomic_field.name.compare(field_name) == 0) {
        if (STRING_FIELD(field_name, field_type)) {
          if (field_name == "GT") {
            m_string_fields[field_name].push_back(PyUnicode_FromString(
                resolve_gt(genomic_fields).c_str()));
          } else {
            m_string_fields[field_name].push_back(PyUnicode_FromString(
                genomic_field.to_string(field_type).c_str()));
          }
        } else if (INT_FIELD(field_type)) {
          m_int_fields[field_name].push_back(genomic_field.int_value_at(0));
        } else if (FLOAT_FIELD(field_type)) {
          m_float_fields[field_name].push_back( genomic_field.float_value_at(0));
        } else {
          std::string msg = "Genomic field type for " + field_name + " not supported";
          THROW_GENOMICSDB_EXCEPTION(msg.c_str());
        }
        found = true;
        break;
      }
    }
      
    if (!found) {
      if (STRING_FIELD(field_name, field_type)) {
        m_string_fields[field_name].push_back(PyUnicode_FromString(""));
      } else if (INT_FIELD(field_type)) {
        m_int_fields[field_name].push_back(-99999);
      } else if (FLOAT_FIELD(field_type)) {
        m_float_fields[field_name].push_back(std::nanf(""));
      } else {
        std::string msg = "Genomic field type for " + field_name + " not supported";
        THROW_GENOMICSDB_EXCEPTION(msg.c_str());
      }
    }
  }
}
  
void ColumnarVariantCallProcessor::process(const std::string& sample_name,
                                           const int64_t* coordinates,
                                           const genomic_interval_t& genomic_interval,
                                           const std::vector<genomic_field_t>& genomic_fields) {
  m_sample_names.push_back(PyUnicode_FromString(sample_name.c_str()));
  m_chrom.push_back(PyUnicode_FromString(genomic_interval.contig_name.c_str()));
  m_pos.push_back(genomic_interval.interval.first);
  process_fields(genomic_fields);
}

