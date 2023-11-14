#!/bin/bash
PREFIX_DIR=${PREFIX_DIR:-$(mktemp -d)}
GENOMICSDB_DIR=$PREFIX_DIR/GenomicsDB
GENOMICSDB_HOME=$GENOMICSDB_DIR/release
export $GENOMICSDB_HOME
export MACOSX_DEPLOYMENT_TARGET=10.13
export OPENSSL_ROOT_DIR=$(brew --prefix openssl@3)
rm -fr $GENOMICSDB_DIR
git clone https://github.com/GenomicsDB/GenomicsDB.git -b develop $GENOMICSDB_DIR
pushd $GENOMICSDB_DIR
echo "Starting GenomicsDB build"
mkdir build && cd build &&
cmake -DCMAKE_INSTALL_PREFIX=$GENOMICSDB_HOME -DCMAKE_PREFIX_PATH=$OPENSSL_ROOT_DIR -DPROTOBUF_ROOT_DIR=./protobuf-install -DAWSSDK_ROOT_DIR=./aws-install -DGCSSDK_ROOT_DIR=./gcs-install -DBUILD_EXAMPLES=False -DDISABLE_MPI=True -DDISABLE_OPENMP=True -DUSE_HDFS=False .. &&
	make && make install
popd
  if [[ -f $GENOMICSDB_HOME/lib/libtiledbgenomicsdb.dylib ]]; then
    echo "Building GenomicsDB in $$GENOMICSDB_DIR DONE"
  else
    echo "Something wrong with building GenomicsDB at $GENOMICSDB_HOME"
    exit 1
  fi