This a repository of scripts and Docker related files to publish to PyPi.
TODO: Only Linux PyPi packages are supported for now. Work is ongoing to publish MacOS packages.

To create a GenomicsDB centos 6 docker image for publishing to PyPi

```bash
# Step1
# This creates a base centos 6 box with python 3.6/3.7/3.8 installed. This may be built once and cached to
# be reused again and again in Step 2
cd /path/to/GenomicsDB-Python/package
docker build -t all_python:centos6

# Step 2
# Create a genomicsdb image based on the image above. This will build and install GenomicsDB into /usr/local
# and setup GENOMICSDB_HOME env appropriately. The distributable libraries should have dependencies only on
# C runtimes, zlib and jvm.
cd /path/to/GenomicsDB-Install
docker build --build-arg os=all_python:centos6 --build-arg distributable_jar=true -t genomicsdb:all_python .

# Step 3
# Build and publish genomicsdb python images
cd /path/to/GenomicsDB-Python/package
./publish_package.sh test_release
# OR
# ./publish_package.sh release
```javascript
