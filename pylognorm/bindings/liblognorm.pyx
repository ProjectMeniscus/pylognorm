cimport liblognorm

from libc.string cimport strlen


def lib_version():
    cdef char* version = liblognorm.ln_version()
    return PyString_FromStringAndSize(version, strlen(version))


cdef class LogNormalizer(object):

    cdef ln_ctx normalizer_ctx
    cdef ee_ctx cee_ctx
    cdef ee_event *event

    def __init__(self):
        self.normalizer_ctx = liblognorm.ln_initCtx()
        self.cee_ctx = liblognorm.ee_initCtx()
        self.event = liblognorm.ee_newEvent(self.cee_ctx)

    def __dealoc__(self):
        liblognorm.ee_deleteEvent(self.event)
        liblognorm.ee_exitCtx(self.cee_ctx)
        liblognorm.ln_exitCtx(self.normalizer_ctx)
