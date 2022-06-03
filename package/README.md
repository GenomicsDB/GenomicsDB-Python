This is a repository of scripts and Docker related files to publish to PyPi.

To create a GenomicsDB centos 6 docker image for publishing to PyPi.

```bash
# Step 0 : Prerequisites
In Python3 env: pip install -r requirements-dev.txt
 
# Step1
# This creates a base centos 6 box with python 3.7/3.8/3.9 installed. This may be built once and cached to
# be reused again and again in Step 2
cd /path/to/GenomicsDB-Python/package
docker build -t all_python:centos6 . --build-arg user=$USER --build-arg user_id=`id -u` --build-arg group_id=`id -g`

# Step 2
# Create a genomicsdb image based on the image above. This will build and install GenomicsDB into /usr/local
# and setup GENOMICSDB_HOME env appropriately. The distributable libraries should have dependencies only on
# zlib.
cd /path/to/GenomicsDB/scripts
docker build --build-arg os=all_python:centos6 -t genomicsdb:all_python .

# Step 3
# Build and publish genomicsdb python images
cd /path/to/GenomicsDB-Python/package
./publish_package.sh test-release
# OR
# ./publish_package.sh release
```
