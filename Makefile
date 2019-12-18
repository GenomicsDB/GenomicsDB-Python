all: build

clean:
	rm -f -r build/
	rm -f *.so
	rm -f test/*.so
	rm -f src/genomicsdb.cpp
	rm -f src/utils.cpp

build:  $(wildcard src/*pxd) $(wildcard src/*pyx) $(wildcard src/*pxi) $(widcard src/genomicsdb_processor*)
	python3 setup.py build_ext --with-genomicsdb=$(GENOMICSDB_HOME) --inplace

rebuild: clean build

.PHONY: test
test: build
	echo "Running tests..."
	PYTHONPATH=${PYTHONPATH}:$(shell pwd) python3 test/test.py
	echo "Running tests DONE"
