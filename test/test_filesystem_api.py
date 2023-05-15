import os
import pytest

import genomicsdb


def test_filesystem_api(tmpdir):
    hello_file = os.path.join(tmpdir, "hello.txt")
    assert not genomicsdb.is_file(hello_file)
    assert genomicsdb.file_size(hello_file) == -1
    assert genomicsdb.read_entire_file(hello_file) is None

    text = "Hello World!"
    fh = open(hello_file, "w")
    fh.write(text)
    fh.close()

    assert genomicsdb.is_file(hello_file)
    assert genomicsdb.file_size(hello_file) == 12

    read_text = genomicsdb.read_entire_file(hello_file)
    assert read_text == text
