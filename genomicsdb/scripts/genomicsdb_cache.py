#!/usr/bin/env python

#
# genomicsdb_cache python script
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

import genomicsdb
from genomicsdb.scripts import genomicsdb_common


def is_cloud_path(path):
    if "://" in path:
        return True
    else:
        return False


def get_arrays(interval, contigs_map, partitions):
    _, _, _, arrays = genomicsdb_common.get_arrays(interval, contigs_map, partitions)
    return arrays


def main():
    parser = argparse.ArgumentParser(
        prog="cache",
        description="Cache GenomicsDB metadata and generated callset/vidmap/loader json artifacts for workspace cloud URLs. The metadata is copied to TMPDIR and the json files to the current working directory",  # noqa
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
    parser.add_argument(
        "-i",
        "--interval",
        action="append",
        required=False,
        help="Optional - genomic intervals over which to operate. The intervals should be specified in the <CONTIG>:<START>-<END> format with START and END optional.\nThis argument may be specified 0 or more times e.g -i chr1:1-10000 -i chr2 -i chr3:1000. \nNote: \n\t1. -i/--interval and -I/--interval-list are mutually exclusive \n\t2. either samples and/or intervals using -i/-I/-s/-S options has to be specified",  # noqa
    )
    parser.add_argument(
        "-I",
        "--interval-list",
        required=False,
        help="Optional - genomic intervals listed in a file over which to operate.\nThe intervals should be specified in the <CONTIG>:<START>-<END> format, with START and END optional one interval per line. \nNote: \n\t1. -i/--interval and -I/--interval-list are mutually exclusive \n\t2. either samples and/or intervals using -i/-I/-s/-S options has to be specified",  # noqa
    )

    args = parser.parse_args()

    workspace = genomicsdb_common.normalize_path(args.workspace)
    if not genomicsdb.workspace_exists(workspace):
        raise RuntimeError(f"workspace({workspace}) not found")

    callset_file = args.callset
    if not callset_file:
        callset_file = workspace + "/callset.json"
    vidmap_file = args.vidmap
    if not vidmap_file:
        vidmap_file = workspace + "/vidmap.json"
    loader_file = args.loader
    if not loader_file:
        loader_file = workspace + "/loader.json"
    if (
        not genomicsdb.is_file(callset_file)
        or not genomicsdb.is_file(vidmap_file)
        or not genomicsdb.is_file(loader_file)
    ):
        raise RuntimeError(f"callset({callset_file}) vidmap({vidmap_file}) or loader({loader_file}) not found")

    if is_cloud_path(callset_file):
        with open("callset.json", "wb") as f:
            f.write(genomicsdb.read_entire_file(callset_file).encode())
    if is_cloud_path(vidmap_file):
        with open("vidmap.json", "wb") as f:
            f.write(genomicsdb.read_entire_file(vidmap_file).encode())
    if is_cloud_path(loader_file):
        with open("loader.json", "wb") as f:
            f.write(genomicsdb.read_entire_file(loader_file).encode())
    if is_cloud_path(workspace) and (args.interval or args.interval_list):
        contigs_map, intervals = genomicsdb_common.parse_vidmap_json(vidmap_file, args.interval or args.interval_list)
        loader = json.loads(genomicsdb.read_entire_file("loader.json"))
        partitions = loader["column_partitions"]
        arrays = {
            arrays_for_interval
            for interval in intervals
            for arrays_for_interval in get_arrays(interval, contigs_map, partitions)
        }
        for array in arrays:
            print(f"Caching fragments for array {array}")
            if genomicsdb.array_exists(workspace, array):
                genomicsdb.cache_array_metadata(workspace, array)


if __name__ == "__main__":
    main()
