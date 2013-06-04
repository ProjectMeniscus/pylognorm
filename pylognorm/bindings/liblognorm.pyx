cimport liblognorm

from libc.string cimport strlen


cdef extern from "Python.h":
    int PyByteArray_Check(object bytearray)
    char* PyByteArray_AsString(object bytearray) except NULL
    Py_ssize_t PyByteArray_Size(object bytearray)

    int PyBytes_Check(object bytes)
    char* PyBytes_AsString(object bytes) except NULL
    Py_ssize_t PyBytes_Size(object bytes)

    object PyUnicode_FromStringAndSize(char *string, Py_ssize_t length)
    object PyString_FromStringAndSize(char *string, Py_ssize_t length)
    object PyByteArray_FromStringAndSize(char *string, Py_ssize_t length)


def lib_version():
    cdef char* version = liblognorm.ln_version()
    return PyString_FromStringAndSize(version, strlen(version))


cdef class LogNormalizer(object):

    cdef ln_ctx normalizer_ctx

    def __init__(self):
        self.normalizer_ctx = liblognorm.ln_initCtx()

    def __dealoc__(self):
        liblognorm.ln_exitCtx(self.normalizer_ctx)
