# GenomicsDB-Python
Experimental Python Bindings using cython to the native [GenomicsDB](https://github.com/GenomicsDB/GenomicsDB) library

Clone the repository for building
```
git clone https://github.com/GenomicsDB/GenomicsDB-Python.git
cd GenomicsDB-Python
```

To build the native library with python protobuf
```
git clone https://github.com/GenomicsDB/GenomicsDB.git -b develop GenomicsDB.native
pushd GenomicsDB.native
# Set OPENSSL_ROOT_DIR, e.g. on MacOS
OPENSSL_ROOT_DIR=/usr/local/opt/openssl@1.1 cmake -S . -B build -DBUILD_FOR_PYTHON=1 -DCMAKE_INSTALL_PREFIX=install
pushd build
make && make install
popd
popd
```

To build the python bindings and run tests in-place:
```
python3 -m venv env
source env/bin/activate > /dev/null
# Point GENOMICSDB_HOME to the installed native binaries built above
python -m pip install --upgrade pip
python -m pip install -r requirements_dev.txt
GENOMICSDB_HOME=GenomicsDB.native/install make install-dev
PYTHONPATH=. python test/test.py
deactivate
```
