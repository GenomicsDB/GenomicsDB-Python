import ctypes
import os
import sys

if sys.platform == "darwin":
    ctypes.CDLL(os.path.join(os.path.dirname(os.path.abspath(__file__)), "lib/libtiledbgenomicsdb.dylib"))
else:
    ctypes.CDLL(os.path.join(os.path.dirname(os.path.abspath(__file__)), "lib/libtiledbgenomicsdb.so"))

__path__ = __import__("pkgutil").extend_path(__path__, __name__)
from .genomicsdb import *
