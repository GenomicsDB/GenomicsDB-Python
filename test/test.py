import os
import shutil
import sys
import tarfile
import tempfile

import genomicsdb

genomicsdb.version()

import pandas as pd


def run_test():
    gdb = genomicsdb.connect("ws", "callset_t0_1_2.json", "vid.json", ["DP"], 40)
    try:
        gdb.query_variant_calls()
    except Exception as e:
        print(e)

    gdb = genomicsdb.connect("ws", "callset_t0_1_2.json", "vid.json", ["DP"], 10)
    list = gdb.query_variant_calls("t0_1_2", [(0, 1000000000)], [(0, 3)])
    print(list)

    list = gdb.query_variant_calls(
        "t0_1_2", [(0, 13000), (13000, 1000000000)], [(0, 3)]
    )
    print(list)
    x, y, calls = zip(*list)
    print(pd.DataFrame(calls[0]))

    gdb.query_variant_calls("t0_1_2", [(0, 1000000000)])
    gdb.query_variant_calls("t0_1_2")

    output = "out.vcf.gz"
    gdb.to_vcf(
        "t0_1_2",
        [(0, 15000)],
        [(0, 3)],
        "chr1_10MB.fasta.gz",
        "template_vcf_header.vcf",
        output=output,
        output_format="z",
    )
    if not os.path.exists(output):
        print(output + " NOT FOUND")
        if not os.path.exists(output + ".tbi"):
            print("Index file to " + output + " NOT FOUND")


from genomicsdb.protobuf import genomicsdb_export_config_pb2 as query_pb
from genomicsdb.protobuf import genomicsdb_coordinates_pb2 as query_coords


def run_test_connect_with_protobuf():
    print("run_test_connect_with_protobuf")
    query_config = query_pb.ExportConfiguration()
    query_config.workspace = "ws"
    query_config.array_name = "t0_1_2"
    query_config.segment_size = 40
    query_config.attributes.extend(["GT", "DP"])

    # query column interval
    interval = query_coords.ContigInterval()
    interval.contig = "1"
    interval.begin = 1
    interval.end = 100000
    query_config.query_contig_intervals.extend([interval])

    # query row range
    range = query_pb.RowRange()
    range.low = 0
    range.high = 3
    row_range_list = query_pb.RowRangeList()
    row_range_list.range_list.extend([range])
    query_config.query_row_ranges.extend([row_range_list])

    del query_config.query_row_ranges[:]
    query_config.query_sample_names.append("HG00141")

    # with loader.json
    gdb = genomicsdb.connect_with_protobuf(query_config, "loader.json")
    gdb.query_variant_calls()

    # without loader.json
    query_config.callset_mapping_file = "callset_t0_1_2.json"
    query_config.vid_mapping_file = "vid.json"
    gdb = genomicsdb.connect_with_protobuf(query_config)
    list = gdb.query_variant_calls()
    x, y, calls = zip(*list)
    print(pd.DataFrame(calls[0]))


def run_test_connect_with_json():
    print("run_test_connect_with_json")
    try:
        gdb = genomicsdb.connect_with_json("query.json")
    except Exception as e:
        print(e)

    gdb = genomicsdb.connect_with_json("query.json", "loader.json")
    gdb.query_variant_calls()


tmp_dir = tempfile.TemporaryDirectory().name

if not os.path.exists(tmp_dir):
    os.makedirs(tmp_dir)
else:
    sys.exit("Aborting as temporary directory seems to exist!")

tar = tarfile.open("test/inputs/sanity.test.tgz")
tar.extractall(tmp_dir)

os.chdir(tmp_dir)

run_test()
run_test_connect_with_protobuf()
run_test_connect_with_json()

shutil.rmtree(tmp_dir)
