from __future__ import absolute_import, print_function 

from setuptools import setup, Extension, find_packages
from pkg_resources import resource_filename

import os
import shutil
import glob
import sys
import logging

PACKAGE_NAME = 'genomicsdb'
INCLUDE_PACKAGE_DATA = False

# Directory where a copy of the CPP compiled object is found.
GENOMICSDB_LOCAL_DATA_DIR = 'gdb_data'


# Specify genomicsdb install location via "--with-genomicsdb=<genomicsdb_install_path>" command line arg
GENOMICSDB_INSTALL_PATH = os.getenv('GENOMICSDB_HOME', default = '/usr/local')
args = sys.argv[:]
for arg in args:
	if arg.find('--with-genomicsdb=') == 0:
		GENOMICSDB_INSTALL_PATH = os.path.expanduser(arg.split('=')[1])
		sys.argv.remove(arg)

print('Compiled GenomicsDB Install Path: {}'.format(GENOMICSDB_INSTALL_PATH))

GENOMICSDB_INCLUDE_DIR = os.path.join(GENOMICSDB_INSTALL_PATH, "include")
GENOMICSDB_LIB_DIR = os.path.join(GENOMICSDB_INSTALL_PATH, "lib")

rpath = []
for arg in args:	
	if arg.find('--with-libs') == 0:
		dst = os.path.join(GENOMICSDB_LOCAL_DATA_DIR, 'lib')

		if os.path.isdir(dst):
			shutil.rmtree(dst)

		PACKAGE_NAME = 'genomicsdb-dist'
		INCLUDE_PACKAGE_DATA = True

		shutil.copytree(GENOMICSDB_LIB_DIR, dst)
		rpath = ['$ORIGIN/gdb_data/lib']
		sys.argv.remove(arg)

genomicsdb_extension=Extension(
	"genomicsdb",
	language="c++",
	sources=["src/genomicsdb.pyx", "src/genomicsdb_processor.cpp"],
	libraries=["tiledbgenomicsdb"],
	include_dirs=[GENOMICSDB_INCLUDE_DIR],
	library_dirs=[GENOMICSDB_LIB_DIR],
	runtime_library_dirs= rpath,
	extra_compile_args=["-std=c++11"]
)

setup(name=PACKAGE_NAME,
	description='Experimental Python Bindings to GenomicsDB',
	author='ODA Automation Inc.',
	license='MIT',
	ext_modules=[genomicsdb_extension], 
	setup_requires=['cython>=0.27'],
	install_requires=[
		'numpy>=1.7',
		'wheel>=0.30'],
	packages = find_packages(),
	keywords=['genomics', 'genomicsdb', 'variant'],
	include_package_data=INCLUDE_PACKAGE_DATA,
	version = '0.0.1.dev0',
	classifiers=[
		'Development Status :: Experimental - pre Alpha',
		'Intended Audience :: Developers',
		'Intended Audience :: Information Technology',
		'Intended Audience :: Science/Research',
		'License :: OSI Approved :: MIT License',
		'Programming Language :: Python',
		'Topic :: Software Development :: Libraries :: Python Modules',
		'Operating System :: POSIX :: Linux',
		'Operating System :: MacOS :: MacOS X',
		'Programming Language :: Python :: 3',
		'Programming Language :: Python :: 3.6',
	],
)

