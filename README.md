# pylognorm
Native Python bindings for [liblognorm](http://www.liblognorm.com/).

## C Library Requirements
[libestr](http://libestr.adiscon.com/download/)
[libee](http://www.libee.org/download/)
[liblognorm](http://www.liblognorm.com/download/)

## Building pylognorm
```bash
pip install -r tools/pip-requires
pip install -r tools/test-requires
python setup.py build_ext --inplace
nosetests
```

##That Legal Thing...

This software library is released to you under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html). See [LICENSE](https://github.com/zinic/pylognorm/blob/master/LICENSE) for more information.

