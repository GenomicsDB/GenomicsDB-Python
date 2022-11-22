# distutils: language = c++
# cython: language_level=3

include "utils.pxi"

import tempfile

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
        return _GenomicsDB(workspace=workspace,
                           callset_mapping_file=callset_mapping_file,
                           vid_mapping_file=vid_mapping_file,
                           attributes=attributes,
                           segment_size=segment_size)
    except Exception as e:
        print(e)
        raise GenomicsDBException("Failed to connect to the native GenomicsDB library")

def connect_with_protobuf(query_protobuf, loader_json = None):
    """Connect to an existing GenomicsDB Workspace with protobuf.

    Parameters
    ----------
    query_protobuf : genomicsdb.protobuf.genomicsdb_export_config_pb2.ExportConfiguration
        The GenomicsDB Export Configuration protobuf object

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
        return _GenomicsDB(query_protobuf=query_protobuf.SerializeToString(), loader_json=loader_json)
    except Exception as e:
        print(e)
        raise GenomicsDBException("Failed to connect to the native GenomicsDB library using protobuf")

def connect_with_json(query_json, loader_json = None):
    """Connect to an existing GenomicsDB Workspace with json files.

    Parameters
    ----------
    query_json : str
        Path to a json file describing the query
    loader_json : str, optional
        Path to a json file describing the loader, by default None.
    
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
        return _GenomicsDB(query_json=query_json, loader_json=loader_json)
    except Exception as e:
        print(e)
        raise GenomicsDBException("Failed to connect to the native GenomicsDB library using json")

cdef class _GenomicsDB:
    cdef GenomicsDB* _genomicsdb

    def __init__(self, **kwargs):
        if 'query_protobuf' in kwargs  and 'loader_json' in kwargs and kwargs['loader_json'] is not None:
            self._genomicsdb = new GenomicsDB(as_protobuf_string(kwargs['query_protobuf']),
                                              GENOMICSDB_PROTOBUF_BINARY_STRING,
                                              as_string(kwargs['loader_json']))
        elif 'query_protobuf' in kwargs:
                self._genomicsdb = new GenomicsDB(as_protobuf_string(kwargs['query_protobuf']),
                                                  GENOMICSDB_PROTOBUF_BINARY_STRING)
        elif 'query_json' in kwargs and 'loader_json' in kwargs and kwargs['loader_json'] is not None:
            self._genomicsdb = new GenomicsDB(as_string(kwargs['query_json']),
                                              GENOMICSDB_JSON_FILE,
                                              as_string(kwargs['loader_json']))
        elif 'query_json' in kwargs:
                self._genomicsdb = new GenomicsDB(as_string(kwargs['query_json']),
                                                  GENOMICSDB_JSON_FILE)
        else:
            if 'workspace' not in kwargs:
                raise GenomicsDBException("Workspace is a required argument to connect to GenomicsDB")
            workspace = kwargs["workspace"]
            callset_mapping_file = kwargs["callset_mapping_file"]
            vid_mapping_file = kwargs["vid_mapping_file"]
            attributes = kwargs["attributes"]
            segment_size = kwargs["segment_size"]

            if attributes is None:
                self._genomicsdb  = new GenomicsDB(as_string(workspace),
                                                   as_string(callset_mapping_file),
                                                   as_string(vid_mapping_file))
            elif segment_size is None:
                self._genomicsdb  = new GenomicsDB(as_string(workspace),
                                                   as_string(callset_mapping_file),
                                                   as_string(vid_mapping_file),
                                                   as_vector(attributes))
            else:
                self._genomicsdb  = new GenomicsDB(as_string(workspace),
                                                   as_string(callset_mapping_file),
                                                   as_string(vid_mapping_file),
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
               reference_genome=None,
               vcf_header=None,
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
                                          as_string(reference_genome),
                                          as_string(vcf_header),
                                          as_string(output),
                                          as_string(output_format),
                                          overwrite)


    def __dealloc__(self):
        if self._genomicsdb != NULL:
            del self._genomicsdb

