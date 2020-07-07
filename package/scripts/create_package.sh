#!/bin/bash

set -e

if [ -z $PYTHON_VERSION ]; then
  echo "PYTHON_VERSION not specified as a variable. Cannot continue."
  exit 1
fi

pushd $HOME
if [ ! -d GenomicsDB-Python ]; then
  echo "GenomicsDB-Python repository not found. Cannot continue."
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
  pip install --upgrade pip     

cd GenomicsDB-Python &&
  pip install -r requirements.txt &&
  python setup.py sdist --with-libs &&
	python setup.py bdist_wheel --with-libs --python-tag=cp${PYTHON_VERSION//./} &&
	echo "Packaging genomicsdb for Python Version=$PYTHON_VERSION DONE" &&
	exit 0

echo "Issues encoutered while packaging genomicsdb for Python Version=$PYTHON_VERSION. Aborting."




