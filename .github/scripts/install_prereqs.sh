#!/bin/bash

# The MIT License (MIT)
# Copyright (c) 2024 dātma, inc™
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

INSTALL_PREFIX=${INSTALL_PREFIX:-/usr/local}

install_openssl3() {
  echo "Building openssl..."
  OPENSSL_PREFIX=${OPENSSL_PREFIX:-$INSTALL_PREFIX}
  OPENSSL_VERSION=${OPENSSL_VERSION:-3.0.12}
  if [[ ! -d $OPENSSL_PREFIX/include/openssl ]]; then
    echo "Installing OpenSSL3 into $OPENSSL_PREFIX"
    pushd /tmp
    wget -q $WGET_NO_CERTIFICATE https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz &&
      tar -xzf openssl-$OPENSSL_VERSION.tar.gz &&
      cd openssl-$OPENSSL_VERSION &&
      if [[ $(uname) == "Darwin" ]]; then
        if [[ -z $OSX_ARCH ]]; then
          ./Configure darwin64-$(uname -m)-cc no-tests no-shared -fPIC --prefix=$OPENSSL_PREFIX
        else
          ./Configure darwin64-${OSX_ARCH}-cc no-tests no-shared -fPIC --prefix=$OPENSSL_PREFIX
        fi
      else
        CFLAGS=-fPIC ./config no-tests no-shared -fPIC --prefix=$OPENSSL_PREFIX --openssldir=$OPENSSL_PREFIX
      fi
    if [[ ! -d $OPENSSL_PREFIX ]]; then
      echo "Creating $OPENSSL_PREFIX folder"
      mkdir -p $OPENSSL_PREFIX
    fi
    make -j4 && $SUDO make install_sw && echo "Installing OpenSSL DONE"
    rm -fr /tmp/openssl*
    popd
  fi
  export OPENSSL_ROOT_DIR=$OPENSSL_PREFIX
}

install_curl() {
  CURL_PREFIX=${CURL_PREFIX:-$INSTALL_PREFIX}
  CURL_VERSION=${CURL_VERSION:-7.83.1}
  if [[ ! -f $CURL_PREFIX/libcurl.a ]]; then
    echo "Installing CURL into $CURL_PREFIX"
    pushd /tmp
    CURL_VERSION_=$(echo $CURL_VERSION | sed -r 's/\./_/g')
    wget -q $WGET_NO_CERTIFICATE https://github.com/curl/curl/releases/download/curl-$CURL_VERSION_/curl-$CURL_VERSION.tar.gz &&
    tar xzf curl-$CURL_VERSION.tar.gz &&
    cd curl-$CURL_VERSION &&
    ./configure --disable-shared --with-pic -without-zstd --with-ssl=$OPENSSL_PREFIX --prefix $CURL_PREFIX &&
      make && $SUDO make install && echo "Installing CURL DONE"
    rm -fr /tmp/curl
    popd
  fi
}

install_uuid() {
  UUID_PREFIX=${UUID_PREFIX:-$INSTALL_PREFIX}
  UUID_VERSION=${UUID_VERSION:-1.0.3}
  if [[ ! -f $UUID_PREFIX/libuuid.a ]]; then
    echo "Installing libuuid into $UUID_PREFIX"
    pushd /tmp
    wget -q $WGET_NO_CERTIFICATE https://sourceforge.net/projects/libuuid/files/libuuid-$UUID_VERSION.tar.gz &&
      tar -xvzf libuuid-$UUID_VERSION.tar.gz &&
      cd libuuid-$UUID_VERSION &&
      sed -i s/2.69/2.63/ configure.ac &&
      aclocal &&
      automake --add-missing &&
      ./configure --with-pic CFLAGS="-I/usr/include/x86_64-linux-gnu" --disable-shared --enable-static --prefix $UUID_PREFIX &&
      autoreconf -i -f &&
      make && $SUDO make install && echo "Installing libuuid DONE"
    rm -fr /tmp/libuuid*
    popd
  fi
}

install_prereqs_for_macos() {
  HOMEBREW_NO_AUTO_UPDATE=1
  HOMEBREW_NO_INSTALL_CLEANUP=1
  # Use the uuid from framework
  brew list ossp-uuid &> /dev/null && brew uninstall ossp-uuid
  brew list cmake &>/dev/null || brew install cmake
  brew list automake &> /dev/null || brew install automake
  brew list pkg-config &> /dev/null || brew install pkg-config
  if [[ $1 == "release" ]]; then
    install_openssl3
  else
    brew list openssl@3 &> /dev/null || brew install openssl@3
    export OPENSSL_ROOT_DIR=$(brew --prefix openssl@3)
    brew list zstd &>/dev/null || brew install zstd
    brew list catch2 &>/dev/null || brew install catch2
  fi
}

install_prereqs_for_centos7() {
  yum install -y -q which wget git &&
    yum install -y -q autoconf automake libtool unzip &&
    yum install -y -q cmake3 patch &&
    yum install -y -q perl perl-IPC-Cmd &&
    echo "Installing devtoolset-11-GCC for semaphore support for cibuildwheel manylinux2014 builds" &&
    yum install -y -q devtoolset-11-gcc devtoolset-11-gcc-c++ &&
    export CC=/opt/rh/devtoolset-11/root/usr/bin/gcc &&
    export CXX=/opt/rh/devtoolset-11/root/usr/bin/g++ &&
    ls -l /opt/rh/devtoolset-11/root/usr/bin/gcc &&
    ls -l /opt/rh/devtoolset-11/root/usr/bin/g++ &&
    echo "Installing devtoolset DONE"
  if [[ $? != 0 ]]; then exit 1; fi
  if [[ $1 == "release" ]]; then
    install_openssl3
    install_curl
    install_uuid
  elif [[ ! -d ~/catch2-install ]]; then
    INSTALL_DIR=~/catch2-install CATCH2_VER=v$CATCH2_VER $GITHUB_WORKSPACE/.github/scripts/install_catch2.sh
    yum install -y -q libuuid libuuid-devel &&
    yum install -y -q curl libcurl-devel
  fi
}

install_prereqs_for_ubuntu() {
  sudo apt-get update -qq
  sudo apt-get -y install cmake
  sudo apt-get -y install zlib1g-dev zstd
  sudo apt-get -y install libssl-dev uuid-dev libcurl4-openssl-dev zstd
  if [[ $1 == "release" ]]; then
    install_openssl3
    install_curl
    install_uuid
  elif [[ ! -d ~/catch2-install ]]; then
    INSTALL_DIR=~/catch2-install CATCH2_VER=v$CATCH2_VER $GITHUB_WORKSPACE/.github/scripts/install_catch2.sh
  fi
}

echo "INSTALL_PREFIX=$INSTALL_PREFIX"

case $(uname) in
  Linux )
    if apt-get --version >/dev/null 2>&1; then
      export DEBIAN_FRONTEND=noninteractive
      install_prereqs_for_ubuntu $1
    else
      CENTOS_RELEASE_FILE=/etc/centos-release
      if [[ ! -f $CENTOS_RELEASE_FILE ]]; then
        CENTOS_RELEASE_FILE=/etc/redhat-release
        if [[ ! -f $CENTOS_RELEASE_FILE ]]; then
          echo "Only Ubuntu and Centos are supported"
          exit -1
        fi
      fi
      if grep -q "release 7" $CENTOS_RELEASE_FILE; then
        install_prereqs_for_centos7 $1
      else
        cat $CENTOS_RELEASE_FILE
        echo "Only Centos 7 is supported"
        exit -1
      fi
    fi
    ;;
  Darwin )
    if [[ $INSTALL_PREFIX == "/usr/local" ]]; then
      SUDO="sudo"
    fi
    install_prereqs_for_macos $1
    ;;
  * )
    echo "OS=`uname` not supported"
    exit 1
esac

rebuild() {
  echo "GenomicsDB build may not have been successful because of the way aws sdks are structured at least in Linux"
  echo "Trying again with a new make..."
  rm -fr dependencies/TileDB && make -j4
}

if [[ $1 == "release" ]]; then
  echo "System PKG_CONFIG_PATH=$(pkg-config --variable pc_path pkg-config)"
  if [[ -z $OSX_ARCH ]]; then
    NATIVE_BUILD_DIR=GenomicsDB-native
  else
    NATIVE_BUILD_DIR=GenomicsDB-native_${OSX_ARCH}
  fi
  # For Debugging...
  echo "NATIVE_BUILD_DIR=${NATIVE_BUILD_DIR}"
  echo "INSTALL_PREFIX=${INSTALL_PREFIX}"
  echo "CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}"
  echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH}"
  echo "DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}"
  echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
  # For Debugging
  git clone https://github.com/GenomicsDB/GenomicsDB.git -b develop $NATIVE_BUILD_DIR
  pushd $NATIVE_BUILD_DIR
  mkdir build &&
    pushd build &&
    if [[ ! -z $OSX_ARCH ]]; then
      echo "OSX_ARCH=$OSX_ARCH"
      CMAKE_ARCH_ARG="-DCMAKE_OSX_ARCHITECTURES=${OSX_ARCH}"
    fi
    cmake .. $CMAKE_ARCH_ARG -DBUILD_NANOARROW=1 -DPROTOBUF_ROOT_DIR=./protobuf -DGCSSDK_ROOT_DIR=./gcssdk -DAWSSDK_ROOT_DIR=./awssdk -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX -DBUILD_EXAMPLES=False -DDISABLE_MPI=True -DDISABLE_OPENMP=True -DDISABLE_TOOLS=True -DDISABLE_EXAMPLES=True -DDISABLE_TESTING=True -DOPENSSL_USE_STATIC_LIBS=True &&
    make -j4 || rebuild && $SUDO make install &&
    popd && popd
fi
