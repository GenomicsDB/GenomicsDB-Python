# distutils: language = c++
# cython: language_level=3

include "utils.pxi"

import os

def version():
    """Print out GenomicsDB C++ Version
    
    Returns
    -------
    str
        GenomicsDB Version
    """
    version_string = genomicsdb_version().decode("ascii")
    return version_string

class GenomicsDBException(Exception):
    pass
    
def connect(workspace,
            callset_mapping_file = None,
            vid_mapping_file = None,
            reference_genome = None,
            attributes = None,
            segment_size = None):
    """Connect to an existing GenomicsDB Workspace.
    
    Parameters
    ----------
    workspace : str
        Path to the GenomicsDB workspace.
    callset_mapping_file : [type], optional
        [description], by default None
    vid_mapping_file : [type], optional
        [description], by default None
    reference_genome : [type], optional
        [description], by default None
    attributes : [type], optional
        [description], by default None
    segment_size : [type], optional
        [description], by default None
    
    Returns
    -------
    [type]
        [description]
    
    Raises
    ------
    GenomicsDBException
         On failure to connect to the native GenomicsDB library
    """    
    if callset_mapping_file is None:
        callset_mapping_file = os.path.join(workspace, "callset.json")
    if vid_mapping_file is None:
        vid_mapping_file = os.path.join(workspace, "vidmap.json")
    try:
        return _GenomicsDB(workspace, callset_mapping_file, vid_mapping_file,
                           reference_genome, attributes, segment_size)
    except:
        raise GenomicsDBException("Failed to connect to the native GenomicsDB library")

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

