from distutils.core import setup
import setuptools
from Cython.Build import cythonize
from distutils.extension import Extension  

setup(name='genomicsdb',
	description='Experimental Python Bindings to GenomicsDB',
	author='ODA Automation Inc.',
	license='MIT',
	ext_modules = cythonize([Extension("genomicsdb", 
			sources=["src/genomicsdb.pyx"], 
			libraries=["tiledbgenomicsdb"],
			library_dirs=["/home/vagrant/lib"],
			include_dirs=["/home/vagrant/include"],
			extra_compile_args=["-std=c++11"])]),
	setup_requires=['cython>=0.27'],
	install_requires=[
        	'numpy>=1.7',
        	'wheel>=0.30']
)

