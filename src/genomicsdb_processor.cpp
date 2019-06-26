#include "genomicsdb.h"
#include "genomicsdb_processor.h"


VariantCallProcessor::VariantCallProcessor() {}

void VariantCallProcessor::setup_callbacks(std::function<void(interval_t)> interval_cb,
                                           std::function<void(uint32_t, genomic_interval_t, std::vector<genomic_field_t>)> variant_call_cb) {
  _process_interval_callback = interval_cb;
  _process_variant_call_callback = variant_call_cb;
}

void VariantCallProcessor::process(interval_t interval) {
  _process_interval_callback(interval);
}

void VariantCallProcessor::process(uint32_t row,
                                   genomic_interval_t genomic_interval,
                                   std::vector<genomic_field_t> fields) {
  _process_variant_call_callback(row, genomic_interval, fields); 
}
