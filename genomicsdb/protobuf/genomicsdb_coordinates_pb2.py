# -*- coding: utf-8 -*-
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: genomicsdb_coordinates.proto
"""Generated protocol buffer code."""
from google.protobuf.internal import builder as _builder
from google.protobuf import descriptor as _descriptor
from google.protobuf import descriptor_pool as _descriptor_pool
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()




DESCRIPTOR = _descriptor_pool.Default().AddSerializedFile(b'\n\x1cgenomicsdb_coordinates.proto\"2\n\x0e\x43ontigPosition\x12\x0e\n\x06\x63ontig\x18\x01 \x02(\t\x12\x10\n\x08position\x18\x02 \x02(\x03\"a\n\x10GenomicsDBColumn\x12\x17\n\rtiledb_column\x18\x01 \x01(\x03H\x00\x12*\n\x0f\x63ontig_position\x18\x02 \x01(\x0b\x32\x0f.ContigPositionH\x00\x42\x08\n\x06\x63olumn\"2\n\x14TileDBColumnInterval\x12\r\n\x05\x62\x65gin\x18\x01 \x02(\x03\x12\x0b\n\x03\x65nd\x18\x02 \x02(\x03\"<\n\x0e\x43ontigInterval\x12\x0e\n\x06\x63ontig\x18\x01 \x02(\t\x12\r\n\x05\x62\x65gin\x18\x02 \x01(\x03\x12\x0b\n\x03\x65nd\x18\x03 \x01(\x03\"\x8b\x01\n\x18GenomicsDBColumnInterval\x12\x37\n\x16tiledb_column_interval\x18\x01 \x01(\x0b\x32\x15.TileDBColumnIntervalH\x00\x12*\n\x0f\x63ontig_interval\x18\x02 \x01(\x0b\x32\x0f.ContigIntervalH\x00\x42\n\n\x08interval\"\x8d\x01\n\x1aGenomicsDBColumnOrInterval\x12#\n\x06\x63olumn\x18\x01 \x01(\x0b\x32\x11.GenomicsDBColumnH\x00\x12\x34\n\x0f\x63olumn_interval\x18\x02 \x01(\x0b\x32\x19.GenomicsDBColumnIntervalH\x00\x42\x14\n\x12\x63olumn_or_intervalB.\n\x14org.genomicsdb.modelB\x0b\x43oordinatesZ\tprotobuf/')

_builder.BuildMessageAndEnumDescriptors(DESCRIPTOR, globals())
_builder.BuildTopDescriptorsAndMessages(DESCRIPTOR, 'genomicsdb_coordinates_pb2', globals())
if _descriptor._USE_C_DESCRIPTORS == False:

  DESCRIPTOR._options = None
  DESCRIPTOR._serialized_options = b'\n\024org.genomicsdb.modelB\013CoordinatesZ\tprotobuf/'
  _CONTIGPOSITION._serialized_start=32
  _CONTIGPOSITION._serialized_end=82
  _GENOMICSDBCOLUMN._serialized_start=84
  _GENOMICSDBCOLUMN._serialized_end=181
  _TILEDBCOLUMNINTERVAL._serialized_start=183
  _TILEDBCOLUMNINTERVAL._serialized_end=233
  _CONTIGINTERVAL._serialized_start=235
  _CONTIGINTERVAL._serialized_end=295
  _GENOMICSDBCOLUMNINTERVAL._serialized_start=298
  _GENOMICSDBCOLUMNINTERVAL._serialized_end=437
  _GENOMICSDBCOLUMNORINTERVAL._serialized_start=440
  _GENOMICSDBCOLUMNORINTERVAL._serialized_end=581
# @@protoc_insertion_point(module_scope)
