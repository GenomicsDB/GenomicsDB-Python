import os
import time
import unittest

import pandas as pd
import pyarrow as pa

import genomicsdb
from genomicsdb import json_output_mode
from genomicsdb.protobuf import genomicsdb_coordinates_pb2 as query_coords
from genomicsdb.protobuf import genomicsdb_export_config_pb2 as query_pb


class TestGenomicsDBDemo(unittest.TestCase):

    query_config = None

    @classmethod
    def setUpClass(cls):
        ws = os.getenv("GENOMICSDB_DEMO_WS")
        if ws is None:
            print("Env GENOMICSDB_DEMO_WS not set.")
            return

        cls.query_config = query_pb.ExportConfiguration()
        cls.query_config.workspace = ws
        cls.query_config.array_name = "allcontigs$1$3095677412"
        cls.query_config.attributes.extend(["REF", "ALT", "GT"])
        # query column interval
        interval = query_coords.ContigInterval()
        interval.contig = "17"
        interval.begin = 7571719
        interval.end = 7590868
        # EGFR
        # interval.contig="7"
        # interval.begin=55086714
        # interval.end=55324313
        cls.query_config.query_contig_intervals.extend([interval])
        # query row range
        range = query_pb.RowRange()
        range.low = 0
        range.high = 200000
        row_range_list = query_pb.RowRangeList()
        row_range_list.range_list.extend([range])
        cls.query_config.query_row_ranges.extend([row_range_list])
        cls.query_config.callset_mapping_file = ws + "/callset.json"
        cls.query_config.vid_mapping_file = ws + "/vidmap.json"
        cls.query_config.bypass_intersecting_intervals_phase = True
        cls.query_config.enable_shared_posixfs_optimizations = True

    @classmethod
    def tearDownClass(cls):
        cls.query_config = None

    def test_genomicsdb_demo_with_interval(self):
        if self.query_config is None:
            return
        filters = ["", 'REF=="A"', 'REF=="A" && ALT|="T"', 'REF=="A" && ALT|="T" && resolve(GT,REF,ALT)&="T/T"']
        for filter in filters:
            start = time.time()
            self.query_config.query_filter = filter
            gdb = genomicsdb.connect_with_protobuf(self.query_config)
            list = gdb.query_variant_calls()
            x, y, calls = zip(*list)
            df = pd.DataFrame(calls[0])
            print("\nSummary with interval for " + filter + ":")
            print("\tCalls=" + str(len(df.index)))
            print("\tElapsed time: " + str(time.time() - start))

    def test_genomicsdb_demo_without_interval(self):
        if self.query_config is None:
            return
        filters = ["", "ISHOMALT", "ISHOMREF", "ISHET", 'REF=="A" && ALT|="T" && resolve(GT, REF, ALT)&="T/T"']
        for filter in filters:
            start = time.time()
            self.query_config.query_filter = filter
            gdb = genomicsdb.connect_with_protobuf(self.query_config)
            df = gdb.query_variant_calls(flatten_intervals=True)
            print("\nSummary for filter " + filter + ":")
            print("\tCalls=" + str(len(df.index)))
            print("\tElapsed time: " + str(time.time() - start))

    def test_genomicsdb_demo_with_json_output(self):
        if self.query_config is None:
            return
        print("test_genomicsdb_demo_with_json_output")
        modes = [
            json_output_mode.NUM_CALLS,
            json_output_mode.SAMPLES,
            json_output_mode.SAMPLES_WITH_NUM_CALLS,
            json_output_mode.ALL_BY_CALLS,
            json_output_mode.ALL,
        ]
        for mode in modes:
            start = time.time()
            gdb = genomicsdb.connect_with_protobuf(self.query_config)
            output_json = gdb.query_variant_calls(json_output=mode)
            print("\nSummary for mode=" + str(mode) + ":")
            print("output json length=" + str(len(output_json)))
            print("\tElapsed time: " + str(time.time() - start))

    def test_genomicsdb_demo_with_arrow_output(self):
        if self.query_config is None:
            return
        print("test_genomicsdb_demo_with_arrow_output")
        for batching_mode in [False, True]:
            start = time.time()
            gdb = genomicsdb.connect_with_protobuf(self.query_config)
            print("\nSummary for batching mode=" + str(batching_mode) + ":")
            for output in gdb.query_variant_calls(arrow_output=True, batching=batching_mode):
                reader = pa.ipc.open_stream(output)
                batch = reader.read_next_batch()
                print("batch num_rows=" + str(batch.num_rows) + " num_columns=" + str(batch.num_columns))
            print("\tElapsed time: " + str(time.time() - start))


if __name__ == "__main__":
    unittest.main()
