#!/bin/bash

USAGE="Usage: publish_package.sh release|test-release"
if [ $# -ne 1 ]; then
	echo "Wrong number of arguments - $USAGE"
	exit 1
fi
if [ "$1" != "release" ] && [ "$1" != "test-release" ]; then
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
if [[ `uname` == "Darwin" ]]; then
  echo "Building packages for MacOS..."
  ./publish_package_local.sh &&
    echo "Building packages for MacOS DONE"
else
  echo "Cannot build MacOS packages from this system"
fi

# Copy genomicsdb artifacts created in docker image
docker create -it --name genomicsdb genomicsdb:python bash &&
docker cp genomicsdb:/usr/local/genomicsdb/protobuf/python/ genomicsdb/protobuf &&
mv genomicsdb/protobuf/python/* genomicsdb/protobuf &&
rmdir genomicsdb/protobuf/python &&
docker cp genomicsdb:/usr/local/lib/libtiledbgenomicsdb.so genomicsdb/lib &&
docker rm -fv genomicsdb &&
sed -i 's/import genomicsdb_/from . import genomicsdb_/g' genomicsdb/protobuf/*.py &&
echo "Docker copy from genomicsdb:python successful"

# Run setup for source distribution of genomicsdb api and binary distribution of protobuf bindings
python setup.py sdist

popd

# Use centos6 based genomicsdb:all_python Docker image to create packages for 3.6/3.7/3.8
# Current dependencies are zlib and jvm. TODO: Statically link in zlib too.
echo "Building packages for Linux on CentOS 6..."
export CURRENT_UID="$(id -u):$(id -g)"
docker-compose run -e PYTHON_VERSION="3.7" package
docker-compose run -e PYTHON_VERSION="3.8" package
docker-compose run -e PYTHON_VERSION="3.9" package
echo "Building packages for Linux on CentOS 6 DONE"

pushd ../

# Repair linux wheel names
for linux_wheel in dist/*-linux_*.whl; do
    mv $linux_wheel ${linux_wheel//-linux_/-manylinux1_};
done

# Publish
make $1

popd

popd
