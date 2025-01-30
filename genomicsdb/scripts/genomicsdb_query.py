#!/usr/bin/env python

#
# genomicsdb_query python script
#
# The MIT License
#
# Copyright (c) 2024-2025 dātma, inc™
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

import argparse
import json
import logging
import multiprocessing
import os
import re
import sys
from typing import List, NamedTuple

import pyarrow as pa
import pyarrow.parquet as pq

import genomicsdb
from genomicsdb import json_output_mode
from genomicsdb.protobuf import genomicsdb_coordinates_pb2 as query_coords
from genomicsdb.protobuf import genomicsdb_export_config_pb2 as query_pb
from genomicsdb.scripts import genomicsdb_common

logging.basicConfig(
    format="%(asctime)s.%(msecs)03d %(levelname)-5s GenomicsDB Python - pid=%(process)d tid=%(thread)d %(message)s",
    level=logging.INFO,
    datefmt="%H:%M:%S",
)


def parse_callset_json(callset_file):
    callset = json.loads(genomicsdb.read_entire_file(callset_file))
    callsets = callset["callsets"]
    samples = [callset if isinstance(callset, str) else callset["sample_name"] for callset in callsets]
    return samples


def parse_callset_json_for_row_ranges(callset_file, samples=None):
    if not samples:
        return None
    callset = json.loads(genomicsdb.read_entire_file(callset_file))
    callsets = callset["callsets"]
    if isinstance(samples, str):
        with open(samples) as file:
            samples = [line.rstrip() for line in file]
    if not samples:
        return None
    # Old style json has type(callset) == str whereas the one generated with vcf2genomicsdb_init is a list
    rows = [
        callsets[callset]["row_idx"] if isinstance(callset, str) else callset["row_idx"]
        for sample in samples
        for callset in callsets
        if (not isinstance(callset, str) and sample == callset["sample_name"])
        or (isinstance(callset, str) and sample == callset)
    ]
    if len(rows) == 0:
        print(f"None of the samples{samples} specified were found in the workspace")
        return []
    rows.sort(reverse=True)
    # make row_tuples
    row = rows.pop()
    row_tuples = [(row, row)]
    while len(rows) > 0:
        row = rows.pop()
        tuple = row_tuples[-1]
        if row > tuple[1] + 1:
            # Append new range
            row_tuples.append((row, row))
        elif row == tuple[1] + 1:
            # Expand range for tuple
            row_tuples.pop()
            row_tuples.append((tuple[0], row))
    return row_tuples


def parse_callset_json_for_split_row_ranges(callset_file, chunk_size):
    callset = json.loads(genomicsdb.read_entire_file(callset_file))
    callsets = callset["callsets"]
    chunks = int(len(callsets) / chunk_size + 1)
    last_chunk_size = len(callsets) - (chunks - 1) * chunk_size
    # Collapse small last chunk into the last but one chunk
    if last_chunk_size < chunk_size / 2:
        chunks -= 1
        last_chunk_size += chunk_size
    if chunks == 1:
        return None
    split_row_ranges = []
    for i in range(0, chunks):
        if i == chunks - 1:
            split_row_ranges.append((chunk_size * i, chunk_size * i + last_chunk_size - 1))
        else:
            split_row_ranges.append((chunk_size * i, chunk_size * (i + 1) - 1))
    return split_row_ranges


def print_fields(key, val, descriptions):
    if "vcf_field_class" not in val:
        val["vcf_field_class"] = ["FILTER"]
    if "length" not in val:
        val["length"] = "1"
    for idx in range(len(val["vcf_field_class"])):
        field_class = val["vcf_field_class"][idx]
        if isinstance(val["type"], list):
            if idx < len(val["type"]):
                field_type = val["type"][idx]
            else:
                field_type = val["type"][0]
        else:
            field_type = val["type"]
        if isinstance(val["length"], list):
            if idx < len(val["length"]):
                field_length = val["length"][idx]
            else:
                field_length = val["length"][0]
            if "variable_length_descriptor" in field_length:
                field_length = field_length["variable_length_descriptor"]
        else:
            field_length = val["length"]
        if field_type == "int":
            field_type = "Integer"
        elif field_type == "float":
            field_type = "Float"
        elif field_type == "char":
            if field_length.lower() == "var":
                field_type = "String"
            else:
                field_type = "Char"
        tuple_index = (key, field_class)
        if descriptions and tuple_index in descriptions:
            print(f"{key:<20} {field_class:10} {field_type:10} {field_length:10} {descriptions[tuple_index]}")
        else:
            print(f"{key:<20} {field_class:10} {field_type:10} {field_length}")


def parse_template_header_file(template_header_file):
    if not genomicsdb.is_file(template_header_file):
        return None
    header_contents = genomicsdb.read_entire_file(template_header_file)
    start = 0
    template_header_fields = {}
    while True:
        end = header_contents.find("\n", start)
        if end == -1:
            break
        line = header_contents[start:end]
        if line.startswith("##INFO") or line.startswith("##FORMAT") or line.startswith("##FILTER"):
            try:
                line = line[2:]
                field_start = line.find("=<")
                field_end = line.find(">")
                field_type = line[0:field_start]
                fields = line[field_start + 2 : field_end].split(",")
                field_id = None
                field_description = None
                for field in fields:
                    val = field.find("ID=")
                    if val == 0:
                        field_id = field[val + len("ID=") :]
                    else:
                        val = field.find("Description=")
                        if val == 0:
                            field_description = field[val + len("Description=") :]
                if field_id and field_description:
                    template_header_fields[(field_id, field_type)] = field_description
            except Exception as e:
                logging.error(f"Exception={e} when processing {template_header_file} for line={line}")
        start = end + 1
    return template_header_fields


def parse_and_print_fields(vidmap_file, template_header_file):
    descriptions = parse_template_header_file(template_header_file)
    vidmap = json.loads(genomicsdb.read_entire_file(vidmap_file))
    fields = vidmap["fields"]
    if descriptions:
        print(f"{'Field':20} {'Class':10} {'Type':10} {'Length':10} {'Description'}")
        print(f"{'-----':20} {'-----':10} {'----':10} {'------':10} {'-----------'}")
    else:
        print(f"{'Field':20} {'Class':10} {'Type':10} {'Length'}")
        print(f"{'-----':20} {'-----':10} {'----':10} {'------'}")
    if isinstance(fields, list):
        {print_fields(field["name"], field, descriptions) for field in fields}
    else:  # Old style vidmap json
        for key, val in fields.items():
            print_fields(key, val, descriptions)
    # See https://github.com/GenomicsDB/GenomicsDB/wiki/Importing-VCF-data-into-GenomicsDB
    # for description of lengths in vid mapping files
    abbreviations = {
        "A": "Number of alternate alleles",
        "R": "Number of alleles (including reference allele)",
        "G": "Number of possible genotypes",
        "PP or P": "Ploidy",
        "VAR or var": "variable length",
    }
    print("--")
    print("Abbreviations : ")
    {print(f"  {key}: {val}") for key, val in abbreviations.items()}


def parse_vidmap_json_for_attributes(vidmap_file, attributes=None):
    if attributes is None or len(attributes) == 0:
        # Default
        return ["REF", "GT"]

    vidmap = json.loads(genomicsdb.read_entire_file(vidmap_file))
    fields = vidmap["fields"]
    if isinstance(fields, list):
        fields = [field["name"] for field in fields]
    else:  # Old style vidmap json
        fields = fields.keys()
    fields = set(fields)
    fields.add("REF")
    fields.add("ALT")
    attributes = attributes.replace(" ", "").split(",")
    not_found = [attribute for attribute in attributes if attribute not in fields]
    if len(not_found) > 0:
        raise RuntimeError(f"Attributes({not_found}) not found in vid mapping({vidmap_file})")
    return attributes


def parse_loader_json(loader_file, interval_form=True):
    loader = json.loads(genomicsdb.read_entire_file(loader_file))
    partitions = loader["column_partitions"]
    array_names = [
        partition["array_name"] if "array_name" in partition else partition["array"] for partition in partitions
    ]
    return [name.replace("$", ":", 1).replace("$", "-", 1) if interval_form else name for name in array_names]


def check_nproc(value):
    ivalue = int(value)
    if ivalue < 1:
        raise argparse.ArgumentTypeError("%s specified nproc arg cannot be less than 1" % value)
    elif ivalue > multiprocessing.cpu_count():
        raise argparse.ArgumentTypeError(
            "%s specified nproc arg cannot exceed max number of available processing units" % value
        )
    return ivalue


def setup():
    parser = argparse.ArgumentParser(
        prog="query",
        description="GenomicsDB simple query with samples/intervals/attributes/filter as inputs",
        formatter_class=argparse.RawTextHelpFormatter,
        usage="%(prog)s [options]",
    )
    parser.add_argument(
        "--version",
        action="version",
        version=genomicsdb.version(),
        help="print GenomicsDB native library version and exit",
    )
    parser.add_argument(
        "-w",
        "--workspace",
        required=True,
        help="URL to GenomicsDB workspace \ne.g. -w my_workspace or -w az://my_container/my_workspace"
        + " or -w s3://my_bucket/my_workspace or -w gs://my_bucket/my_workspace",
    )
    parser.add_argument(
        "-v",
        "--vidmap",
        required=False,
        help="Optional - URL to vid mapping file. Defaults to vidmap.json in workspace",
    )
    parser.add_argument(
        "-c",
        "--callset",
        required=False,
        help="Optional - URL to callset mapping file. Defaults to callset.json in workspace",
    )
    parser.add_argument(
        "-l", "--loader", required=False, help="Optional - URL to loader file. Defaults to loader.json in workspace"
    )
    parser.add_argument("--list-samples", action="store_true", help="List samples ingested into the workspace and exit")
    parser.add_argument(
        "--list-contigs", action="store_true", help="List contigs configured in vid mapping for the workspace and exit"
    )
    parser.add_argument(
        "--list-fields",
        action="store_true",
        help="List genomic fields configured in vid mapping for the workspace and exit",
    )
    parser.add_argument(
        "--list-partitions",
        action="store_true",
        help="List interval partitions(genomicsdb arrays in the workspace) for the given intervals(-i/--interval or -I/--interval-list) or all the intervals for the workspace and exit",  # noqa
    )
    parser.add_argument(
        "--no-cache",
        action="store_true",
        help="Do not use cached metadata and files with the genomicsdb query",
    )
    parser.add_argument(
        "-i",
        "--interval",
        action="append",
        required=False,
        help="genomic intervals over which to operate. The intervals should be specified in the <CONTIG>:<START>-<END> format with START and END optional.\nThis argument may be specified 0 or more times e.g -i chr1:1-10000 -i chr2 -i chr3:1000. \nNote: \n\t1. -i/--interval and -I/--interval-list are mutually exclusive \n\t2. either samples and/or intervals using -i/-I/-s/-S options has to be specified",  # noqa
    )
    parser.add_argument(
        "-I",
        "--interval-list",
        required=False,
        help="genomic intervals listed in a file over which to operate.\nThe intervals should be specified in the <CONTIG>:<START>-<END> format, with START and END optional one interval per line. \nNote: \n\t1. -i/--interval and -I/--interval-list are mutually exclusive \n\t2. either samples and/or intervals using -i/-I/-s/-S options has to be specified",  # noqa
    )
    parser.add_argument(
        "-s",
        "--sample",
        action="append",
        required=False,
        help="sample names over which to operate. This argument may be specified 0 or more times e.g -s HG00097 -s HG00090. \nNote: \n\t1. -s/--sample and -S/--sample-list are mutually exclusive \n\t2. either samples and/or intervals using -i/-I/-s/-S options has to be specified",  # noqa
    )
    parser.add_argument(
        "-S",
        "--sample-list",
        required=False,
        help="sample file containing list of samples, one sample per line, to operate upon. \nNote: \n\t1. -s/--sample and -S/--sample-list are mutually exclusive \n\t2. either samples and/or intervals using -i/-I/-s/-S options has to be specified",  # noqa
    )
    parser.add_argument(
        "-a",
        "--attributes",
        required=False,
        help="Optional - comma separated list of genomic attributes(REF, ALT) and fields described in the vid mapping for the query, eg. GT,AC,PL,DP... Defaults to REF,GT",  # noqa
    )
    parser.add_argument(
        "-f",
        "--filter",
        required=False,
        help="Optional - genomic filter expression for the query, e.g. 'ISHOMREF' or 'ISHET' or 'REF == \"G\" && resolve(GT, REF, ALT) &= \"T/T\" && ALT |= \"T\"'",  # noqa
    )
    parser.add_argument(
        "-n",
        "--nproc",
        type=check_nproc,
        default=8,
        help="Optional - number of processing units for multiprocessing(default: %(default)s). Run nproc from command line to print the number of processing units available to a process for the user",  # noqa
    )
    parser.add_argument(
        "--chunk-size",
        default=10240,
        help="Optional - hint to split number of samples for  multiprocessing used in conjunction with -n/--nproc and when -s/-S/--sample/--sample-list is not specified (default: %(default)s)",  # noqa
    )
    parser.add_argument(
        "-t",
        "--output-type",
        choices=["csv", "json", "arrow"],
        default="csv",
        help="Optional - specify type of output for the query (default: %(default)s)",
    )
    parser.add_argument(
        "-j",
        "--json-output-type",
        choices=["all", "all-by-calls", "samples-with-num-calls", "samples", "num-calls"],
        default="samples-with-num-calls",
        help="Optional - used in conjunction with -t/--output-type json (default: %(default)s)",
    )
    parser.add_argument(
        "-z",
        "--max-arrow-byte-size",
        default="64MB",
        help="Optional - used in conjunction with -t/--output-type arrow as hint for buffering parquet files(default: %(default)s)",  # noqa
    )
    parser.add_argument(
        "-o",
        "--output",
        default="query_output",
        help="a prefix filename to outputs from the tool. The filenames will be suffixed with the interval and .csv/.json/... (default: %(default)s)",  # noqa
    )
    parser.add_argument(
        "-d",
        "--dryrun",
        action="store_true",
        help="displays the query that  will be run without actually executing the query (default: %(default)s)",  # noqa
    )
    parser.add_argument(
        "-b",
        "--bypass-intersecting-intervals-phase",
        action="store_true",
        help="iterate only once bypassing the intersecting intervals phase (default: %(default)s)",  # noqa
    )

    args = parser.parse_args()

    workspace = genomicsdb_common.normalize_path(args.workspace)
    is_cloud_workspace = True if "://" in workspace else False
    if not genomicsdb.workspace_exists(workspace):
        raise RuntimeError(f"workspace({workspace}) not found")
    callset_file = args.callset
    if not callset_file:
        if is_cloud_workspace and not args.no_cache and genomicsdb.is_file("callset.json"):
            callset_file = "callset.json"
        else:
            callset_file = genomicsdb_common.join_paths(workspace, "callset.json")
    vidmap_file = args.vidmap
    if not vidmap_file:
        if is_cloud_workspace and not args.no_cache and genomicsdb.is_file("vidmap.json"):
            vidmap_file = "vidmap.json"
        else:
            vidmap_file = genomicsdb_common.join_paths(workspace, "vidmap.json")
    loader_file = args.loader
    if not loader_file:
        if not args.no_cache and genomicsdb.is_file("loader.json"):
            loader_file = "loader.json"
        else:
            loader_file = genomicsdb_common.join_paths(workspace, "loader.json")
    if (
        not genomicsdb.is_file(callset_file)
        or not genomicsdb.is_file(vidmap_file)
        or not genomicsdb.is_file(loader_file)
    ):
        raise RuntimeError(f"callset({callset_file}) vidmap({vidmap_file}) or loader({loader_file}) not found")

    # List samples
    if args.list_samples:
        samples = parse_callset_json(callset_file)
        print(*samples, sep="\n")
        sys.exit(0)

    # List fields
    if args.list_fields:
        template_header_file = workspace + "/vcfheader.vcf"
        parse_and_print_fields(vidmap_file, template_header_file)
        sys.exit(0)

    intervals = args.interval
    interval_list = args.interval_list
    samples = args.sample
    sample_list = args.sample_list
    if not args.list_partitions and not args.list_contigs:
        if not intervals and not samples and not interval_list and not sample_list:
            raise RuntimeError(
                "one of either -i/-interval -I/--interval-list -s/--sample -S/--sample-list has to be specified"  # noqa
            )

    contigs_map, intervals = genomicsdb_common.parse_vidmap_json(vidmap_file, intervals or interval_list)

    # List contigs
    if args.list_contigs:
        if intervals:
            for interval in intervals:
                if interval.split(":")[0] in contigs_map.keys():
                    print(interval)
        else:
            print(*contigs_map.keys(), sep="\n")
        sys.exit(0)

    loader = json.loads(genomicsdb.read_entire_file(loader_file))
    partitions = loader["column_partitions"]

    # List partitions
    if args.list_partitions:
        if args.interval or args.interval_list:
            partition_names = genomicsdb_common.get_partitions(intervals, contigs_map, partitions)
        else:
            # just parse loader.json for partitions
            partition_names = parse_loader_json(loader_file)
        print(*partition_names, sep="\n")
        sys.exit(0)

    row_tuples = parse_callset_json_for_row_ranges(callset_file, samples or sample_list)
    attributes = parse_vidmap_json_for_attributes(vidmap_file, args.attributes)

    if args.no_cache:
        os.environ.pop("TILEDB_CACHE", None)
    else:
        os.environ["TILEDB_CACHE"] = "1"

    return workspace, callset_file, vidmap_file, partitions, contigs_map, intervals, row_tuples, attributes, args


def generate_output_filename(output, output_type, interval, idx):
    if output_type == "arrow":
        output_filename = os.path.join(output, f"{interval.replace(':', '-')}")
    else:
        output_filename = f"{output}_{interval.replace(':', '-')}"
    if idx > 0:
        output_filename = output_filename + f"_{idx}"
    if output_type == "arrow":
        return output_filename
    else:
        return output_filename + "." + output_type


def parse_args_for_json_type(json_output_type):
    json_types = {
        "all": json_output_mode.ALL,
        "all-by-calls": json_output_mode.ALL_BY_CALLS,
        "samples-with-num-calls": json_output_mode.SAMPLES_WITH_NUM_CALLS,
        "samples": json_output_mode.SAMPLES,
        "num-calls": json_output_mode.NUM_CALLS,
    }
    return json_types[json_output_type]


def parse_args_for_max_bytes(max_arrow_byte_size):
    max_arrow_byte_size = max_arrow_byte_size.upper()
    units = {"B": 1, "KB": 1024, "MB": 1024**2, "GB": 1024**3, "TB": 1024**4}
    if not re.match(r" ", max_arrow_byte_size):
        max_arrow_byte_size = re.sub(r"([KMGT]?B)", r" \1", max_arrow_byte_size)
    number, unit = max_arrow_byte_size.split()
    return int(float(number) * units[unit])


class GenomicsDBExportConfig(NamedTuple):
    workspace: str
    vidmap_file: str
    callset_file: str
    attributes: str
    filter: str
    bypass_intersecting_intervals_phase: bool

    def __str__(self):
        if self.filter:
            filter_str = f" filter={self.filter}"
        else:
            filter_str = ""
        bypass_str = f" bypass_intersecting_intervals_phase={self.bypass_intersecting_intervals_phase}"
        return f"workspace={self.workspace} attributes={self.attributes}{filter_str}{bypass_str}"


class GenomicsDBQueryConfig(NamedTuple):
    interval: str
    contig: str
    start: int
    end: int
    array_name: str
    row_tuples: List[tuple]

    def __str__(self):
        if self.row_tuples:
            row_tuples_str = f"{self.row_tuples}"
        else:
            row_tuples_str = "ALL"
        return f"\tinterval={self.interval} array={self.array_name} callset rows={row_tuples_str}"


class OutputConfig(NamedTuple):
    filename: str
    type: str
    json_type: str
    max_arrow_bytes: int


class Config(NamedTuple):
    export_config: GenomicsDBExportConfig
    query_config: GenomicsDBQueryConfig
    output_config: OutputConfig


def configure_export(config: GenomicsDBExportConfig):
    export_config = query_pb.ExportConfiguration()
    export_config.workspace = config.workspace
    export_config.vid_mapping_file = config.vidmap_file
    export_config.callset_mapping_file = config.callset_file
    export_config.bypass_intersecting_intervals_phase = config.bypass_intersecting_intervals_phase
    export_config.enable_shared_posixfs_optimizations = True
    if config.attributes:
        export_config.attributes.extend(config.attributes)
    if config.filter:
        export_config.query_filter = config.filter
    return export_config


def configure_query(config: GenomicsDBQueryConfig):
    query_config = query_pb.QueryConfiguration()
    query_config.array_name = config.array_name
    contig_interval = query_coords.ContigInterval()
    contig_interval.contig = config.contig
    contig_interval.begin = config.start
    contig_interval.end = config.end
    query_config.query_contig_intervals.extend([contig_interval])
    row_range_list = None
    if config.row_tuples:
        row_range_list = query_pb.RowRangeList()
        for tuple in config.row_tuples:
            range = query_pb.RowRange()
            range.low = tuple[0]
            range.high = tuple[1]
            row_range_list.range_list.extend([range])
    if row_range_list:
        query_config.query_row_ranges.extend([row_range_list])
    return query_config


def process(config):
    export_config = config.export_config
    query_config = config.query_config
    output_config = config.output_config
    msg = f"array({query_config.array_name}) for interval({query_config.interval})"
    if query_config.row_tuples:
        msg += f" and rows({query_config.row_tuples})"
    if not genomicsdb.array_exists(export_config.workspace, query_config.array_name):
        logging.error(msg + f" not imported into workspace({export_config.workspace})")
        return -1
    global gdb
    try:
        if gdb:
            logging.info("Found gdb to process " + msg)
        else:
            logging.error("Something wrong, gdb seems to be None")
            return -1
    except NameError:
        logging.info("Instantiating genomicsdb to process " + msg + "...")
        gdb = genomicsdb.connect_with_protobuf(configure_export(export_config))
        logging.info("Instantiating genomicsdb to process " + msg + " DONE")
    query_protobuf = configure_query(query_config)
    try:
        if output_config.type == "csv":
            df = gdb.query_variant_calls(query_protobuf=query_protobuf, flatten_intervals=True)
            df.to_csv(output_config.filename, index=False)
        elif output_config.type == "json":
            json_output = gdb.query_variant_calls(query_protobuf=query_protobuf, json_output=output_config.json_type)
            with open(output_config.filename, "wb") as f:
                f.write(json_output)
        elif output_config.type == "arrow":
            nbytes = 0
            writer = None
            i = 0
            for out in gdb.query_variant_calls(query_protobuf=query_protobuf, arrow_output=True, batching=True):
                reader = pa.ipc.open_stream(out)
                for batch in reader:
                    if nbytes > output_config.max_arrow_bytes:
                        i += 1
                        nbytes = 0
                        if writer:
                            writer.close()
                            writer = None
                    if not writer:
                        writer = pq.ParquetWriter(f"{output_config.filename}__{i}.parquet", batch.schema)
                    nbytes += batch.nbytes
                    writer.write_batch(batch)
                if writer:
                    writer.close()
                    writer = None
    except Exception as e:
        logging.critical(f"Unexpected exception : {e}")
        gdb = None
        return -1

    logging.info(f"Processed {msg}")
    return 0


def main():
    workspace, callset_file, vidmap_file, partitions, contigs_map, intervals, row_tuples, attributes, args = setup()

    if row_tuples is not None and len(row_tuples) == 0:
        return

    print(f"Starting genomicsdb_query for workspace({workspace}) and intervals({intervals})")

    output_type = args.output_type
    output = args.output
    json_type = None
    if output_type == "json":
        json_type = parse_args_for_json_type(args.json_output_type)
    max_arrow_bytes = -1
    if output_type == "arrow":
        if not os.path.exists(output):
            os.mkdir(output)
        max_arrow_bytes = parse_args_for_max_bytes(args.max_arrow_byte_size)
        print(f"Using {args.max_arrow_byte_size} number of bytes as hint for writing out parquet files")

    export_config = GenomicsDBExportConfig(
        workspace, vidmap_file, callset_file, attributes, args.filter, args.bypass_intersecting_intervals_phase
    )
    configs = []
    for interval in intervals:
        print(f"Processing interval({interval})...")

        contig, start, end, arrays = genomicsdb_common.get_arrays(interval, contigs_map, partitions)
        if len(arrays) == 0:
            logging.error(f"No arrays in the workspace matched input interval({interval})")
            # continue

        print(f"\tArrays:{arrays} under consideration for interval({interval})")
        for idx, array in enumerate(arrays):
            query_config = GenomicsDBQueryConfig(interval, contig, start, end, array, row_tuples)
            output_config = OutputConfig(
                generate_output_filename(output, output_type, interval, idx),
                output_type,
                json_type,
                max_arrow_bytes,
            )
            configs.append(Config(export_config, query_config, output_config))

    if len(configs) == 0:
        print("Nothing to process!!. Check output for possible errors")
        sys.exit(1)

    # Check if there is room for row_tuples to be parallelized
    chunk_size = int(args.chunk_size)
    if row_tuples is None and len(configs) < args.nproc and chunk_size > 1:
        row_tuples = parse_callset_json_for_split_row_ranges(callset_file, chunk_size)
        if row_tuples:
            new_configs = []
            for idx_row, row_tuple in enumerate(row_tuples):
                for idx, config in enumerate(configs):
                    query_config = config.query_config
                    split_query_config = GenomicsDBQueryConfig(
                        query_config.interval,
                        query_config.contig,
                        query_config.start,
                        query_config.end,
                        query_config.array_name,
                        [row_tuple],
                    )
                    output_config = config.output_config
                    split_output_config = OutputConfig(
                        generate_output_filename(
                            output, output_type, query_config.interval, len(configs) * idx + idx_row
                        ),
                        output_type,
                        json_type,
                        max_arrow_bytes,
                    )
                    new_configs.append(Config(export_config, split_query_config, split_output_config))
            configs = new_configs

    if args.dryrun:
        print(f"Query configurations for {export_config}:")
        for config in configs:
            print(config.query_config)
        sys.exit(0)

    if min(len(configs), args.nproc) == 1:
        results = list(map(process, configs))
    else:
        with multiprocessing.Pool(processes=min(len(configs), args.nproc)) as pool:
            results = list(pool.map(process, configs))

    msg = "successfully"
    for result in results:
        if result != 0:
            msg = "unsuccessfully for some arrays. Check output for errors"
            break

    print(f"genomicsdb_query for workspace({workspace}) and intervals({intervals}) completed {msg}")


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as e:
        logging.error(e)
        sys.exit(1)
