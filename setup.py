#
# setup.py
#
# The MIT License (MIT)
#
# Copyright (c) 2023 dātma, inc™
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Description: setup script to build the GenomicsDB python package
#

from setuptools import setup, Extension, find_packages

import os
import shutil
import glob
import sys
import numpy

# Directory where a copy of the CPP compiled object is found.
GENOMICSDB_LOCAL_DATA_DIR = "genomicsdb"

# Specify genomicsdb install location via
#     "--with-genomicsdb=<genomicsdb_install_path>" command line arg
GENOMICSDB_INSTALL_PATH = os.getenv("GENOMICSDB_HOME", default="genomicsdb")

copy_genomicsdb_libs = False
copy_protobuf_definitions = False

args = sys.argv[:]
for arg in args:
    if arg.find("--with-genomicsdb=") == 0:
        GENOMICSDB_INSTALL_PATH = os.path.expanduser(arg.split("=")[1])
        sys.argv.remove(arg)
    if arg.find("--with-libs") == 0:
        copy_genomicsdb_libs = True
        sys.argv.remove(arg)
    if arg.find("--with-protobuf") == 0:
        copy_protobuf_definitions = True
        sys.argv.remove(arg)

print("Compiled GenomicsDB Install Path: {}".format(GENOMICSDB_INSTALL_PATH))

GENOMICSDB_INCLUDE_DIR = os.path.join(GENOMICSDB_INSTALL_PATH, "include")
GENOMICSDB_LIB_DIR = os.path.join(GENOMICSDB_INSTALL_PATH, "lib")
GENOMICSDB_PROTOBUF_DIR = os.path.join(
    GENOMICSDB_INSTALL_PATH, "genomicsdb/protobuf/python"
)

if GENOMICSDB_INSTALL_PATH == "genomicsdb":
    copy_genomicsdb_libs = False
    copy_protobuf_definitions = False

dst = os.path.join("genomicsdb/lib")
if copy_genomicsdb_libs:
    glob_paths = [
        os.path.join(GENOMICSDB_LIB_DIR, e)
        for e in ["lib*genomicsdb*.so", "lib*genomicsdb*.dylib"]
    ]
    lib_paths = []
    for paths in glob_paths:
        lib_paths.extend(glob.glob(paths))
    print("Adding the following libraries to the GenomicsDB Package :")
    print(lib_paths, sep="\n")

    for lib_path in lib_paths:
        print("Copying {0} to {1}".format(lib_path, dst))
        shutil.copy(lib_path, dst)

rpath = []
link_args = []
if sys.platform == "darwin":
    link_args = ["-Wl,-rpath," + dst]
else:
    rpath = ["$ORIGIN/" + dst]

dst = os.path.join("genomicsdb/include")
if copy_genomicsdb_libs:
    shutil.copytree(GENOMICSDB_INCLUDE_DIR, dst, dirs_exist_ok=True)

dst = os.path.join("genomicsdb/protobuf")
if copy_protobuf_definitions:
    shutil.copytree(GENOMICSDB_PROTOBUF_DIR, dst, dirs_exist_ok=True)
    for file in os.listdir(dst):
        if file.endswith(".py"):
            # Read in the file
            filename = os.path.join(dst, file)
            with open(filename, "r") as file:
                replaced_contents = file.read().replace(
                    "import genomicsdb_", "from . import genomicsdb_"
                )
            # Write out the file
            with open(filename, "w") as file:
                file.write(replaced_contents)


def run_cythonize(src):
    from Cython.Build.Dependencies import cythonize

    cythonize(src, include_path=[GENOMICSDB_INCLUDE_DIR, numpy.get_include()], force=True)
    return os.path.splitext(src)[0] + ".cpp"


genomicsdb_extension = Extension(
    "genomicsdb.genomicsdb",
    language="c++",
    include_dirs=[GENOMICSDB_INCLUDE_DIR, numpy.get_include()],
    sources=[run_cythonize("src/genomicsdb.pyx"), "src/genomicsdb_processor.cpp", "src/genomicsdb_processor_columnar.cpp"],
    libraries=["tiledbgenomicsdb"],
    library_dirs=[GENOMICSDB_LIB_DIR],
    runtime_library_dirs=rpath,
    extra_link_args=link_args,
    extra_compile_args=["-std=c++17"],
)

with open("README.md") as f:
    long_description = f.read()

setup(
    name="genomicsdb",
    description="Experimental Python Bindings for querying GenomicsDB",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="GenomicsDB.org",
    author_email="support@genomicsdb.org",
    maintainer="GenomicsDB.org",
    maintainer_email="support@genomicsdb.org",
    license="MIT",
    ext_modules=[genomicsdb_extension],
    zip_safe=False,
    setup_requires=["cython>=0.27"],
    install_requires=["numpy>=1.19.5", "pandas"],
    extras_require = {"protobuf": ["protobuf>=4.21.1"]},
    python_requires=">=3.9",
    packages=find_packages(exclude=["package", "test"]),
    keywords=["genomics", "genomicsdb", "variant", "vcf", "variant calls"],
    include_package_data=True,
    version="0.0.9.2",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Intended Audience :: Information Technology",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: MIT License",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Operating System :: POSIX :: Linux",
        "Operating System :: MacOS :: MacOS X",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
)

