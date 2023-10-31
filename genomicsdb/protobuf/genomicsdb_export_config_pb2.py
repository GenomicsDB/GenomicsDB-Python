# -*- coding: utf-8 -*-
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: genomicsdb_export_config.proto
"""Generated protocol buffer code."""
from google.protobuf.internal import builder as _builder
from google.protobuf import descriptor as _descriptor
from google.protobuf import descriptor_pool as _descriptor_pool
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()


from . import genomicsdb_coordinates_pb2 as genomicsdb__coordinates__pb2
from . import genomicsdb_vid_mapping_pb2 as genomicsdb__vid__mapping__pb2
from . import genomicsdb_callsets_mapping_pb2 as genomicsdb__callsets__mapping__pb2


DESCRIPTOR = _descriptor_pool.Default().AddSerializedFile(b'\n\x1egenomicsdb_export_config.proto\x12\rgenomicsdb_pb\x1a\x1cgenomicsdb_coordinates.proto\x1a\x1cgenomicsdb_vid_mapping.proto\x1a!genomicsdb_callsets_mapping.proto\"^\n\x1eGenomicsDBColumnOrIntervalList\x12<\n\x17\x63olumn_or_interval_list\x18\x01 \x03(\x0b\x32\x1b.GenomicsDBColumnOrInterval\"%\n\x08RowRange\x12\x0b\n\x03low\x18\x01 \x02(\x03\x12\x0c\n\x04high\x18\x02 \x02(\x03\";\n\x0cRowRangeList\x12+\n\nrange_list\x18\x01 \x03(\x0b\x32\x17.genomicsdb_pb.RowRange\"H\n\x0bSparkConfig\x12\x18\n\x10query_block_size\x18\x01 \x01(\x03\x12\x1f\n\x17query_block_size_margin\x18\x02 \x01(\x03\"}\n\x10\x41nnotationSource\x12\x10\n\x08\x66ilename\x18\x01 \x02(\t\x12\x13\n\x0b\x64\x61ta_source\x18\x02 \x02(\t\x12\x12\n\nattributes\x18\x03 \x03(\t\x12\x14\n\x06is_vcf\x18\x04 \x01(\x08:\x04true\x12\x18\n\x10\x66ile_chromosomes\x18\x05 \x03(\t\"\xe8\x02\n\x12QueryConfiguration\x12\x14\n\narray_name\x18\x02 \x01(\tH\x00\x12\x39\n)generate_array_name_from_partition_bounds\x18\x03 \x01(\x08:\x04trueH\x00\x12J\n\x13query_column_ranges\x18\x05 \x03(\x0b\x32-.genomicsdb_pb.GenomicsDBColumnOrIntervalList\x12/\n\x16query_contig_intervals\x18\x06 \x03(\x0b\x32\x0f.ContigInterval\x12\x35\n\x10query_row_ranges\x18\x07 \x03(\x0b\x32\x1b.genomicsdb_pb.RowRangeList\x12\x1a\n\x12query_sample_names\x18\x08 \x03(\t\x12\x12\n\nattributes\x18\t \x03(\t\x12\x14\n\x0cquery_filter\x18\n \x01(\tB\x07\n\x05\x61rray\"\x83\n\n\x13\x45xportConfiguration\x12\x11\n\tworkspace\x18\x01 \x02(\t\x12\x18\n\x10reference_genome\x18\x04 \x01(\t\x12\x14\n\narray_name\x18\x02 \x01(\tH\x00\x12\x39\n)generate_array_name_from_partition_bounds\x18\x03 \x01(\x08:\x04trueH\x00\x12J\n\x13query_column_ranges\x18\x05 \x03(\x0b\x32-.genomicsdb_pb.GenomicsDBColumnOrIntervalList\x12/\n\x16query_contig_intervals\x18\x06 \x03(\x0b\x32\x0f.ContigInterval\x12\x35\n\x10query_row_ranges\x18\x07 \x03(\x0b\x32\x1b.genomicsdb_pb.RowRangeList\x12\x1a\n\x12query_sample_names\x18\x08 \x03(\t\x12\x12\n\nattributes\x18\t \x03(\t\x12\x14\n\x0cquery_filter\x18\n \x01(\t\x12\x1b\n\x13vcf_header_filename\x18\x0b \x01(\t\x12\x1b\n\x13vcf_output_filename\x18\x0c \x01(\t\x12\x19\n\x11vcf_output_format\x18\r \x01(\t\x12\x1a\n\x10vid_mapping_file\x18\x0e \x01(\tH\x01\x12$\n\x0bvid_mapping\x18\x0f \x01(\x0b\x32\r.VidMappingPBH\x01\x12\x1e\n\x14\x63\x61llset_mapping_file\x18\x10 \x01(\tH\x02\x12,\n\x0f\x63\x61llset_mapping\x18\x11 \x01(\x0b\x32\x11.CallsetMappingPBH\x02\x12\x35\n-max_diploid_alt_alleles_that_can_be_genotyped\x18\x12 \x01(\r\x12\x1a\n\x12max_genotype_count\x18\x13 \x01(\r\x12\x18\n\x10index_output_VCF\x18\x14 \x01(\x08\x12\x18\n\x10produce_GT_field\x18\x15 \x01(\x08\x12\x1c\n\x14produce_FILTER_field\x18\x16 \x01(\x08\x12\x18\n\x10sites_only_query\x18\x17 \x01(\x08\x12;\n3produce_GT_with_min_PL_value_for_spanning_deletions\x18\x18 \x01(\x08\x12\x11\n\tscan_full\x18\x19 \x01(\x08\x12\x1e\n\x0csegment_size\x18\x1a \x01(\r:\x08\x31\x30\x34\x38\x35\x37\x36\x30\x12.\n&combined_vcf_records_buffer_size_limit\x18\x1b \x01(\r\x12\x32\n#enable_shared_posixfs_optimizations\x18\x1c \x01(\x08:\x05\x66\x61lse\x12\x32\n#bypass_intersecting_intervals_phase\x18\x1d \x01(\x08:\x05\x66\x61lse\x12\x30\n\x0cspark_config\x18\x1e \x01(\x0b\x32\x1a.genomicsdb_pb.SparkConfig\x12:\n\x11\x61nnotation_source\x18\x1f \x03(\x0b\x32\x1f.genomicsdb_pb.AnnotationSource\x12%\n\x16\x61nnotation_buffer_size\x18  \x01(\r:\x05\x31\x30\x32\x34\x30\x42\x07\n\x05\x61rrayB\x12\n\x10vid_mapping_infoB\x16\n\x14\x63\x61llset_mapping_infoB@\n\x14org.genomicsdb.modelB\x1dGenomicsDBExportConfigurationZ\tprotobuf/')

_builder.BuildMessageAndEnumDescriptors(DESCRIPTOR, globals())
_builder.BuildTopDescriptorsAndMessages(DESCRIPTOR, 'genomicsdb_export_config_pb2', globals())
if _descriptor._USE_C_DESCRIPTORS == False:

  DESCRIPTOR._options = None
  DESCRIPTOR._serialized_options = b'\n\024org.genomicsdb.modelB\035GenomicsDBExportConfigurationZ\tprotobuf/'
  _GENOMICSDBCOLUMNORINTERVALLIST._serialized_start=144
  _GENOMICSDBCOLUMNORINTERVALLIST._serialized_end=238
  _ROWRANGE._serialized_start=240
  _ROWRANGE._serialized_end=277
  _ROWRANGELIST._serialized_start=279
  _ROWRANGELIST._serialized_end=338
  _SPARKCONFIG._serialized_start=340
  _SPARKCONFIG._serialized_end=412
  _ANNOTATIONSOURCE._serialized_start=414
  _ANNOTATIONSOURCE._serialized_end=539
  _QUERYCONFIGURATION._serialized_start=542
  _QUERYCONFIGURATION._serialized_end=902
  _EXPORTCONFIGURATION._serialized_start=905
  _EXPORTCONFIGURATION._serialized_end=2188
# @@protoc_insertion_point(module_scope)
