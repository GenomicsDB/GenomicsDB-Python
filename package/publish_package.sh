#
# publish_package.sh
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
# Description: Bash script to help with packaging and releasing to PyPi
#

#!/bin/bash

USAGE="Usage: publish_package.sh release|test-release macos|linux" 
if [ $# -ne 2 ]; then
	echo "Wrong number of arguments - $USAGE"
	exit 1
fi
if [ "$1" != "release" ] && [ "$1" != "test-release" ]; then
	echo $USAGE
	exit 1
fi
if [ "$2" != "macos" ] && [ "$2" != "linux" ]; then
  echo $USAGE
  exit 1
fi

set -e

# Move to the package directory
pushd $(dirname "$0")

pushd ../
echo "Packaging for GenomicsDB-Python "`grep version setup.py`
echo "Sleeping for 10 seconds. Ctrl-C if you want to set new version in setup.py."
sleep 10
make clean

# Build locally for MacOS, use Docker for Linux
if [[ $2 == macos && `uname` == "Darwin" ]]; then
  popd
  echo "Building packages for MacOS..."
  ./publish_package_local.sh &&
    echo "Building packages for MacOS DONE" &&
    exit 0
elif [[ $2 == macos ]]; then
  echo "Cannot build MacOS packages from a $(uname) system"
  exit 1
fi

# Copy genomicsdb artifacts created in docker image
docker create -it --name genomicsdb genomicsdb:python bash &&
  mkdir -p genomicsdb/lib &&
  docker cp -L genomicsdb:/usr/local/lib/libtiledbgenomicsdb.so genomicsdb/lib &&
  docker rm -fv genomicsdb &&
  echo "Docker copy from genomicsdb:python successful"

RC=$?
if [[ $RC != 0 ]]; then
  echo "Failure to copy of genomicsdb artifacts RC=$RC"
  exit $RC
fi

python -m pip install --upgrade pip
python -m pip install -r requirements_dev.txt
# Run setup for source distribution of genomicsdb api and binary distribution of protobuf bindings
python setup.py sdist

popd

# Use centos6 based genomicsdb:all_python Docker image to create packages for 3.9/3.10/3.11
echo "Building packages for Linux on CentOS 7..."
# docker-compose run -e PYTHON_VERSION="3.9" package
# docker-compose run -e PYTHON_VERSION="3.10" package
docker-compose run -e PYTHON_VERSION="3.11" package
echo "Building packages for Linux on CentOS 7 DONE"

pushd ../

# Repair linux wheel names
for linux_wheel in dist/*-linux_*.whl; do
  echo "Moving $linux_wheel to ${linux_wheel//-linux_/-manylinux_2_17_x86_64.manylinux2014_}"
  mv $linux_wheel ${linux_wheel//-linux_/-manylinux_2_17_x86_64.manylinux2014_}
done

popd

popd
