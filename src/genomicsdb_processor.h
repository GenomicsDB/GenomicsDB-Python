#include "genomicsdb.h"

#include <functional>

class VariantCallProcessor : public GenomicsDBVariantCallProcessor {  
 public:
  VariantCallProcessor();

  void setup_callbacks(std::function<void(interval_t)>, std::function<void(uint32_t, genomic_interval_t, std::vector<genomic_field_t>)>);

  void process(interval_t);

  void process(uint32_t, genomic_interval_t, std::vector<genomic_field_t>);

  std::function<void(interval_t)> _process_interval_callback;
  std::function<void(uint32_t, genomic_interval_t, std::vector<genomic_field_t>)> _process_variant_call_callback;

};
