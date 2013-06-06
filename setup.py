# -*- coding: utf-8 -*-
try:
    from setuptools import setup, find_packages
    from setuptools.command import easy_install
except ImportError:
    from ez_setup import use_setuptools
    use_setuptools()
    from setuptools import setup, find_packages
    from setuptools.command import easy_install

try:
    from Cython.Compiler.Main import compile
    from Cython.Distutils import build_ext
    has_cython = True
except ImportError:
    has_cython = False

import os
from distutils.core import setup
from distutils.extension import Extension

C_LIBRARIES = ['estr', 'ee', 'lognorm']
COMPILER_ARGS = list()
LINKER_ARGS = list()

ENABLE_GDB = os.getenv('ENABLE_GDB')

if ENABLE_GDB and ENABLE_GDB.lower() == 'true':
    COMPILER_ARGS.append('-g')
    LINKER_ARGS.append('-g')

cmdclass = dict()
ext_modules = list()


def read(relative):
    try:
        contents = open(relative, 'r').read()
        return [l for l in contents.split('\n') if l != '']
    except Exception:
        print('Unable to read from build file: {}'.format(relative))
        return list()


def ez_install(package):
    easy_install.main(["-U", package])


def module_files(module_name, *extensions):
    found = list()
    filename_base = module_name.replace('.', '/')
    for extension in extensions:
        filename = '{}.{}'.format(filename_base, extension)
        if os.path.exists(filename):
            found.append(filename)
            break
    return found


def cythonize():
    if has_cython:
        cmdclass.update({
            'build_ext': build_ext
        })

    for module in read('./tools/cython-modules'):
        if has_cython:
            build_list = module_files(module, 'pyx', 'pyd')
            for build_target in build_list:
                compile(build_target)
        else:
            build_list = module_files(module, 'c')

        ext_modules.append(
            Extension(
                module,
                build_list,
                libraries=C_LIBRARIES,
                extra_compile_args=COMPILER_ARGS,
                extra_link_args=LINKER_ARGS))


cythonize()

setup(
    name='pylognorm',
    version='0.1.2',
    description='liblognorm python bindings',
    url='http://github.com/zinic/pylognorm',
    classifiers=[
        'Development Status :: 4 - Beta',
        'Environment :: Console',
        'Natural Language :: English',
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'Topic :: System :: Logging',
        'Programming Language :: Python',
        'Programming Language :: Cython',
        'Programming Language :: Python :: Implementation :: CPython',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3.3'
    ],
    author='John Hopper',
    author_email='john.hopper@jpserver.net',
    license='Apache 2.0',
    tests_require=read('./tools/test-requires'),
    install_requires=read('./tools/install-requires'),
    test_suite='nose.collector',
    zip_safe=False,
    include_package_data=True,
    packages=find_packages(exclude=['ez_setup']),
    cmdclass=cmdclass,
    ext_modules=ext_modules
)
