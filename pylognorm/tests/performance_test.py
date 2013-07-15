import unittest
import time
import simplejson as json

from pylognorm import LogNormalizer, lib_version


APACHE_LL_STR = (
    '66.69.25.244 - - [13/Jan/2013:09:57:51 -0600] "GET /wiki/skins/common/'
    'commonPrint.css?270 HTTP/1.1" 304 212 "http://nu.realityhub.com/wiki/i'
    'ndex.php/Main_Page" "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:18.0) Geck'
    'o/20100101 Firefox/18.0"'
)


def performance(duration=10, print_output=True):
    normalizer = LogNormalizer()
    normalizer.load_rules('./samples/rules.db')
    runs = 0
    then = time.time()
    while time.time() - then < duration:
        event = normalizer.normalize(APACHE_LL_STR)
        event_dict = json.loads(event.as_json())
        del(event)
        del(event_dict)
        runs += 1
    if print_output:
        print('Ran {} times in {} seconds for {} runs per second.'.format(
            runs,
            duration,
            runs / float(duration)))

if __name__ == '__main__':
    print('Executing warmup')
    performance(5, False)

    print('Executing performance test')
    performance(5)

    print('Profiling...')
    import cProfile
    cProfile.run('performance(5)')
