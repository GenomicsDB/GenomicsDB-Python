# distutils: language = c++
# cython: language_level=3

include "utils.pxi"

def version():
    version_string = genomicsdb_version()
    return version_string


def connect(workspace, callset_mapping_file, vid_mapping_file, reference_genome, attributes, segment_size):
    return _GenomicsDB(workspace, callset_mapping_file, vid_mapping_file, reference_genome, attributes, segment_size)

cdef class _GenomicsDB:
    cdef GenomicsDB* _genomicsdb

    def __cinit__(self):
        self._genomicsdb = NULL

    def __init__(self,
                 workspace,
                 callset_mapping_file,
                 vid_mapping_file,
                 reference_genome,
                 attributes = None,
                 segment_size = None):
        cdef string ws = as_string(workspace)
        cdef vector[string] vec = as_vector(attributes)
        if attributes is None:
            self._genomicsdb  = new GenomicsDB(as_string(workspace),
                                               as_string(callset_mapping_file),
                                               as_string(vid_mapping_file),
                                               as_string(reference_genome))
        elif segment_size is None:
            self._genomicsdb  = new GenomicsDB(as_string(workspace),
                                               as_string(callset_mapping_file),
                                               as_string(vid_mapping_file),
                                               as_string(reference_genome),
                                               as_vector(attributes))
        else:
            self._genomicsdb  = new GenomicsDB(as_string(workspace),
                                               as_string(callset_mapping_file),
                                               as_string(vid_mapping_file),
                                               as_string(reference_genome),
                                               as_vector(attributes),
                                               segment_size)

    def query_variant_calls(self,
                            array=None,
                            column_ranges=None,
                            row_ranges=None):
        cdef list variant_calls = []
        cdef VariantCallProcessor processor
        processor.set_root(variant_calls)
        if array is None:
            self._genomicsdb.query_variant_calls()
        elif column_ranges is None:
            self._genomicsdb.query_variant_calls(processor, as_string(array))
        elif row_ranges is None:
            self._genomicsdb.query_variant_calls(processor, as_string(array),
                                                 as_ranges(column_ranges))
        else:
            self._genomicsdb.query_variant_calls(processor, as_string(array),
                                                 as_ranges(column_ranges),
                                                 as_ranges(row_ranges))
        return variant_calls

    def __dealloc__(self):
        if self._genomicsdb != NULL:
            del self._genomicsdb

