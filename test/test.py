import os
import shutil
import sys
import tarfile
import tempfile

from genomicsdb import *

def run_test():
	version()
	gdb = connect("ws", "callset_t0_1_2.json", "vid.json", "chr1_10MB.fasta.gz", ["DP"], 40)
	

tmp_dir = tempfile.TemporaryDirectory().name

if not os.path.exists(tmp_dir):
	os.makedirs(tmp_dir)
else:
	sys.exit("Aborting as temporary directory seems to exist!")

tar = tarfile.open("test/inputs/sanity.test.tgz")
tar.extractall(tmp_dir)

os.chdir(tmp_dir)

run_test()

shutil.rmtree(tmp_dir)


