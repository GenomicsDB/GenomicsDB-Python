source /opt/rh/devtoolset-11/enable
INSTALL_PREFIX=/usr/local
export OPENSSL_ROOT_DIR=$INSTALL_PREFIX
export LD_LIBRARY_PATH=$INSTALL_PREFIX/lib64:$INSTALL_PREFIX/lib:$LD_LIBRARY_PATH
git clone https://github.com/GenomicsDB/GenomicsDB.git -b develop GenomicsDB
cd GenomicsDB
echo "Starting GenomicsDB build"
mkdir build && cd build &&
cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DBUILD_EXAMPLES=False -DDISABLE_MPI=True -DDISABLE_OPENMP=True -DUSE_HDFS=False .. &&
	make -j4 && make install
cd ../..
