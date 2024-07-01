#
# delocate_wheel_local.sh
#
# The MIT License (MIT)
# Copyright (c) 2024 dātma, inc™
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
# Description: Script to delocate wheel by sanitizing native library paths
#

#!/bin/bash

if [[ $(uname) == "Linux" ]]; then
  exit 0
fi

pushd dist

mkdir genomicsdb
for WHEEL in $(ls *.whl)
do
  echo "delocating WHEEL=$WHEEL"
  VERSION=$(echo $WHEEL | grep -o cp... | head -n1 | cut -c 3-5)
  LIB=genomicsdb.cpython-$VERSION-darwin.so
  CYTHON_LIB=genomicsdb/$LIB
  rm -fr $CYTHON_LIB
  unzip -j $WHEEL $CYTHON_LIB > /dev/null
  mv $LIB genomicsdb
  ls $CYTHON_LIB > /dev/null
  if [[ $? != 0 ]]; then
    echo "Could not find CYTHON_LIB=$CYTHON_LIB"
    exit 1
  fi
  install_name_tool -change @rpath/libtiledbgenomicsdb.1.dylib @loader_path/lib/libtiledbgenomicsdb.1.dylib $CYTHON_LIB
  otool -L $CYTHON_LIB
  zip $WHEEL $CYTHON_LIB
done
rm -fr genomicsdb

popd
