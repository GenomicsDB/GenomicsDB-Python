#!/bin/bash

USAGE="Usage: publish_package.sh release|test-release"
# TODO: create packages for MacOS
if [ $# -ne 1 ]; then
	echo "Wrong number of arguments - $USAGE"
	exit 1
fi
if [ "$1" != "release" ] && [ "$1" != "test-release" ]; then
	echo $USAGE
	exit 1
fi

pushd ../
echo "Packaging for GenomicsDB-Python "`grep version setup.py`
echo "Sleeping for 10 seconds. Ctrl-C if you want to set new version in setup.py."
sleep 10
make clean
popd

# Use centos6 based genomicsdb:all_python Docker image to create packages for 3.6/3.7/3.8
# Current dependencies are zlib and jvm. TODO: Statically link in zlib too.
docker-compose run -e PYTHON_VERSION="3.6" package
docker-compose run -e PYTHON_VERSION="3.7" package
docker-compose run -e PYTHON_VERSION="3.8" package

pushd ../
# Repair linux wheel names
for linux_wheel in dist/*-linux_*.whl; do
	mv $linux_wheel ${linux_wheel//-linux_/-manylinux1_};
done
# Publish
make $1
popd
