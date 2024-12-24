#
# genomicsdb_common python script
#
# The MIT License
#
# Copyright (c) 2024 dātma, inc™
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

import json
import os
import re
import sys

import genomicsdb


def normalize_path(path):
    if "://" in path:
        return path
    else:
        return os.path.abspath(path)


def parse_vidmap_json(vidmap_file, intervals=None):
    if isinstance(intervals, str):
        is_file = True
    else:
        is_file = False
    contigs_map = {}
    vidmap = json.loads(genomicsdb.read_entire_file(vidmap_file))
    contigs = vidmap["contigs"]
    if intervals and is_file:
        with open(intervals) as file:
            intervals = [line.rstrip() for line in file]
    all_intervals = not intervals
    if not intervals:
        intervals = []
    for contig in contigs:
        if isinstance(contig, str):  # Old style vidmap json
            contig_name = contig
            contigs_map[contig] = {
                "length": contigs[contig]["length"],
                "tiledb_column_offset": contigs[contig]["tiledb_column_offset"],
            }
        else:  # Generated with vcf2genomicsdb_init
            contig_name = contig["name"]
            contigs_map[contig["name"]] = contig
        if all_intervals:
            intervals.append(contig_name)
    return contigs_map, intervals


interval_pattern = re.compile(r"(.*):(.*)-(.*)|(.*):(.*)|(.*)")


# get tiledb offsets for interval
def parse_interval(interval: str):
    result = re.match(interval_pattern, interval)
    if result:
        length = len(result.groups())
        if length == 6:
            if result.group(1) and result.group(2) and result.group(3):
                return result.group(1), int(result.group(2)), int(result.group(3))
            elif result.group(4) and result.group(5):
                return result.group(4), int(result.group(5)), None
            elif result.group(6):
                return result.group(6), 1, None
    raise RuntimeError(f"Interval {interval} could not be parsed")


def get_arrays(interval, contigs_map, partitions):
    contig, start, end = parse_interval(interval)
    if contig in contigs_map:
        contig_offset = contigs_map[contig]["tiledb_column_offset"] + start - 1
        length = contigs_map[contig]["length"]
        if end and end < length + 1:
            contig_end = contigs_map[contig]["tiledb_column_offset"] + end - 1
        else:
            end = length
            contig_end = contigs_map[contig]["tiledb_column_offset"] + length - 1
    else:
        print(f"Contig({contig}) not found in vidmap.json")

    arrays = []
    for idx, partition in enumerate(partitions):
        if isinstance(partition["begin"], int):  # Old style vidmap json
            column_begin = partition["begin"]
            if "end" in partition.keys():
                column_end = partition["end"]
            elif idx + 1 < len(partitions):
                column_end = partitions[idx + 1]["begin"] - 1
            else:
                column_end = sys.maxsize
        else:  # Generated with vcf2genomicsdb_init
            column_begin = partition["begin"]["tiledb_column"]
            column_end = partition["end"]["tiledb_column"]

        if contig_end < column_begin or contig_offset > column_end:
            continue

        if "array_name" in partition.keys():
            arrays.append(partition["array_name"])
        elif "array" in partition.keys():
            arrays.append(partition["array"])

    return contig, start, end, arrays
