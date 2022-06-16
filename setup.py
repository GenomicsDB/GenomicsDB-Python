from setuptools import setup, Extension, find_packages

import os
import shutil
import glob
import sys

# Directory where a copy of the CPP compiled object is found.
GENOMICSDB_LOCAL_DATA_DIR = "genomicsdb"

# Specify genomicsdb install location via
#     "--with-genomicsdb=<genomicsdb_install_path>" command line arg
GENOMICSDB_INSTALL_PATH = os.getenv("GENOMICSDB_HOME", default="/usr/local")

copy_genomicsdb_libs = False
args = sys.argv[:]
for arg in args:
    if arg.find("--with-genomicsdb=") == 0:
        GENOMICSDB_INSTALL_PATH = os.path.expanduser(arg.split("=")[1])
        sys.argv.remove(arg)
    if arg.find("--with-libs") == 0:
        copy_genomicsdb_libs = True;
        sys.argv.remove(arg)

print("Compiled GenomicsDB Install Path: {}".format(GENOMICSDB_INSTALL_PATH))

GENOMICSDB_INCLUDE_DIR = os.path.join(GENOMICSDB_INSTALL_PATH, "include")
GENOMICSDB_LIB_DIR = os.path.join(GENOMICSDB_INSTALL_PATH, "lib")

dst = os.path.join("lib")
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

    if not os.path.exists(dst):
        os.makedirs(dst)
    for lib_path in lib_paths:
        print("Copying {0} to {1}".format(lib_path, dst))
        shutil.copy(lib_path, dst)

rpath = []
link_args = []
if sys.platform == "darwin":
    link_args = ["-Wl,-rpath," + dst]
else:
    rpath = ["$ORIGIN/" + dst]

def run_cythonize(src):
    from Cython.Build.Dependencies import cythonize
    cythonize(src, include_path=[GENOMICSDB_INCLUDE_DIR], force=True)
    return os.path.splitext(src)[0] + ".cpp"

genomicsdb_extension = Extension(
    "genomicsdb.genomicsdb",
    language="c++",
    include_dirs=[GENOMICSDB_INCLUDE_DIR],
    sources=[run_cythonize("src/genomicsdb.pyx"), "src/genomicsdb_processor.cpp"],
    libraries=["tiledbgenomicsdb"],
    library_dirs=[GENOMICSDB_LIB_DIR],
    runtime_library_dirs=rpath,
    extra_link_args=link_args,
    extra_compile_args=["-std=c++11"],
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
    install_requires=["numpy>=1.7"],
    python_requires=">=3.7",
    packages=find_packages(exclude=["package", "test"]),
    keywords=["genomics", "genomicsdb", "variant", "vcf", "variant calls"],
    include_package_data=True,
    version="0.0.8.10",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Intended Audience :: Information Technology",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: MIT License",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Operating System :: POSIX :: Linux",
        "Operating System :: MacOS :: MacOS X",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
    ],
)
