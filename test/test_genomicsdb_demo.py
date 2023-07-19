import unittest

import os
import shutil
import sys
import tarfile
import tempfile
import time

import genomicsdb
from genomicsdb.protobuf import genomicsdb_export_config_pb2 as query_pb
from genomicsdb.protobuf import genomicsdb_coordinates_pb2 as query_coords

import pandas as pd

class TestGenomicsDBDemo(unittest.TestCase):

  def test_genomicsdb_demo_with_interval(self):
    ws = os.getenv("GENOMICSDB_DEMO_WS")
    if ws is None:
      print("Env GENOMICSDB_DEMO_WS not set.")
      return
      
    query_config = query_pb.ExportConfiguration()
    query_config.workspace = ws
    query_config.array_name = "allcontigs$1$3095677412"
    query_config.attributes.extend(["REF", "ALT", "GT"])
    
    # query column interval
    interval = query_coords.ContigInterval()
    interval.contig = "17"
    interval.begin = 7571719
    interval.end = 7590868
    query_config.query_contig_intervals.extend([interval])
    
    # query row range
    range = query_pb.RowRange()
    range.low = 0
    range.high = 200000
    row_range_list = query_pb.RowRangeList()
    row_range_list.range_list.extend([range])
    query_config.query_row_ranges.extend([row_range_list])
    
    query_config.callset_mapping_file = ws+"/callset.json"
    query_config.vid_mapping_file = ws+"/vidmap.json"
    query_config.bypass_intersecting_intervals_phase = True
    query_config.enable_shared_posixfs_optimizations = True
    
    filters = ["", "REF==\"A\"", "REF==\"A\" && ALT|=\"T\"", "REF==\"A\" && ALT|=\"T\" && GT&=\"1/1\""]
    
    for filter in filters:
      start = time.time()
      query_config.query_filter = filter
      gdb = genomicsdb.connect_with_protobuf(query_config)
      list = gdb.query_variant_calls()
      x, y, calls = zip(*list)
      df = pd.DataFrame(calls[0])
      print("\nSummary with interval for "+filter+":")
      print("\tCalls="+str(len(df.index)))
      print("\tElapsed time: "+str(time.time()-start))

  def test_genomicsdb_demo_without_interval(self):
    ws = os.getenv("GENOMICSDB_DEMO_WS")
    if ws is None:
      print("Env GENOMICSDB_DEMO_WS not set.")
      return
  
    query_config = query_pb.ExportConfiguration()
    query_config.workspace = ws
    query_config.array_name = "allcontigs$1$3095677412"
  
    # query column interval
    interval = query_coords.ContigInterval()
    interval.contig = "17"
    interval.begin = 7571719
    interval.end = 7590868
    query_config.query_contig_intervals.extend([interval])
  
    # query row range
    range = query_pb.RowRange()
    range.low = 0
    range.high = 200000
    row_range_list = query_pb.RowRangeList()
    row_range_list.range_list.extend([range])
    query_config.query_row_ranges.extend([row_range_list])
  
    query_config.callset_mapping_file = ws+"/callset.json"
    query_config.vid_mapping_file = ws+"/vidmap.json"
    query_config.bypass_intersecting_intervals_phase = True
    query_config.enable_shared_posixfs_optimizations = True
    #query_config.segment_size = 10240
  
    #attributes
    query_config.attributes.extend(["REF", "ALT", "GT"])

    filters = ["", "REF==\"A\"", "REF==\"A\" && ALT|=\"T\"", "REF==\"A\" && ALT|=\"T\" && GT&=\"1/1\""]

    for filter in filters:
      start = time.time()
  
      query_config.query_filter = filter
  
      gdb = genomicsdb.connect_with_protobuf(query_config)
      df = gdb.query_variant_calls(flatten_intervals=True)
      print("\nSummary for filter "+filter+":")
      print("\tCalls="+str(len(df.index)))
      print("\tElapsed time: "+str(time.time()-start))

if __name__ == '__main__':
  unittest.main()

