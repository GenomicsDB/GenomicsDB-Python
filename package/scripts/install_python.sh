#!/bin/bash

# Argument parsing
PYTHON_USER=$1
PYTHON_USER_ID=$2
PYTHON_GROUP_ID=$3

PYTHON_MAJOR=3
OPENSSL_VERSION=1.1.1o

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
  ./configure --prefix=/usr/local --with-openssl=/usr/local/ssl-$OPENSSL_VERSION --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib" &&
    make &&
    make altinstall
  RC=$?
  popd
  rm -fr Python-$VERSION Python-$VERSION.tgz
  check_rc $RC
}

install_openssl() {
  pushd /tmp
  wget $WGET_NO_CERTIFICATE -nv https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz &&
    tar xzvf openssl-$OPENSSL_VERSION.tar.gz &&
    pushd openssl-$OPENSSL_VERSION
    CFLAGS=-fPIC ./config -fPIC -shared --prefix=/usr/local/ssl-$OPENSSL_VERSION &&
    make depend && make && make install
    RC=$?
    ln -s /usr/local/ssl-$OPENSSL_VERSION /usr/local/ssl
    export LD_LIBRARY_PATH=/usr/local/ssl-$OPENSSL_VERSION/lib:$LD_LIBRARY_PATH
    popd
    rm -fr openssl-$OPENSSL_VERSION*
    check_rc $RC
  popd
}

install_devtoolset() {
  echo "Installing devtoolset"
  yum install -y centos-release-scl &&
  yum install -y devtoolset-7 &&
  source /opt/rh/devtoolset-7/enable
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

install

# Workaround for Centos 6 being EOL'ed
curl https://www.getpagespeed.com/files/centos6-eol.repo --output /etc/yum.repos.d/CentOS-Base.repo
yum -y install centos-release-scl
curl https://www.getpagespeed.com/files/centos6-scl-eol.repo --output /etc/yum.repos.d/CentOS-SCLo-scl.repo
curl https://www.getpagespeed.com/files/centos6-scl-rh-eol.repo --output /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
sed -i 's/http/https/g' /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/http/https/g' /etc/yum.repos.d/CentOS-SCLo-scl.repo
sed -i 's/http/https/g' /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
WGET_NO_CERTIFICATE="--no-check-certificate"

yum install -y zlib-devel bzip2-devel libffi libffi-devel wget
yum groupinstall -y "development tools"

if [[ $PYTHON_USER_ID != 0  && $PYTHON_GROUP_ID != 0 ]]; then
  echo "groupadd -g $PYTHON_GROUP_ID genomicsdb-python"
  echo "useradd -m $PYTHON_USER -u $PYTHON_USER_ID -g $PYTHON_GROUP_ID"
  groupadd -g $PYTHON_GROUP_ID genomicsdb-python &&
  useradd -m $PYTHON_USER -u $PYTHON_USER_ID -g $PYTHON_GROUP_ID
fi

install_devtoolset &&
  install_openssl &&
  install_python_version 3.7.10  && sanity_test_python 3.7 &&
  install_python_version 3.8.11 && sanity_test_python 3.8 &&
  install_python_version 3.9.6 && sanity_test_python 3.9 &&
  echo "Python versions successfully installed"

