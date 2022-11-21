#!/bin/bash

PREFIX_DIR=$HOME/python
GENOMICSDB_DIR=$PREFIX_DIR/GenomicsDB
GENOMICSDB_HOME=$GENOMICSDB_DIR/release
GENOMICSDB_BRANCH=master

GENOMICSDB_PYTHON_DIR=$(readlink -f `pwd`/..)

#MACOSX_DEPLOYMENT_TARGET=11.0
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

install_openssl() {
  check_rc $(brew list openssl@1.1 &> /dev/null || brew install openssl@1.1)
  OPENSSL_ROOT_DIR=$(readlink -f /usr/local/opt/openssl@1.1)
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
  echo "Publishing package for python $PYTHON_VERSION DONE"
}

publish() {
  echo "Installing Python" &&
#  publish_package 3.7 &&
#	publish_package 3.8 &&
  publish_package 3.9
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
  install_genomicsdb &&
  publish
