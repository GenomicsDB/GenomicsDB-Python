#
# publish_package_local.sh
#
# The MIT License (MIT)
#
# Copyright (c) 2023 dātma, inc™
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Description: Bash script to publish locally on MacOS
#

#!/bin/bash

PREFIX_DIR=${PREFIX_DIR:-$(mktemp -d)}
GENOMICSDB_DIR=$PREFIX_DIR/GenomicsDB
GENOMICSDB_HOME=$GENOMICSDB_DIR/release
GENOMICSDB_BRANCH=${GENOMICSDB_BRANCH:-master}

GENOMICSDB_PYTHON_DIR=$(readlink -f `pwd`/..)

MACOSX_DEPLOYMENT_TARGET=12.1
HOMEBREW_NO_AUTO_UPDATE=1

die() {
  if [[ $# -eq 1 ]]; then
    echo $1
  fi
  exit 1
}

check_rc() {
  if [[ $# -eq 1 ]]; then
    if [[ $1 -ne 0 ]]; then
      die "command returned $1. Quitting Installation of python"
    fi
  fi
}

install_prereqs() {
  HOMEBREW_NO_AUTO_UPDATE=1
  HOMEBREW_NO_INSTALL_CLEANUP=1
  check_rc $(brew list openssl@3 &> /dev/null || brew install openssl@3)
  export OPENSSL_ROOT_DIR=$(brew --prefix openssl@3)
  brew list libcsv &> /dev/null && brew uninstall libcsv
  # Use the uuid from framework
  brew list ossp-uuid &> /dev/null && brew uninstall ossp-uuid

}

install_python_version() {
  check_rc $(brew list python@$1 &> /dev/null || brew install python@$1)
}

publish_package() {
	PYTHON_VERSION=$1
  install_python_version $PYTHON_VERSION
  echo "Publishing python package for $1 ..."
  pushd /tmp
	python$PYTHON_VERSION -m venv try$PYTHON_VERSION &&
		source try$PYTHON_VERSION/bin/activate &&
		pip install --upgrade pip &&
    pushd $GENOMICSDB_PYTHON_DIR &&
    pip install -r package/requirements_pkg.txt &&
    python setup.py sdist --with-genomicsdb=$GENOMICSDB_HOME &&
	  python setup.py bdist_wheel --with-genomicsdb=$GENOMICSDB_HOME --with-libs &&
    popd &&
		deactivate
	RC=$?
	rm -fr try$PYTHON_VERSION
  popd
	check_rc $RC
  echo "Publishing package for python $PYTHON_VERSION DONE"
}

publish() {
  echo "Installing Python" &&
  publish_package 3.9 &&
  publish_package 3.10 &&
  publish_package 3.11
}

install_genomicsdb() {
  echo "Building GenomicsDB in $GENOMICSDB_DIR..."
  rm -fr $GENOMICSDB_DIR
  git clone https://github.com/GenomicsDB/GenomicsDB.git -b $GENOMICSDB_BRANCH $GENOMICSDB_DIR
  pushd $GENOMICSDB_DIR
  mkdir build
  cd build
  cmake -DCMAKE_INSTALL_PREFIX=$GENOMICSDB_HOME -DCMAKE_PREFIX_PATH=$OPENSSL_ROOT_DIR -DPROTOBUF_ROOT_DIR=./protobuf-install -DAWSSDK_ROOT_DIR=./aws-install -DGCSSDK_ROOT_DIR=./gcs-install -DBUILD_EXAMPLES=False -DDISABLE_MPI=True -DDISABLE_OPENMP=True -DUSE_HDFS=False .. &&
    make && make install
  popd
  if [[ -f $GENOMICSDB_HOME/lib/libtiledbgenomicsdb.dylib ]]; then
    echo "Building GenomicsDB in $GENOMICSDB_DIR DONE"
  else
    echo "Something wrong with building GenomicsDB at $GENOMICSDB_HOME"
    exit 1
  fi
}

if [[ `uname` != "Darwin" ]]; then
  echo "Script needs porting for Non-MacOS systems"
  exit 1
fi

install_prereqs
install_genomicsdb &&
  publish

rm -fr $GENOMICSDB_DIR
