#include "genomicsdb.h"
#include "genomicsdb_processor.h"


void genomicsdb_cleanup_arrow_schema(void *schema) {
  return ArrowVariantCallProcessor::cleanup_schema(schema);
}

void genomicsdb_cleanup_arrow_array(void *array) {
  return ArrowVariantCallProcessor::cleanup_array(array);
}

int genomicsdb_allocate_arrow_schema(ArrowSchema** schema, ArrowSchema *src) {
  int rc = ArrowVariantCallProcessor::allocate_schema((void **)schema, src);
  if (!rc) {
    // To ensure only the capsule destructor doesn't call a random release ptr
    // schema[0]->release = NULL;
  }
  return rc;
}
