clean:
	rm -f -r build/
	rm -f *.so
	rm -f test/*.so
	rm -f src/genomicsdb.cpp
	rm -f src/utils.cpp

.PHONY: build
build: clean
	python3 setup.py build_ext --with-genomicsdb=$(GENOMICSDB_HOME) --inplace

.PHONY: tests
tests: build
	echo "Running tests..."
	PYTHONPATH=${PYTHONPATH}:$(shell pwd) python3 test/test.py
	echo "Running tests DONE"
