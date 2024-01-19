#!/bin/bash
install_prereqs_for_mac() {
  HOMEBREW_NO_AUTO_UPDATE=1
  HOMEBREW_NO_INSTALL_CLEANUP=1
  brew list openssl@3 &> /dev/null || brew install openssl@3
  brew list libcsv &> /dev/null && brew uninstall libcsv
  # Use the uuid from framework
  brew list ossp-uuid &> /dev/null && brew uninstall ossp-uuid
  brew list cmake &>/dev/null || brew install cmake
  brew list automake &> /dev/null || brew install automake
  brew list pkg-config &> /dev/null || brew install pkg-config
}

install_prereqs_for_centos7() {
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
    echo "Installing minimal dependencies DONE"
}

install_genomicsdb_for_mac() {
    PREFIX_DIR=${PREFIX_DIR:-$(mktemp -d)}
    GENOMICSDB_DIR=$PREFIX_DIR/GenomicsDB
    GENOMICSDB_HOME=/usr/local
    export $GENOMICSDB_HOME
    export MACOSX_DEPLOYMENT_TARGET=12.1
    export OPENSSL_ROOT_DIR=$(brew --prefix openssl@3)
    rm -fr $GENOMICSDB_DIR
    git clone https://github.com/GenomicsDB/GenomicsDB.git $GENOMICSDB_DIR
    pushd $GENOMICSDB_DIR
    echo "Starting GenomicsDB build"
    mkdir build && cd build &&
    cmake -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" -DCMAKE_INSTALL_PREFIX=$GENOMICSDB_HOME -DCMAKE_PREFIX_PATH=$OPENSSL_ROOT_DIR -DPROTOBUF_ROOT_DIR=./protobuf-install -DAWSSDK_ROOT_DIR=./aws-install -DGCSSDK_ROOT_DIR=./gcs-install -DBUILD_EXAMPLES=False -DDISABLE_MPI=True -DDISABLE_OPENMP=True -DUSE_HDFS=False .. &&
        make -j4 && make install
    popd
    if [[ -f $GENOMICSDB_HOME/lib/libtiledbgenomicsdb.dylib ]]; then
        echo "Building GenomicsDB in $GENOMICSDB_DIR DONE"
    else
        echo "Something wrong with building GenomicsDB at $GENOMICSDB_HOME"
        exit 1
    fi
}

install_genomicsdb_for_centos7() {
    source /opt/rh/devtoolset-11/enable
    INSTALL_PREFIX=/usr/local
    export OPENSSL_ROOT_DIR=$INSTALL_PREFIX
    export LD_LIBRARY_PATH=$INSTALL_PREFIX/lib64:$INSTALL_PREFIX/lib:$LD_LIBRARY_PATH
    git clone https://github.com/GenomicsDB/GenomicsDB.git GenomicsDB-build
    pushd GenomicsDB-build
    echo "Starting GenomicsDB build"
    mkdir build && cd build &&
    cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DBUILD_EXAMPLES=False -DDISABLE_MPI=True -DDISABLE_OPENMP=True -DUSE_HDFS=False .. &&
        make && echo "Make succeded" && make install && find /usr/local -name *genomicsdb*
    popd
}

install_openssl3_for_centos7() {
  source /opt/rh/devtoolset-11/enable
  echo "Building openssl..."
  OPENSSL_PREFIX=/usr/local
  OPENSSL_VERSION=3.0.11
  if [[ ! -d $OPENSSL_PREFIX/include/openssl ]]; then
    pushd /tmp
    wget $WGET_NO_CERTIFICATE https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz &&
      tar -xvzf openssl-$OPENSSL_VERSION.tar.gz &&
      cd openssl-$OPENSSL_VERSION &&
      CFLAGS=-fPIC ./config no-tests -fPIC --prefix=$OPENSSL_PREFIX --openssldir=$OPENSSL_PREFIX &&
      make -j4 && make install && echo "Installing OpenSSL DONE"
    rm -fr /tmp/openssl*
    popd
  fi
}

git clone https://github.com/GenomicsDB/GenomicsDB.git GenomicsDB-native
pushd GenomicsDB-native
scripts/prereqs/install_prereqs.sh
echo "Runner HOME=$HOME"
source $HOME/genomicsdb_prereqs.sh 
echo "OPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR"
mkdir build && cd build
if [[ $(uname) == "Darwin" ]]; then
  cmake -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" -DBUILD_EXAMPLES=False -DDISABLE_MPI=True -DDISABLE_OPENMP=True -DUSE_HDFS=False ..
else
  cmake -DBUILD_EXAMPLES=False -DDISABLE_MPI=True -DDISABLE_OPENMP=True -DUSE_HDFS=False ..
fi
make && make install
popd

exit 0


if [[ `uname` != "Darwin" ]]; then
  install_prereqs_for_centos7
  install_openssl3_for_centos7
  install_genomicsdb_for_centos7
else
  install_prereqs_for_mac
  install_genomicsdb_for_mac
fi
