from os import path
from liblognorm cimport *
from libc.stdlib cimport malloc, free
from libc.string cimport strlen


def lib_version():
    cdef char* version = ln_version()
    return PyString_FromStringAndSize(version, strlen(version))


cdef char * _object_to_cstr(object obj):
    cdef char *cstr_filename
    if PyByteArray_Check(obj):
        cstr_filename = PyByteArray_AsString(obj)
    elif PyBytes_Check(obj):
        cstr_filename = PyBytes_AsString(obj)
    else:
        raise Exception(
            'Unable to convert to cstr: {}'.format(type(obj)))
    return cstr_filename


class LogNormalizer(object):

    def __init__(self):
        self.cnormalizer = CLogNormalizer()
        self.rules_loaded = False

    def load_rule(self, rule):
        self.cnormalizer.load_rule(rule)

    def load_rules(self, filename):
        if self.rules_loaded:
            raise Exception('Normalizer rules already loaded.')
        if not path.exists(filename):
            raise Exception('Unable to locate file: {}'.format(filename))
        self.cnormalizer.load_rules(filename)
        self.rules_loaded = True

    def normalize(self, logline):
        return self.cnormalizer.normalize(logline, len(logline))


cdef class CLogNormalizer(object):

    cdef ln_ctx normalizer_ctx
    cdef ee_ctx cee_ctx

    def __cinit__(self):
        self.normalizer_ctx = ln_initCtx()
        self.cee_ctx = ee_initCtx()
        ln_setEECtx(self.normalizer_ctx, self.cee_ctx);

    def __init__(self):
        pass

    def __dealoc__(self):
        ee_exitCtx(self.cee_ctx)
        ln_exitCtx(self.normalizer_ctx)

    def load_rule(self, object rule):
        ln_loadSample(self.normalizer_ctx, _object_to_cstr(rule))

    def load_rules(self, object filename):
        ln_loadSamples(self.normalizer_ctx, _object_to_cstr(filename))

    def normalize(self, object data, int length):
        cdef char *normal = self._normalize(_object_to_cstr(data), length)
        if normal == NULL:
            return None
        else:
            pyobj = PyUnicode_FromString(normal)
            free(normal)
            return pyobj

    cdef char * _normalize(self, char *data, int length):
        cdef es_str_t *in_str = es_newStrFromCStr(data, length)
        cdef ee_event *event = NULL
        cdef char *formatted = NULL

        ln_normalize(self.normalizer_ctx, in_str, &event)

        if event != NULL:
            formatted = self.format_JSON(event)
            ee_deleteEvent(event)
        es_deleteStr(in_str)
        return formatted

    cdef char * format_JSON(self, ee_event *event):
        cdef es_str_t *out_str = NULL
        cdef char *cstr = NULL

        ee_fmtEventToJSON(event, &out_str)
        cstr = es_str2cstr(out_str, NULL)
        es_deleteStr(out_str)
        return cstr

