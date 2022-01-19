#!/bin/bash

set -e

if [ -z $PYTHON_VERSION ]; then
  echo "PYTHON_VERSION not specified as a variable. Cannot continue."
  exit 1
fi

pushd $HOME
if [ ! -d GenomicsDB-Python ]; then
  echo "Could not find GenomicsDB-Python. Cannot continue"
  exit 1
fi

if [ -d /usr/local/ssl/lib ]; then
	export LD_LIBRARY_PATH="/usr/local/ssl/lib:$LD_LIBRARY_PATH"
else
	echo "/usr/local/ssl/lib not found. Cannot continue."
	exit 1
fi

echo "Packaging genomicsdb for Python Version=$PYTHON_VERSION..."

python$PYTHON_VERSION -m venv env-dist-$PYTHON_VERSION &&
  source env-dist-$PYTHON_VERSION/bin/activate &&
  echo "Installing required dependencies for $PYTHON_VERSION..." &&
  pip install --upgrade pip &&
  echo "Installing wheel..." && pip install wheel && echo "Installing wheel DONE" &&
  echo "Installing setuptools..." && pip install setuptools && echo "Installing setuptools DONE" &&
  echo "Installing setuptools-scm..." && pip install setuptools-scm && echo "Installing setuptools-scm DONE" &&
  echo "Installing numpy..." && pip install numpy && echo "Installing numpy DONE" &&
  echo "Installing cython..." && pip install cython && echo "Installing cython DONE" &&
  echo "Installing required dependencies for $PYTHON_VERSION DONE"

if [[ $? -ne 0 ]]; then
  echo "Problems installing dependencies. Cannot continue"
  exit 1
fi

cd GenomicsDB-Python &&
  python setup.py sdist --with-libs &&
	python setup.py bdist_wheel --with-libs --python-tag=cp${PYTHON_VERSION//./} &&
	echo "Packaging genomicsdb for Python Version=$PYTHON_VERSION DONE" &&
	exit 0

echo "Issues encoutered while packaging genomicsdb for Python Version=$PYTHON_VERSION. Aborting."
exit 1




