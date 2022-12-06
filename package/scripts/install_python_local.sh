#!/bin/bash

set -e

VERSION=${VERSION:-3.10.8}
PREFIX=${PREFIX:-/usr/local}
OPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR:-/usr/lib64}

wget -nv https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz
tar -xvzf Python-$VERSION.tgz

# Dependencies
sudo yum install -y bzip2-devel libffi libffi-devel
sudo yum install readline-devel # needed for command history from interpreter

pushd Python-$VERSION
./configure --prefix=$PREFIX --with-openssl=$OPENSSL_ROOT_DIR --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib" --enable-optimizations --disable-test-modules
make -j8
make altinstall
popd

rm -fr Python-$VERSION*
