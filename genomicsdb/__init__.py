import ctypes
import os
import sys

if sys.platform == "darwin":
    ctypes.CDLL(os.path.join("lib", "libtiledbgenomicsdb.dylib"))
else:
    ctypes.CDLL(os.path.join("lib", "libtiledbgenomicsdb.so"))

__path__ = __import__("pkgutil").extend_path(__path__, __name__)
from .genomicsdb import *
