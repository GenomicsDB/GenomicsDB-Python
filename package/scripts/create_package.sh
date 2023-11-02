#
# create_package.sh
#
# The MIT License (MIT)
#
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
# Description: Bash script to be used with docker compose for creating a python
#              package ready for publishing
#

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

source /opt/rh/devtoolset-11/enable
export LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH"


cd GenomicsDB-Python
echo "PWD=$(pwd)"
echo "Packaging genomicsdb for Python Version=$PYTHON_VERSION..."

python$PYTHON_VERSION -m venv env-dist-$PYTHON_VERSION &&
  source env-dist-$PYTHON_VERSION/bin/activate &&
  echo "Installing required dependencies for $PYTHON_VERSION..." &&
  pip install --upgrade pip &&
  pip install -r package/requirements_pkg.txt &&
  echo "Installing required dependencies for $PYTHON_VERSION DONE"

if [[ $? -ne 0 ]]; then
  echo "Problems installing dependencies. Cannot continue"
  exit 1
fi

python setup.py bdist_wheel --python-tag=cp${PYTHON_VERSION//./} &&
  echo "Packaging genomicsdb for Python Version=$PYTHON_VERSION DONE" &&
  exit 0

echo "Issues encoutered while packaging genomicsdb for Python Version=$PYTHON_VERSION. Aborting."
exit 1




