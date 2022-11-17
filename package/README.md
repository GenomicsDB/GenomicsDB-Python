This is a repository of scripts and Docker related files to publish to PyPi.

To create a GenomicsDB centos 6 docker image for publishing to PyPi.

```bash
# Step 0 : Prerequisites
cd /path/to/GenomicsDB-Python/package
In Python3 env: python -m pip install -r requirements_pkg.txt
 
# Step1
# This creates a base centos 6 box with python 3.7/3.8/3.9 and GenomicsDB installed. This may be built once and cached to
# be reused in Step 2
docker build -t genomicsdb:python . --build-arg user=$USER --build-arg user_id=`id -u` --build-arg group_id=`id -g` --build-arg genomicsdb_branch=master

# Step 2
# Build and publish genomicsdb python images
./publish_package.sh test-release linux
# OR
# ./publish_package.sh release linux
```
