import os

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

    assert not genomicsdb.workspace_exists("non-existent-ws")
    assert not genomicsdb.workspace_exists("az://non-existent-container/ws")
    assert not genomicsdb.workspace_exists("az://non-existent-container@non-existent-account.blob/ws")

    assert not genomicsdb.array_exists("non-existent-ws", "non-existent-array")
    assert not genomicsdb.array_exists("az://non-existent-container/ws", "non-existent-array")
    assert not genomicsdb.array_exists("az://non-existent-container@non-existent-account.blob/ws", "non-existent-array")
