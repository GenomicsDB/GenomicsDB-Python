import unittest

import os
import shutil
import sys
import tarfile
import tempfile

import genomicsdb

class TestGenomicsDBVersion(unittest.TestCase):
    def test_version(self):
        version = genomicsdb.version()
        self.assertIsInstance(version, str)
        self.assertTrue(len(version) > 0)
        # Should contain major.minor.patch in version string
        version_components = version.split('.')
        self.assertTrue(len(version_components) == 3)
        self.assertTrue(int(version_components[0]) > 0)
        self.assertTrue(int(version_components[1]) >= 0)

if __name__ == '__main__':
    unittest.main()
