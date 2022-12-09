[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![pypi](https://img.shields.io/pypi/v/genomicsdb.svg)](https://pypi.org/project/genomicsdb/) 

# GenomicsDB-Python
Experimental Python 3 Bindings to the native [GenomicsDB](https://github.com/GenomicsDB/GenomicsDB) library. Only queries are supported for now. For importing vcf files into GenomicsDB, use the command line tools - `vcf2genomicsdb` or `gatk GenomicsDBImport`.

## Installation : Only Linux and MacOS are currently supported
Install `genomicsdb` binary wheels from PyPi with pip:
```
pip install genomicsdb
```

Or explicitly from a source distribution

```
# Download the source distribution from https://pypi.org/project/genomicsdb/#files as genomicsdb.source.tar.gz
tar xvf genomicsdb.source.tar.gz
cd genomicsdb-<version>
python setup.py install
```

## Development
See [instructions](https://github.com/GenomicsDB/GenomicsDB-Python/blob/master/INSTALL.md) for local builds and running tests.
