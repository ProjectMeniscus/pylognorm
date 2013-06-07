from os import path

from liblognorm cimport *
from libc.stdlib cimport malloc, free
from libc.string cimport strlen


ctypedef enum format_kind:
    fmt_json,
    fmt_xml,
    fmt_rfc5424


def lib_version():
    cdef char* version = ln_version()
    return PyString_FromStringAndSize(version, strlen(version))


cdef char * _object_to_cstr(object obj):
    cdef char *cstr
    if PyByteArray_Check(obj):
        cstr = PyByteArray_AsString(obj)
    elif PyBytes_Check(obj):
        cstr = PyBytes_AsString(obj)
    else:
        raise Exception(
            'Unable to convert to cstr: {}'.format(type(obj)))
    return cstr


class LogNormalizer(object):

    def __init__(self):
        self.cnormalizer = CLogNormalizer()
        self.rules_loaded = False

    def load_rules(self, filename):
        if self.rules_loaded:
            raise Exception('Normalizer rules already loaded.')
        if not path.exists(filename):
            raise Exception('Unable to locate file: {}'.format(filename))
        self.cnormalizer.load_rules(filename)
        self.rules_loaded = True

    def normalize(self, logline):
        return self.cnormalizer.normalize(logline)


cdef class CEEvent(object):

    cdef ee_event *event

    cdef _set(self, ee_event *event):
        self.event = event

    def __dealoc__(self):
        ee_deleteEvent(self.event)

    def as_json(self):
        return self._format(fmt_json)

    def as_rfc5424(self):
        return self._format(fmt_rfc5424)

    def as_xml(self):
        return self._format(fmt_xml)

    def as_csv(self, object extra_data):
        cdef char *extra_data_cstr = _object_to_cstr(extra_data)
        cdef object py_str_obj = None

        try:
            py_str_obj = self._format_csv(extra_data_cstr)
        finally:
            free(extra_data_cstr)
        return py_str_obj

    cdef object _format(self, format_kind fmt):
        cdef es_str_t *es_out = NULL
        cdef char *cstr = NULL
        cdef object py_str_obj = None

        try:
            if fmt == fmt_json:
                ee_fmtEventToJSON(self.event, &es_out)
            elif fmt == fmt_xml:
                ee_fmtEventToJSON(self.event, &es_out)
            elif fmt == fmt_rfc5424:
                ee_fmtEventToJSON(self.event, &es_out)
            else:
                raise Exception('Unknown format: {}'.format(fmt))

            cstr = es_str2cstr(es_out, NULL)
            py_str_obj = PyUnicode_FromString(cstr)
        finally:
            es_deleteStr(es_out)
            free(cstr)
        return py_str_obj

    cdef object _format_csv(self, char *extra_data):
        cdef es_str_t *es_out = NULL
        cdef es_str_t *es_extra_data = NULL
        cdef char *cstr = NULL
        cdef object py_str_obj = None

        es_extra_data = es_newStrFromCStr(extra_data, strlen(extra_data))

        try:
            ee_fmtEventToCSV(self.event, &es_out, es_extra_data)
            cstr = es_str2cstr(es_out, NULL)
            py_str_obj = PyUnicode_FromString(cstr)
        finally:
            es_deleteStr(es_extra_data)
            es_deleteStr(es_out)
            free(cstr)
        return py_str_obj


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

    def load_rules(self, object filename):
        cdef char* cstr_filename

        if PyByteArray_Check(filename):
            cstr_filename = PyByteArray_AsString(filename)
        elif PyBytes_Check(filename):
            cstr_filename = PyBytes_AsString(filename)
        else:
            raise Exception(
                'Unable to convert to cstr: {}'.format(type(filename)))
        ln_loadSamples(self.normalizer_ctx, cstr_filename)

    def normalize(self, object data):
        return self._normalize(_object_to_cstr(data))

    cdef CEEvent _normalize(self, char *data):
        cdef es_str_t *in_str = es_newStrFromCStr(data, strlen(data))
        cdef ee_event *event = NULL
        cdef CEEvent event_wrapper = None

        ln_normalize(self.normalizer_ctx, in_str, &event)

        if event != NULL:
            event_wrapper = CEEvent()
            event_wrapper._set(event)
        es_deleteStr(in_str)
        return event_wrapper


