# distutils: language = c++
# cython: language_level=3

include "utils.pxi"

import tempfile
import pandas as pd

def version():
    """Print out version of the GenomicsDB native library
    
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
            callset_mapping_file = "callset.json",
            vid_mapping_file = "vidmap.json",
            reference_genome = None,
            attributes = None,
            segment_size = None):
    """Connect to an existing GenomicsDB Workspace.
    
    Parameters
    ----------
    workspace : str
        Path to the GenomicsDB workspace.
    callset_mapping_file : str, optional
        Path to a json file describing callset mappings, by default "callset.json"
    vid_mapping_file : str, optional
        Path to a json file describing vid mappings, by default "vidmap.json"
    reference_genome : str, optional
        Path to the reference genome file, by default None
    attributes : list, optional
        List of attributes to be queried, by default None. All attributes will be queried if None.
    segment_size : int, optional
        Segment Size, by default None. Allow GenomicsDB to configure one.
    
    Returns
    -------
    GenomicsDB
        GenomicsDB instance ready for queries
    
    Raises
    ------
    GenomicsDBException
         On failure to connect to the native GenomicsDB library
    """    
    try:
        return _GenomicsDB(workspace, callset_mapping_file, vid_mapping_file,
                           reference_genome, attributes, segment_size)
    except:
        raise GenomicsDBException("Failed to connect to the native GenomicsDB library")

def connect_transcriptomics(workspace,
                            callset_mapping_file = None,
                            vid_mapping_file = None,
                            gtf_name = None,
                            gi_name = None,
                            segment_size = None):

    try:
        return _GenomicsDBTranscriptomics(workspace, callset_mapping_file, vid_mapping_file,
                                          gtf_name, gi_name, segment_size)
    except:
        raise GenomicsDBException("Failed to connect to the native GenomicsDB library for transcriptomics style data")

cdef class _GenomicsDB:
    cdef GenomicsDB* _genomicsdb

    def __cinit__(self):
        self._genomicsdb = NULL

    def __init__(self,
                 workspace,
                 callset_mapping_file,
                 vid_mapping_file,
                 reference_genome = None,
                 attributes = None,
                 segment_size = None):
        cdef string ws = as_string(workspace)
        cdef vector[string] vec = as_vector(attributes)
        if reference_genome is None:
            self._genomicsdb  = new GenomicsDB(as_string(workspace),
                                               as_string(callset_mapping_file),
                                               as_string(vid_mapping_file),
                                               as_string(""))
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
        """ Query for variant calls from the GenomicsDB workspace using array, column_ranges and row_ranges for subsetting """

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

    def to_vcf(self,
               array=None,
               column_ranges=None,
               row_ranges=None,
               output=None,
               output_format=None,
               overwrite=False):
        """ Generate vcf from the GenomicsDB workspace using array, column_ranges and row_ranges for subsetting """

        if output is None:
            output = ""
        if output_format is None:
            output_format = ""
        if array is None:
            self._genomicsdb.generate_vcf(as_string(output),
                                          as_string(output_format),
                                          overwrite)
        else:
            self._genomicsdb.generate_vcf(as_string(array),
                                          as_ranges(column_ranges),
                                          as_ranges(row_ranges),
                                          as_string(output),
                                          as_string(output_format),
                                          overwrite)


    def __dealloc__(self):
        if self._genomicsdb != NULL:
            del self._genomicsdb

cdef class _GenomicsDBTranscriptomics:
    cdef GenomicsDBTranscriptomics* _genomicsdb_transcriptomics

    def __cinit__(self):
        self._genomicsdb_transcriptomics = NULL

    def __init__(self,
                 workspace,
                 callset_mapping_file = None,
                 vid_mapping_file = None,
                 gtf_name = None,
                 gi_name = None,
                 segment_size = None):

        if callset_mapping_file is None:
            self._genomicsdb_transcriptomics = new GenomicsDBTranscriptomics(as_string(workspace))

        elif vid_mapping_file is None:
            self._genomicsdb_transcriptomics = new GenomicsDBTranscriptomics(as_string(workspace),
                                                                             as_string(callset_mapping_file))

        elif gtf_name is None:
            self._genomicsdb_transcriptomics = new GenomicsDBTranscriptomics(as_string(workspace),
                                                                             as_string(callset_mapping_file),
                                                                             as_string(vid_mapping_file))

        elif gi_name is None:
            self._genomicsdb_transcriptomics = new GenomicsDBTranscriptomics(as_string(workspace),
                                                                             as_string(callset_mapping_file),
                                                                             as_string(vid_mapping_file),
                                                                             as_string(gtf_name))

        elif segment_size is None:
            self._genomicsdb_transcriptomics = new GenomicsDBTranscriptomics(as_string(workspace),
                                                                             as_string(callset_mapping_file),
                                                                             as_string(vid_mapping_file),
                                                                             as_string(gtf_name),
                                                                             as_string(gi_name))

        else:
            self._genomicsdb_transcriptomics = new GenomicsDBTranscriptomics(as_string(workspace),
                                                                             as_string(callset_mapping_file),
                                                                             as_string(vid_mapping_file),
                                                                             as_string(gtf_name),
                                                                             as_string(gi_name),
                                                                             segment_size)

    def query_variant_calls(self,
                            array,
                            column_ranges = None,
                            row_ranges = None):
        cdef vector[transcriptomics_cell] retval
        if column_ranges is None:
            retval = self._genomicsdb_transcriptomics.query_variant_calls(as_string(array))
        
        elif row_ranges is None:
            retval = self._genomicsdb_transcriptomics.query_variant_calls(as_string(array), as_ranges(column_ranges))

        else:
            retval = self._genomicsdb_transcriptomics.query_variant_calls(as_string(array), as_ranges(column_ranges), as_ranges(row_ranges))


        l = []
        for cell in retval:
            d = dict()
            d["start"] = cell.start
            d["end"] = cell.end
            d["sample_idx"] = cell.sample_idx
            d["position"] = cell.position
            #d["file_idx"] = cell.file_idx # not defined in this context
            d["score"] = cell.score
            d["name"] = cell.name
            d["gene"] = cell.gene
            l.append(d)

        return pd.DataFrame(l, columns=["start", "end", "sample_idx", "position", "score", "name", "gene"])
        #return l

    def __dealloc__(self):
        if self._genomicsdb_transcriptomics != NULL:
            del self._genomicsdb_transcriptomics
