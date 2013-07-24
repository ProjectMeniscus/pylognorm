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


cdef char * _pystr_to_cstr(object obj) except NULL:
    target = obj
    # This was a pain in the ass to do in c however this may
    # not be completely correct either
    if isinstance(obj, unicode):
        target = obj.encode('UTF-8')
    return _object_to_cstr(target)


cdef char * _object_to_cstr(object obj) except NULL:
    cdef char *cstr = NULL
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

    def load_rule(self, rule):
        self.cnormalizer.load_rule(rule)

    def load_rules(self, filename):
        if not path.exists(filename):
            raise Exception(
                'Unable to locate rules file: {}'.format(filename))
        self.cnormalizer.load_rules(filename)

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
        return self._format_csv(_pystr_to_cstr(extra_data))

    cdef object _format(self, format_kind fmt):
        cdef es_str_t *es_out = NULL
        cdef char *cstr = NULL
        cdef object py_str_obj = None

        try:
            if fmt == fmt_json:
                ee_fmtEventToJSON(self.event, &es_out)
            elif fmt == fmt_xml:
                ee_fmtEventToXML(self.event, &es_out)
            elif fmt == fmt_rfc5424:
                ee_fmtEventToRFC5424(self.event, &es_out)
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

    def __dealoc__(self):
        ee_exitCtx(self.cee_ctx)
        ln_exitCtx(self.normalizer_ctx)

    def load_rule(self, object rule_str):
        ln_loadSample(self.normalizer_ctx, _pystr_to_cstr(rule_str))

    def load_rules(self, object filename):
        ln_loadSamples(self.normalizer_ctx, _pystr_to_cstr(filename))

    def normalize(self, object data):
        return self._normalize(_pystr_to_cstr(data))

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


