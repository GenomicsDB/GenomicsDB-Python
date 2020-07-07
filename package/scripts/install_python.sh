#!/bin/bash

PYTHON_MAJOR=3
OPENSSL_VERSION=1.0.2o

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
	wget -nv https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz &&
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
	wget -nv https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz &&
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
		deactivate
	RC=$?
	rm -fr try$PYTHON_VERSION
	popd
	check_rc $RC
}

yum install -y zlib-devel bzip2-devel libffi libffi-devel wget
yum groupinstall -y "development tools"
	
install_devtoolset &&
	install_openssl &&
	install_python_version 3.6.10 && sanity_test_python 3.6 &&
	install_python_version 3.7.7  && sanity_test_python 3.7 &&
	install_python_version 3.8.3  && sanity_test_python 3.8




