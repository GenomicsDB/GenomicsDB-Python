#
# CMakeLists.txt
#
# The MIT License
#
# Copyright (c) 2023 dātma, inc™
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Description : Python bindings to the native GenomicsDB Library
#

# distutils: language = c++
# cython: language_level=3

include "utils.pxi"

import threading
from enum import Enum

import numpy as np
import pandas
import pyarrow as pa

from genomicsdb.protobuf import genomicsdb_export_config_pb2 as query_pb


def version():
    """Print out version of the GenomicsDB native library

    Returns
    -------
    str
        GenomicsDB Version
    """
    version_string = c_version().decode("utf-8")
    return version_string


class GenomicsDBException(Exception):
    pass


class json_output_mode(Enum):
    ALL = 0
    ALL_BY_CALLS = 1
    SAMPLES_WITH_NUM_CALLS = 2
    NUM_CALLS = 3
    SAMPLES = 4


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
        raise GenomicsDBException("Failed to connect to the native GenomicsDB library", e)


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
        raise GenomicsDBException("Failed to connect to the native GenomicsDB library using protobuf", e)


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
        raise GenomicsDBException("Failed to connect to the native GenomicsDB library using json", e)


cdef class _GenomicsDB:
    cdef GenomicsDB* _genomicsdb

    def __init__(self, **kwargs):
        if 'query_protobuf' in kwargs and kwargs.get('loader_json', None) is not None:
            self._genomicsdb = new GenomicsDB(as_protobuf_string(kwargs['query_protobuf']),
                                              GENOMICSDB_PROTOBUF_BINARY_STRING,
                                              as_string(kwargs['loader_json']))
        elif 'query_protobuf' in kwargs:
            self._genomicsdb = new GenomicsDB(as_protobuf_string(kwargs['query_protobuf']),
                                              GENOMICSDB_PROTOBUF_BINARY_STRING)
        elif 'query_json' in kwargs and kwargs.get('loader_json', None) is not None:
            self._genomicsdb = new GenomicsDB(as_string(kwargs['query_json']),
                                              GENOMICSDB_JSON_FILE,
                                              as_string(kwargs['loader_json']))
        elif 'query_json' in kwargs:
            self._genomicsdb = new GenomicsDB(as_string(kwargs['query_json']),
                                              GENOMICSDB_JSON_FILE)
        else:
            if kwargs.get('workspace', None) is None:
                raise GenomicsDBException("Workspace is a required argument to connect to GenomicsDB")
            workspace = kwargs["workspace"]
            callset_mapping_file = kwargs["callset_mapping_file"]
            vid_mapping_file = kwargs["vid_mapping_file"]
            attributes = kwargs["attributes"]
            segment_size = kwargs["segment_size"]

            if attributes is None:
                self._genomicsdb = new GenomicsDB(as_string(workspace),
                                                  as_string(callset_mapping_file),
                                                  as_string(vid_mapping_file))
            elif segment_size is None:
                self._genomicsdb = new GenomicsDB(as_string(workspace),
                                                  as_string(callset_mapping_file),
                                                  as_string(vid_mapping_file),
                                                  as_vector(attributes))
            else:
                self._genomicsdb = new GenomicsDB(as_string(workspace),
                                                  as_string(callset_mapping_file),
                                                  as_string(vid_mapping_file),
                                                  as_vector(attributes),
                                                  segment_size)

    def query_variant_calls(self,
                            array=None,
                            column_ranges=None,
                            row_ranges=None,
                            query_protobuf: query_pb.QueryConfiguration = None,
                            flatten_intervals=False,
                            json_output=None,
                            arrow_output=None,
                            # batching/compress only used with arrow_output
                            batching=False,
                            compress=None):
        """ Query for variant calls from the GenomicsDB workspace using array, column_ranges
        and row_ranges for subsetting
        """

        if json_output is not None:
            return self.query_variant_calls_json(array, column_ranges, row_ranges, query_protobuf, json_output)
        elif arrow_output is not None:
            return self.query_variant_calls_arrow(array, column_ranges, row_ranges, query_protobuf, batching, compress)
        elif flatten_intervals is True:
            return self.query_variant_calls_columnar(array, column_ranges, row_ranges, query_protobuf)
        else:
            return self.query_variant_calls_by_interval(array, column_ranges, row_ranges, query_protobuf)

    def query_variant_calls_json(self,
                                 array=None,
                                 column_ranges=None,
                                 row_ranges=None,
                                 query_protobuf: query_pb.QueryConfiguration = None,
                                 json_output=json_output_mode.ALL):
        cdef payload_mode
        if json_output == json_output_mode.ALL:
            payload_mode = PAYLOAD_ALL
        elif json_output == json_output_mode.ALL_BY_CALLS:
            payload_mode = PAYLOAD_ALL_BY_CALLS
        elif json_output == json_output_mode.SAMPLES_WITH_NUM_CALLS:
            payload_mode = PAYLOAD_SAMPLES_WITH_NUM_CALLS
        elif json_output == json_output_mode.NUM_CALLS:
            payload_mode = PAYLOAD_NUM_CALLS
        elif json_output == json_output_mode.SAMPLES:
            payload_mode = PAYLOAD_SAMPLES
        else:
            raise RuntimeError("Unknown json_output_mode")
        cdef JSONVariantCallProcessor processor
        cdef string configstring
        cdef genomicsdb_ranges_t rows, columns
        processor.set_payload_mode(payload_mode)
        if query_protobuf:
            if array or column_ranges or row_ranges:
                raise GenomicsDBException("Cannot specify query_protobuf and array/column_ranges/row_ranges together")
            configstring = as_protobuf_string(query_protobuf.SerializeToString())
            with nogil:
                self._genomicsdb.query_variant_calls(processor, configstring, GENOMICSDB_PROTOBUF_BINARY_STRING)
        elif array is None:
            configstring = as_string("")
            with nogil:
                self._genomicsdb.query_variant_calls(processor, configstring, GENOMICSDB_NONE)
        elif column_ranges is None:
            configstring = as_string(array)
            rows = scan_full()
            with nogil:
                self._genomicsdb.query_variant_calls(processor, configstring, rows)
        elif row_ranges is None:
            configstring = as_string(array)
            columns = as_ranges(column_ranges)
            with nogil:
                self._genomicsdb.query_variant_calls(processor, configstring, columns)
        else:
            configstring = as_string(array)
            columns = as_ranges(column_ranges)
            rows = as_ranges(row_ranges)
            with nogil:
                self._genomicsdb.query_variant_calls(processor, configstring,
                                                     columns, rows)
        return processor.construct_json_output()

    def query_variant_calls_by_interval(self,
                                        array=None,
                                        column_ranges=None,
                                        row_ranges=None,
                                        query_protobuf: query_pb.QueryConfiguration = None):
        cdef list variant_calls = []
        cdef VariantCallProcessor processor
        processor.set_root(variant_calls)
        if query_protobuf:
            if array or column_ranges or row_ranges:
                raise GenomicsDBException("Cannot specify query_protobuf and array/column_ranges/row_ranges together")
            self._genomicsdb.query_variant_calls(processor, as_protobuf_string(query_protobuf.SerializeToString()),
                                                 GENOMICSDB_PROTOBUF_BINARY_STRING)
        elif array is None:
            self._genomicsdb.query_variant_calls(processor, as_string(""), GENOMICSDB_NONE)
        elif column_ranges is None:
            self._genomicsdb.query_variant_calls(processor, as_string(array), scan_full())
        elif row_ranges is None:
            self._genomicsdb.query_variant_calls(processor, as_string(array), as_ranges(column_ranges))
        else:
            self._genomicsdb.query_variant_calls(processor, as_string(array),
                                                 as_ranges(column_ranges),
                                                 as_ranges(row_ranges))
        return variant_calls

    def query_variant_calls_columnar(self,
                                     array=None,
                                     column_ranges=None,
                                     row_ranges=None,
                                     query_protobuf: query_pb.QueryConfiguration = None):
        """ Query for variant calls from the GenomicsDB workspace using array, column_ranges and
        row_ranges for subsetting
        """

        cdef ColumnarVariantCallProcessor processor
        if query_protobuf:
            if array or column_ranges or row_ranges:
                raise GenomicsDBException("Cannot specify query_protobuf and array/column_ranges/row_ranges together")
            self._genomicsdb.query_variant_calls(processor, as_protobuf_string(query_protobuf.SerializeToString()),
                                                 GENOMICSDB_PROTOBUF_BINARY_STRING)
        elif array is None:
            self._genomicsdb.query_variant_calls(processor, as_string(""), GENOMICSDB_NONE)
        elif column_ranges is None:
            self._genomicsdb.query_variant_calls(processor, as_string(array), scan_full())
        elif row_ranges is None:
            self._genomicsdb.query_variant_calls(processor, as_string(array), as_ranges(column_ranges))
        else:
            self._genomicsdb.query_variant_calls(processor, as_string(array),
                                                 as_ranges(column_ranges),
                                                 as_ranges(row_ranges))
        return pandas.DataFrame(processor.construct_data_frame()).replace(np.nan, '').replace(-99999, '')

    def query_variant_calls_arrow(self,
                                  array=None,
                                  column_ranges=None,
                                  row_ranges=None,
                                  query_protobuf: query_pb.QueryConfiguration = None,
                                  batching=False,
                                  compress=None):
        """ Query for variant calls from the GenomicsDB workspace using array, column_ranges and
        row_ranges for subsetting
        """

        cdef ArrowVariantCallProcessor processor

        if batching:
            processor.set_batching(1)

        def query_calls():
            if query_protobuf:
                if array or column_ranges or row_ranges:
                    raise GenomicsDBException("Cannot specify query_protobuf and " +
                                              "array/column_ranges/row_ranges together")
                configstring = as_protobuf_string(query_protobuf.SerializeToString())
                with nogil:
                    self._genomicsdb.query_variant_calls(processor, configstring, GENOMICSDB_PROTOBUF_BINARY_STRING)
            elif array is None:
                configstring = as_string("")
                with nogil:
                    self._genomicsdb.query_variant_calls(processor, configstring, GENOMICSDB_NONE)
            elif column_ranges is None:
                configstring = as_string(array)
                rows = scan_full()
                with nogil:
                    self._genomicsdb.query_variant_calls(processor, configstring, rows)
            elif row_ranges is None:
                configstring = as_string(array)
                columns = as_ranges(column_ranges)
                with nogil:
                    self._genomicsdb.query_variant_calls(processor, configstring, columns)
            else:
                configstring = as_string(array)
                columns = as_ranges(column_ranges)
                rows = as_ranges(row_ranges)
                with nogil:
                    self._genomicsdb.query_variant_calls(processor, configstring,
                                                         columns, rows)

        if batching:
            query_thread = threading.Thread(target=query_calls)
            query_thread.start()
        else:
            query_calls()

        cdef void* arrow_schema = processor.arrow_schema()
        if arrow_schema:
            schema_capsule = pycapsule_get_arrow_schema(arrow_schema)
            schema_obj = _ArrowSchemaWrapper._import_from_c_capsule(schema_capsule)
            schema = pa.schema(schema_obj.children_schema)
        else:
            raise GenomicsDBException("Failed to retrieve arrow schema for query_variant_calls()")

        cdef void* arrow_array = NULL
        w_opts = pa.ipc.IpcWriteOptions(allow_64bit=True, compression=compress)
        while True:
            try:
                arrow_array = processor.arrow_array()
                if arrow_array:
                    array_capsule = pycapsule_get_arrow_array(arrow_array)
                    array_obj = _ArrowArrayWrapper._import_from_c_capsule(schema_capsule, array_capsule)
                    arrays = [pa.array(array_obj.child(i)) for i in range(array_obj.n_children)]
                    batch = pa.RecordBatch.from_arrays(arrays, schema=schema)
                    sink = pa.BufferOutputStream()
                    writer = pa.RecordBatchStreamWriter(sink, schema, options=w_opts)
                    writer.write_batch(batch)
                    writer.close()
                    yield sink.getvalue().to_pybytes()
                else:
                    break
            except Exception as e:
                raise GenomicsDBException("Exception from processing of arrow arrays", e)

        if batching:
            query_thread.join()

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


# Filesystem Utilities

def is_file(filename):
    """
    Check if the given filename(local or cloud URI) exists as a file

    Parameters
    ----------
    filename : str

    Returns
    -------
    true/false
    """
    return c_is_file(as_string(filename))


def file_size(filename):
    """
    Get the size of the file referenced by filename(local or cloud URI)

    Parameters
    ----------
    filename : str

    Returns
    -------
    size or -1 if file is not found
    """
    return c_file_size(as_string(filename))


def read_entire_file(filename):
    """
    Retrieve the contents of the file referenced by filename(local or cloud URI). Use with relatively small, text files

    Parameters
    ----------
    filename : str

    Returns
    -------
    contents of file decoded with utf-8 if the file could be found and read, otherwise return None

    """
    cdef char* contents = NULL
    cdef size_t length
    cdef int p = c_read_entire_file(as_string(filename), <void**>&contents, &length)
    if p == 0:
        contents_string = contents.decode("utf-8")
        free(contents)
        return contents_string


def workspace_exists(workspace):
    return c_workspace_exists(as_string(workspace))


def array_exists(workspace, array):
    return c_array_exists(as_string(workspace), as_string(array))


def cache_array_metadata(workspace, array):
    if c_cache_fragment_metadata(as_string(workspace), as_string(array)) != 0:
        print(f"Could not cache fragment metadata for array={array.decode()} in {workspace}")
