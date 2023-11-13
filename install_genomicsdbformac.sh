#!/bin/bash
INSTALL_PREFIX=/usr/local
export OPENSSL_ROOT_DIR=$(brew --prefix openssl@3)
git clone https://github.com/GenomicsDB/GenomicsDB.git -b develop GenomicsDB-build
cd GenomicsDB-build
echo "Starting GenomicsDB build"
mkdir build && cd build &&
cmake -DCMAKE_INSTALL_PREFIX=$GENOMICSDB_HOME -DPROTOBUF_ROOT_DIR=./protobuf-install -DAWSSDK_ROOT_DIR=./aws-install -DGCSSDK_ROOT_DIR=./gcs-install -DBUILD_EXAMPLES=False -DDISABLE_MPI=True -DDISABLE_OPENMP=True -DUSE_HDFS=False .. &&
	make -j4 && make install
cd ../..
  if [[ -f $INSTALL_PREFIX/lib/libtiledbgenomicsdb.dylib ]]; then
    echo "Building GenomicsDB in $GENOMICSDB_DIR DONE"
  else
    echo "Something wrong with building GenomicsDB at $GENOMICSDB_HOME"
    exit 1
  fi