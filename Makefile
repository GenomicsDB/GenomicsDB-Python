clean:
	rm -f -r build/
	rm -f *.so
	rm -f test/*.so

clean-cpp:
	rm -f src/genomicsdb.cpp

clean-all: clean clean-cpp

.PHONY: build
build: clean
	python setup.py build_ext --inplace
	cp genomicsdb*.so test

.PHONY: tests
tests:
	echo "TBD: Unit tests"
