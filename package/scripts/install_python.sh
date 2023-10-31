#
# install_python.sh
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
# Description: Script to install python versions of interest
#

#!/bin/bash

# Argument parsing
PYTHON_USER=$1
PYTHON_USER_ID=$2
PYTHON_GROUP_ID=$3

PYTHON_MAJOR=3

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

install_python_version() {
  # Download and extract source
  VERSION=$1
  wget $WGET_NO_CERTIFICATE -nv https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz &&
    tar -xvzf Python-$VERSION.tgz
  check_rc $?
  pushd Python-$VERSION
  ./configure --prefix=/usr/local --with-openssl=$LD_LIBRARY_PATH --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib" &&
    make &&
    make altinstall
  echo "python version $VERSION is successful"
  python3 -m ssl
  RC=$?
  popd
  rm -fr Python-$VERSION Python-$VERSION.tgz
  check_rc $RC
}

sanity_test_python() {
  PYTHON_VERSION=$1
  pushd /tmp
  python$PYTHON_VERSION -m venv try$PYTHON_VERSION &&
    source try$PYTHON_VERSION/bin/activate &&
    pip install --upgrade pip &&
    pip install numpy &&
    pip install setuptools &&
    pip install setuptools_scm
    deactivate
  RC=$?
  rm -fr try$PYTHON_VERSION
  popd
  check_rc $RC
}

source /opt/rh/devtoolset-11/enable
export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:$LD_LIBRARY_PATH
# Workaround for Centos 6 being EOL'ed
WGET_NO_CERTIFICATE="--no-check-certificate"

yum install -y bzip2-devel libffi libffi-devel
openssl version
which openssl

if [[ $PYTHON_USER_ID != 0  && $PYTHON_GROUP_ID != 0 ]]; then
  echo "groupadd -g $PYTHON_GROUP_ID genomicsdb"
  echo "useradd -m $PYTHON_USER -u $PYTHON_USER_ID -g $PYTHON_GROUP_ID"
  groupadd -g $PYTHON_GROUP_ID genomicsdb &&
  useradd -m $PYTHON_USER -u $PYTHON_USER_ID -g $PYTHON_GROUP_ID
fi

install_python_version 3.9.6 && sanity_test_python 3.9 &&
install_python_version 3.10.8 && sanity_test_python 3.10 &&
install_python_version 3.11.4  && sanity_test_python 3.11 &&
echo "Python versions successfully installed"


