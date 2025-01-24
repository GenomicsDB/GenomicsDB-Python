.PHONY: clean clean-test clean-pyc clean-build docs help
.DEFAULT_GOAL := help

define BROWSER_PYSCRIPT
import os, webbrowser, sys

try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts
	rm -f src/genomicsdb.cc
	rm -fr genomicsdb/lib/lib*
	rm -fr genomicsdb/include/*.h
	rm -f genomicsdb/genomicsdb.cpython*so

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -fr {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

format: ## format files with black and isort
	black --line-length 120 setup.py src test genomicsdb/scripts
	isort --profile black --line-length 120 setup.py src test genomicsdb/scripts

lint: ## check style with flake8 and vulnerabilities with bandit
	bandit -r setup.py src
	flake8 --extend-ignore='E203, N803, N806, E402' --max-line-length=120 setup.py src test genomicsdb/scripts
	black --check --line-length 120 setup.py src test genomicsdb/scripts
	isort --profile black --line-length 120 -c setup.py src test genomicsdb/scripts
	cython-lint --max-line-length 120 src/*.pyx

test: FORCE ## run tests quickly with the default Python
	pytest test -s

FORCE:

docs: ## generate Sphinx HTML documentation, including API docs
	rm -f docs/genomicsdb_python.rst
	rm -f docs/modules.rst
	sphinx-apidoc -o docs/ src
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(MAKE) -C docs latex

latexpdf: docs
	$(MAKE) -C docs/_build/latex all

test-release: dist ## package and upload a test release
	twine upload --repository testpypi dist/*

release: dist ## package and upload a release
	twine upload dist/*

dist: ## builds source and wheel package
	python setup.py sdist --with-libs
	python setup.py bdist_wheel --with-libs
	package/scripts/delocate_wheel_local.sh
	ls -l dist

install: ## install the package to the active Python's site-packages
	python setup.py install --with-libs

install-dev: clean # install the package in place for debug purposes.
#	python -m pip install --upgrade pip
#	python -m pip install -r requirements_dev.txt
	python setup.py build_ext --inplace --with-libs
#       pip install -e .

install-dev-with-protobuf: # install the package in place for debug purpose. Use iff protobuf definitions have changed in GenomicsDB
	python setup.py build_ext --inplace --with-libs --with-protobuf

check:
	python -c "import genomicsdb; print(genomicsdb.version())"
	python -c "import genomicsdb.protobuf"
