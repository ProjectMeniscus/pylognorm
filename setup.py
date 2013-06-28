# -*- coding: utf-8 -*-
import sys
import os

from setuptools import setup, find_packages
from setuptools.command import easy_install
from distutils.extension import Extension

try:
    from Cython.Compiler.Main import compile
    from Cython.Distutils import build_ext
    has_cython = True
except ImportError:
    has_cython = False


C_LIBRARIES = ['estr', 'ee', 'lognorm']
COMPILER_ARGS = list()
LINKER_ARGS = list()

ENABLE_GDB = os.getenv('ENABLE_GDB')

if ENABLE_GDB and ENABLE_GDB.lower() == 'true':
    COMPILER_ARGS.append('-g')
    LINKER_ARGS.append('-g')


def read(relative):
    contents = open(relative, 'r').read()
    return [l for l in contents.split('\n') if l != '']


def module_files(module_name, *extensions):
    found = list()
    filename_base = module_name.replace('.', '/')
    for extension in extensions:
        filename = '{}.{}'.format(filename_base, extension)
        if os.path.isfile(filename):
            found.append(filename)
    return found


def fail_build(reason, code=1):
    print(reason)
    sys.exit(code)


def cythonize():
    if not has_cython:
        fail_build('In order to build this project, cython is required.')

    for module in read('./tools/cython-modules'):
        for cython_target in module_files(module, 'pyx', 'pyd'):
            compile(cython_target)


def package_c():
    missing_modules = list()
    extensions = list()

    for module in read('./tools/cython-modules'):
        c_files = module_files(module, 'c')
        if len(c_files) > 0:
            c_ext = Extension(
                module.replace('.', os.sep),
                c_files,
                libraries=C_LIBRARIES,
                extra_compile_args=COMPILER_ARGS,
                extra_link_args=LINKER_ARGS)
            extensions.append(c_ext)
        else:
            missing_modules.append(module)

    if len(missing_modules) > 0:
        fail_build('Missing C files for modules {}'.format(missing_modules))
    return extensions

# Got tired of fighting build_ext
if 'build' in sys.argv:
    cythonize()

ext_modules = package_c()

setup(
    name='pylognorm',
    version='0.2.1',
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
    packages=find_packages(exclude=['ez_setup', '*.tests']),
    ext_modules=ext_modules
)

