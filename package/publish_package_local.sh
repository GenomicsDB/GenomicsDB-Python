#!/bin/bash

PREFIX_DIR=$HOME/python

ZLIB_VERSION=1.2.11
ZLIB_PREFIX_DIR=$PREFIX_DIR/zlib-$ZLIB_VERSION

GENOMICSDB_DIR=$PREFIX_DIR/GenomicsDB
GENOMICSDB_HOME=$GENOMICSDB_DIR/release
GENOMICSDB_BRANCH=develop

GENOMICSDB_PYTHON_DIR=`pwd`/..

#MACOSX_DEPLOYMENT_TARGET=11.0

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

install_openssl() {
  brew list openssl@1.1 &> /dev/null || brew install openssl@1.1
  check_rc $?
  OPENSSL_ROOT_DIR=$(readlink -f /usr/local/opt/openssl@1.1)
}

install_zlib() {
  if [[ -d $ZLIB_PREFIX_DIR ]]; then
    return 0
  fi
  pushd /tmp
  wget http://zlib.net/fossils/zlib-$ZLIB_VERSION.tar.gz &&
    tar -xvzf zlib-$ZLIB_VERSION.tar.gz &&
    pushd zlib-$ZLIB_VERSION &&
    ./configure --prefix=$ZLIB_PREFIX_DIR &&
    make && make install
  RC=$?
  popd 
  rm zlib-1.2.11*
  popd
  check_rc $RC
}

install_python_version() {
  case $1 in
    3.7*)
      PYTHON_EXECUTABLE=$PREFIX_DIR/bin/python3.7
      ;;
    3.8*)
      PYTHON_EXECUTABLE=$PREFIX_DIR/bin/python3.8
      ;;
    3.9*)
      PYTHON_EXECUTABLE=$PREFIX_DIR/bin/python3.9
      ;;
    *)
      echo "Unsupported Python Version $1"
      exit 1
      ;;
  esac
  
  if [[ -f $PYTHON_EXECUTABLE ]]; then
    return 0
  fi
  
	# Download and extract source
	VERSION=$1
  pushd /tmp
	wget -nv https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz &&
		tar -xvzf Python-$VERSION.tgz &&
	  pushd Python-$VERSION &&
    CPPFLAGS="-I$OPENSSL_PREFIX_DIR/include -I$ZLIB_PREFIX_DIR/include" LDFLAGS="-L$OPENSSL_PREFIX_DIR/lib -L$ZLIB_PREFIX_DIR/lib" ./configure --prefix=$PREFIX_DIR --enable-shared --with-openssl=$OPENSSL_PREFIX_DIR &&
		make &&
		make altinstall
	RC=$?
	popd
	rm -fr Python-$VERSION Python-$VERSION.tgz
  popd
	check_rc $RC
}

publish_package() {
	PYTHON_VERSION=$1
  echo "Publishing python package for $1 ..."
  pushd /tmp
	$PREFIX_DIR/bin/python$PYTHON_VERSION -m venv try$PYTHON_VERSION &&
		source try$PYTHON_VERSION/bin/activate &&
		pip install --upgrade pip &&
    pushd $GENOMICSDB_PYTHON_DIR &&
	  pip install -r requirements.txt &&
    cp $GENOMICSDB_HOME/genomicsdb/protobuf/python/* genomicsdb/protobuf &&
    sed -i '' 's/import genomicsdb_/from . import genomicsdb_/g' genomicsdb/protobuf/*.py &&  
    python setup.py sdist --with-genomicsdb=$GENOMICSDB_HOME &&
	  python setup.py bdist_wheel --with-genomicsdb=$GENOMICSDB_HOME --with-libs &&
    popd &&
		deactivate
	RC=$?
	rm -fr try$PYTHON_VERSION
  popd
	check_rc $RC
  echo "Publishing package DONE"
}

publish() {
  echo "Installing Python" &&
    install_python_version 3.7.10  && publish_package 3.7 &&
	  install_python_version 3.8.11  && publish_package 3.8 &&
    install_python_version 3.9.6 && publish_package 3.9
}

install_genomicsdb() {
  rm -fr $GENOMICSDB_DIR
  git clone https://github.com/GenomicsDB/GenomicsDB.git -b $GENOMICSDB_BRANCH $GENOMICSDB_DIR
  pushd $GENOMICSDB_DIR
  mkdir build
  cd build
  cmake -DCMAKE_INSTALL_PREFIX=$GENOMICSDB_HOME -DCMAKE_PREFIX_PATH=$OPENSSL_ROOT_DIR -DBUILD_EXAMPLES=False -DDISABLE_MPI=True -DBUILD_DISTRIBUTABLE_LIBRARY=1 -DBUILD_FOR_PYTHON=1 .. &&
    make -j4 && make install
}

if [[ `uname` != "Darwin" ]]; then
  echo "Script needs porting for Non-MacOS systems"
  exit 1
fi

install_openssl &&
  install_zlib &&
  install_genomicsdb &&
  publish
