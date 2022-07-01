# The MIT License (MIT)
# Copyright (c) 2022 Omics Data Automation, Inc.
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

#!/bin/bash

USER=$1
BRANCH=$2

set -e

. /etc/profile

INSTALL_PREFIX=/usr/local
OPENSSL_VERSION=1.1.1o
CURL_VERSION=7.83.1

WGET_NO_CERTIFICATE=" --no-check-certificate"
OPENSSL_PREFIX=$INSTALL_PREFIX/ssl
install_openssl() {
  if [[ ! -d $OPENSSL_PREFIX ]]; then
    echo "Installing OpenSSL"
    pushd /tmp
    wget $WGET_NO_CERTIFICATE -nv https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz &&
      tar -xvzf openssl-$OPENSSL_VERSION.tar.gz &&
      cd openssl-$OPENSSL_VERSION &&
      if [[ `uname` == "Linux" ]]; then
	  CFLAGS=-fPIC ./config shared --prefix=$OPENSSL_PREFIX --openssldir=$OPENSSL_PREFIX
      else
	  ./Configure darwin64-x86_64-cc shared -fPIC --prefix=$OPENSSL_PREFIX
      fi
      make && make install && echo "Installing OpenSSL DONE"
    rm -fr /tmp/openssl*
    popd
  fi
}

CURL_PREFIX=$INSTALL_PREFIX
install_curl() {
  if [[ `uname` == "Darwin" ]]; then
    # curl is supported natively in macOS
    return 0
  fi
  if [[ ! -f $CURL_PREFIX/libcurl.a ]]; then
    echo "Installing CURL into $CURL_PREFIX"
    pushd /tmp
    CURL_VERSION_=$(echo $CURL_VERSION | sed -r 's/\./_/g')
    wget -nv https://github.com/curl/curl/releases/download/curl-$CURL_VERSION_/curl-$CURL_VERSION.tar.gz &&
    tar xzf curl-$CURL_VERSION.tar.gz &&
    cd curl-$CURL_VERSION &&
      ./configure --with-pic -without-zstd --with-ssl=$OPENSSL_PREFIX --prefix $CURL_PREFIX &&
      make && make install && echo "Installing CURL DONE"
    rm -fr /tmp/curl
    popd
  fi
}

echo "Cleanup existing static libraries"
rm -fr $INSTALL_PREFIX/lib/libcurl*
rm -fr $INSTALL_PREFIX/lib/libuuid*
rm -fr $INSTALL_PREFIX/include/curl
rm -fr $INSTALL_PREFIX/include/uuid
rm -fr $INSTALL_PREFIX/ssl

echo "Rebuilding openssl for shared libraries"
install_openssl
echo "Rebuilding curl for shared libraries"
install_curl

echo "git clone https://github.com/GenomicsDB/GenomicsDB.git --recursive -b $BRANCH GenomicsDB"
git clone https://github.com/GenomicsDB/GenomicsDB.git --recursive -b $BRANCH GenomicsDB

pushd GenomicsDB
echo "Starting GenomicsDB build"
DOCKER_BUILD=true ./scripts/install_genomicsdb.sh $USER /usr/local true python false
popd

echo "GenomicsDB for Python installed successfully"
