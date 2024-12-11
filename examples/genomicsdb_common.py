import json
import os
import re

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
        contigs_map[contig["name"]] = contig
        if all_intervals:
            intervals.append(contig["name"])
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


def get_arrays(contigs_map, intervals, partitions):
    arrays = set()
    for interval in intervals:
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
            continue

        for partition in partitions:
            if contig_end < partition["begin"]["tiledb_column"] or contig_offset > partition["end"]["tiledb_column"]:
                continue
            arrays.add(partition["array_name"])

    return arrays
