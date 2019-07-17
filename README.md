# GenomicsDB-Python
Experimental Python Bindings using cython to the native [GenomicsDB](https://github.com/GenomicsDB/GenomicsDB) library

To build:
```
git clone https://github.com/nalinigans/GenomicsDB-Python.git
cd GenomicsDB-Python
virtualenv -p python3 env
source env/bin/activate > /dev/null
python setup.py build_ext --inplace --with-genomicsdb=$GENOMICSDB_HOME
deactivate
```

To run tests:
```
cd GenomicsDB-Python
PYTHONPATH=${PYTHONPATH}:$(shell pwd) python3 test/test.py
```
