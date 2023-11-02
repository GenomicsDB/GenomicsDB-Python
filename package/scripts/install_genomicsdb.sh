#
# install_genomicsdb.sh
#
# The MIT License (MIT)
# Copyright (c) 2022 Omics Data Automation, Inc.
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
# Description: Script to build GenomicsDB
#

#!/bin/bash

set -e

. /etc/profile

USER=$1
BRANCH=$2

INSTALL_PREFIX=/usr/local

OPENSSL_VERSION=${OPENSSL_VERSION:-3.0.11}

echo "Installing minimal dependencies..."
yum install -y centos-release-scl && yum install -y devtoolset-11 &&
  yum install -y -q deltarpm &&
  yum update -y -q &&
  yum install -y -q epel-release &&
  yum install -y -q which wget git &&
  yum install -y -q autoconf automake libtool unzip &&
  yum install -y -q cmake3 patch &&
  yum install -y -q perl perl-IPC-Cmd &&
  yum install -y -q libuuid libuuid-devel &&
  yum install -y -q curl libcurl-devel &&
  yum install -y -q openssl-devel &&
  echo "Installing minimal dependencies DONE"

source /opt/rh/devtoolset-11/enable


echo "git clone https://github.com/GenomicsDB/GenomicsDB.git -b $BRANCH GenomicsDB"
git clone https://github.com/GenomicsDB/GenomicsDB.git -b $BRANCH GenomicsDB

./GenomicsDB/scripts/prereqs/install_prereqs.sh "full"

echo "Building openssl..."
OPENSSL_PREFIX=$INSTALL_PREFIX
if [[ ! -d $OPENSSL_PREFIX/include/openssl ]]; then
  pushd /tmp
  wget $WGET_NO_CERTIFICATE https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz &&
    tar -xvzf openssl-$OPENSSL_VERSION.tar.gz &&
    cd openssl-$OPENSSL_VERSION &&
    CFLAGS=-fPIC ./config no-tests -fPIC --prefix=$OPENSSL_PREFIX --openssldir=$OPENSSL_PREFIX &&
    make && make install && echo "Installing OpenSSL DONE"
  rm -fr /tmp/openssl*
  popd
fi
export OPENSSL_ROOT_DIR=$OPENSSL_PREFIX
export LD_LIBRARY_PATH=$INSTALL_PREFIX/lib64:$INSTALL_PREFIX/lib:$LD_LIBRARY_PATH

cd GenomicsDB
echo "Starting GenomicsDB build"
mkdir build && cd build &&
  cmake3 -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DBUILD_EXAMPLES=False -DDISABLE_MPI=True -DDISABLE_OPENMP=True -DUSE_HDFS=False .. &&
  make && make install
cd ../..

if [[ -f $INSTALL_PREFIX/lib/libtiledbgenomicsdb.so ]]; then
  echo "GenomicsDB for Python installed successfully"
else
  echo "GenomicsDB does not seem to have installed properly"
  exit 1
fi
