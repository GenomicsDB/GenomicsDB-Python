# distutils: language = c++
# cython: language_level=3

include "utils.pxi"

def version():
	version_string = genomicsdb_version()
	return version_string


def connect(workspace, callset_mapping_file, vid_mapping_file, reference_genome, attributes, segment_size):
	return _GenomicsDB(workspace, callset_mapping_file, vid_mapping_file, reference_genome, attributes, segment_size)

cdef void process_interval(interval_t interval):
	print(interval.first, interval.second)

cdef void	process_variant_call(uint32_t row,
															 genomic_interval_t interval,
															 vector[genomic_field_t] fields):
	print(row, interval.contig_name)

cdef class _GenomicsDB:
	cdef GenomicsDB* _genomicsdb
	cdef VariantCallProcessor _processor

	def __cinit__(self):
		self._genomicsdb = NULL

	def __init__(self,
							 workspace,
							 callset_mapping_file,
							 vid_mapping_file,
							 reference_genome,
							 attributes = None,
							 segment_size = None):
		cdef string ws = as_string(workspace)
		print("Got ws")
		cdef vector[string] vec = as_vector(attributes)
		print("Got attributes")
		if attributes is None:
			self._genomicsdb  = new GenomicsDB(as_string(workspace),
																				 as_string(callset_mapping_file),
																				 as_string(vid_mapping_file),
																				 as_string(reference_genome))
		elif segment_size is None:
			self._genomicsdb  = new GenomicsDB(as_string(workspace),
																				 as_string(callset_mapping_file),
																				 as_string(vid_mapping_file),
																				 as_string(reference_genome),
																				 as_vector(attributes))
		else:
			self._genomicsdb  = new GenomicsDB(as_string(workspace),
																				 as_string(callset_mapping_file),
																				 as_string(vid_mapping_file),
																				 as_string(reference_genome),
																				 as_vector(attributes),
																				 segment_size)
		print("Got GDB instance")

	def query_variant_calls(self,
													array=None,
													column_ranges=None,
													row_ranges=None):
		print("we are in query_variant calls")
		cdef function[void(interval_t)] process_interval_fn = process_interval
		cdef function[void(uint32_t, genomic_interval_t, vector[genomic_field_t])] process_variant_call_fn = process_variant_call;
		self._processor.setup_callbacks(process_interval_fn, process_variant_call_fn)
		if array is None:
			print("array is none")
			self._genomicsdb.query_variant_calls()
		elif column_ranges is None:
			print("Column is None")
			self._genomicsdb.query_variant_calls(as_string(array))
		elif row_ranges is None:
			print("Row is None")
			self._genomicsdb.query_variant_calls(as_string(array),
																					 as_ranges(column_ranges))
		else:
			self._genomicsdb.query_variant_calls(self._processor, as_string(array),
																					 as_ranges(column_ranges),
																					 as_ranges(row_ranges))

	def __dealloc__(self):
		print("Cleaning up")
		if self._genomicsdb != NULL:
			del self._genomicsdb
		print("Cleanup Done")

