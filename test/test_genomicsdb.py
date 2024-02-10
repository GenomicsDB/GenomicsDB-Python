import os
import pytest
import shutil
import sys
import tarfile
import tempfile

import genomicsdb

from genomicsdb.protobuf import genomicsdb_export_config_pb2 as query_pb
from genomicsdb.protobuf import genomicsdb_coordinates_pb2 as query_coords

@pytest.fixture()
def setup():
  tmp_dir = tempfile.TemporaryDirectory().name
  print("tmp_dir")
  if not os.path.exists(tmp_dir):
    os.makedirs(tmp_dir)
  else:
    sys.exit("Aborting as temporary directory seems to exist!")
  tar = tarfile.open("test/inputs/sanity.test.tgz")
  tar.extractall(tmp_dir)
  os.chdir(tmp_dir)
  yield
  shutil.rmtree(tmp_dir)

def test_version():
  version = genomicsdb.version()
  assert len(version) > 0
  # Should contain major.minor.patch in version string
  version_components = version.split('.')
  assert len(version_components) == 3
  assert int(version_components[0]) > 0
  assert int(version_components[1]) >= 0

def test_connect_and_query_with_protobuf(setup):
  export_config = query_pb.ExportConfiguration()
  export_config.workspace = "ws"
  export_config.segment_size = 40
  export_config.callset_mapping_file = "callset_t0_1_2.json"
  export_config.vid_mapping_file = "vid.json"
  export_config.attributes.extend(["GT", "DP"])
  gdb = genomicsdb.connect_with_protobuf(export_config)

  # test basic
  list = gdb.query_variant_calls()
  assert len(list) == 1
  x, y, calls = zip(*list)
  assert len(calls[0]) == 5

  # test all
  query_config = query_pb.QueryConfiguration()
  list = gdb.query_variant_calls(query_protobuf=query_config)
  assert len(list) == 1
  x, y, calls = zip(*list)
  assert len(calls[0]) == 5

  # test with flatten intervals
  calls = gdb.query_variant_calls(query_protobuf=query_config,
                                  flatten_intervals=True)
  assert len(calls) == 5

  # test with query protobuf and json output
  from genomicsdb import json_output_mode
  assert len(gdb.query_variant_calls(query_protobuf=query_config,
                                     json_output=json_output_mode.NUM_CALLS)) == 15
  assert len(gdb.query_variant_calls(query_protobuf=query_config,
                                     json_output=json_output_mode.SAMPLES)) == 31
  assert len(gdb.query_variant_calls(query_protobuf=query_config,
                                     json_output=json_output_mode.SAMPLES_WITH_NUM_CALLS)) == 37
  assert len(gdb.query_variant_calls(query_protobuf=query_config,
                                     json_output=json_output_mode.ALL_BY_CALLS)) == 207
  assert len(gdb.query_variant_calls(query_protobuf=query_config,
                                     json_output=json_output_mode.ALL)) == 273
  with pytest.raises(Exception):
      output_json = gdb.query_variant_calls(query_protobuf=query_config,
                                            json_output=9999)

  # test with query contig interval and no results
  interval = query_coords.ContigInterval()
  interval.contig = "22"
  query_config.query_contig_intervals.extend([interval])
  print(gdb.query_variant_calls(query_protobuf=query_config,
                                json_output=json_output_mode.NUM_CALLS))
  assert len(gdb.query_variant_calls(query_protobuf=query_config,
                                     json_output=json_output_mode.NUM_CALLS)) == 15
  assert len(gdb.query_variant_calls(query_protobuf=query_config,
                                     json_output=json_output_mode.SAMPLES)) == 2
  assert len(gdb.query_variant_calls(query_protobuf=query_config,
                                     json_output=json_output_mode.SAMPLES_WITH_NUM_CALLS)) == 2
  assert len(gdb.query_variant_calls(query_protobuf=query_config,
                                     json_output=json_output_mode.ALL_BY_CALLS)) == 2
  assert len(gdb.query_variant_calls(query_protobuf=query_config,
                                     json_output=json_output_mode.ALL)) == 2
  
  # test with query contig interval
  del query_config.query_contig_intervals[:]
  interval = query_coords.ContigInterval()
  interval.contig = "1"
  interval.begin = 1
  interval.end = 13000
  query_config.query_contig_intervals.extend([interval])
  list = gdb.query_variant_calls(query_protobuf=query_config)
  assert len(list) == 1
  x, y, calls = zip(*list)
  assert len(calls[0]) == 2

  # test with query row range
  range = query_pb.RowRange()
  range.low = 0
  range.high = 1
  row_range_list = query_pb.RowRangeList()
  row_range_list.range_list.extend([range])
  query_config.query_row_ranges.extend([row_range_list])
  list = gdb.query_variant_calls(query_protobuf=query_config)
  assert len(list) == 1
  x, y, calls = zip(*list)
  assert len(calls[0]) == 2

  # test with query row range and json_output
  output = gdb.query_variant_calls(query_protobuf=query_config,
                                   json_output=json_output_mode.SAMPLES)
  assert len(output) == 21
  assert output == b'["HG00141","HG01958"]'

  # test with query sample names
  query_config = query_pb.QueryConfiguration()
  query_config.query_sample_names.append("HG00141")
  query_config.query_sample_names.append("HG01958")
  list = gdb.query_variant_calls(query_protobuf=query_config)
  assert len(list) == 1
  x, y, calls = zip(*list)
  assert len(calls[0]) == 4

  # test exception when query row and sample names are specified together
  range = query_pb.RowRange()
  range.low = 0
  range.high = 1
  row_range_list = query_pb.RowRangeList()
  row_range_list.range_list.extend([range])
  query_config.query_row_ranges.extend([row_range_list])
  with pytest.raises(Exception):
    gdb.query_variant_calls(query_protobuf=query_config)

  # test with two query contig intervals
  query_config = query_pb.QueryConfiguration()
  interval = query_coords.ContigInterval()
  interval.contig = "1"
  interval.begin = 1
  interval.end = 13000
  interval1 = query_coords.ContigInterval()
  interval1.contig = "1"
  interval1.begin = 13000
  interval1.end = 18000
  query_config.query_contig_intervals.extend([interval, interval1])
  list = gdb.query_variant_calls(query_protobuf=query_config)
  assert len(list) == 2
  x, y, calls = zip(*list)
  assert len(calls[0]) == 2
  assert len(calls[1]) == 3

  # test with two query contig intervals and flatten intervals
  calls = gdb.query_variant_calls(query_protobuf=query_config, flatten_intervals=True)
  assert len(calls) == 5

  # test exception when query protobuf and array/column_ranges/row_ranges are specified together
  query_config = query_pb.QueryConfiguration()
  with pytest.raises(Exception):
    gdb.query_variant_calls(query_protobuf=query_config, array="t0_1_2", column_ranges=[], row_ranges=[])
