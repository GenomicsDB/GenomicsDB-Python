# GenomicsDB-Python
Experimental Python Bindings using cython to the native [GenomicsDB](https://github.com/GenomicsDB/GenomicsDB) library

To build:
```
git clone https://github.com/GenomicsDB/GenomicsDB-Python.git
cd GenomicsDB-Python
virtualenv -p python3 <env>
or
python -m venv <env>
source <env>/bin/activate > /dev/null
pip install -r requirements.txt OR pip install -r requirements_dev.txt
python setup.py build_ext --inplace --with-libs --with-genomicsdb=$GENOMICSDB_HOME
deactivate
```

To run tests:
```
cd GenomicsDB-Python
PYTHONPATH=${PYTHONPATH}:$(pwd) python3 test/test.py
```
