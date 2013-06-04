import unittest
import time

from pylognorm import LogNormalizer, lib_version


class WhenUsingBindings(unittest.TestCase):

    def test_init(self):
        normalizer = LogNormalizer()

    def test_version(self):
        version = lib_version()
        self.assertIsNotNone(version)
        self.assertTrue(version != '')


if __name__ == '__main__':
    unittest.main()