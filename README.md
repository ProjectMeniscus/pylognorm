# pylognorm
Native Python bindings for [liblognorm](http://www.liblognorm.com/).

## C Library Requirements
* [libestr](http://libestr.adiscon.com/download/) >= v0.1.5
* [libee](http://www.libee.org/download/) >= v0.4.1
* [liblognorm](http://www.liblognorm.com/download/) >= v0.3.7

## Building pylognorm
```bash
pip install -r tools/pip-requires
pip install -r tools/test-requires
python setup.py build && python setup.py build_ext --inplace
nosetests
```

## Using pylognorm

* [Pylognorm unit test](https://github.com/zinic/pylognorm/blob/master/pylognorm/tests/bindings_test.py)

##That Legal Thing...

This software library is released to you under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html). See [LICENSE](https://github.com/zinic/pylognorm/blob/master/LICENSE) for more information.

