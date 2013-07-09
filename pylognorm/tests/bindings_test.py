import unittest
import time
import json

from pylognorm import LogNormalizer, lib_version


APACHE_LL = (
    '66.69.25.244 - - [13/Jan/2013:09:57:51 -0600] "GET /wiki/skins/common/'
    'commonPrint.css?270 HTTP/1.1" 304 212 "http://nu.realityhub.com/wiki/i'
    'ndex.php/Main_Page" "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:18.0) Geck'
    'o/20100101 Firefox/18.0"'
)

APACHE_RULE = (
    'rule=:%remote_host:ipv4% %a:word% %b:word% [%timestamp:char'
    '-to:]%] "%method:word% %uri:word% %http_version:char-to:"%" %status_co'
    'de:word% %bytes:word% %url:quoted-string% %user_agent:quoted-string%'
)


class WhenUsingBindings(unittest.TestCase):

    def test_init(self):
        normalizer = LogNormalizer()

    def test_version(self):
        version = lib_version()
        self.assertIsNotNone(version)
        self.assertTrue(version != '')

    def test_loading_single_rules(self):
        normalizer = LogNormalizer()
        normalizer.load_rule(APACHE_RULE)
        event = normalizer.normalize(APACHE_LL)

        expected = {
            'user_agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64;'
                          ' rv:18.0) Gecko/20100101 Firefox/18.0',
            'url': 'http://nu.realityhub.com/wiki/index.php/Main_Page',
            'bytes': '212',
            'status_code': '304',
            'http_version': 'HTTP/1.1',
            'uri': '/wiki/skins/common/commonPrint.css?270',
            'method': 'GET',
            'timestamp': '13/Jan/2013:09:57:51 -0600',
            'b': '-',
            'a': '-',
            'remote_host': '66.69.25.244'
        }

        self.assertEqual(expected, json.loads(event.as_json()))

    def test_loading_rules(self):
        normalizer = LogNormalizer()
        normalizer.load_rules('./samples/rules.db')

    def test_normalizing(self):
        normalizer = LogNormalizer()
        normalizer.load_rules('./samples/rules.db')
        event = normalizer.normalize(APACHE_LL)

        expected = {
            'user_agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64;'
                          ' rv:18.0) Gecko/20100101 Firefox/18.0',
            'url': 'http://nu.realityhub.com/wiki/index.php/Main_Page',
            'bytes': '212',
            'status_code': '304',
            'http_version': 'HTTP/1.1',
            'uri': '/wiki/skins/common/commonPrint.css?270',
            'method': 'GET',
            'timestamp': '13/Jan/2013:09:57:51 -0600',
            'b': '-',
            'a': '-',
            'remote_host': '66.69.25.244'
        }

        self.assertEqual(expected, json.loads(event.as_json()))

if __name__ == '__main__':
    unittest.main()
