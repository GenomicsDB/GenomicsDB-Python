import os
import pytest

import genomicsdb


def test_filesystem_api(tmpdir):
    hello_file = os.path.join(tmpdir, "hello.txt")
    assert not genomicsdb.fs_utils.is_file(hello_file)
    assert genomicsdb.fs_utils.file_size(hello_file) == -1
    assert genomicsdb.fs_utils.read_file(hello_file) == ""

    text = "Hello World!"
    fh = open(hello_file, "w")
    fh.write(text)
    fh.close()

    assert genomicsdb.fs_utils.is_file(hello_file)
    assert genomicsdb.fs_utils.file_size(hello_file) == 12

    read_text = genomicsdb.fs_utils.read_file(hello_file)
    assert read_text == text
