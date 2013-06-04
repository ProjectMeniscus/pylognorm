cdef extern from "Python.h":
    int PyByteArray_Check(object bytearray)
    char * PyByteArray_AsString(object bytearray) except NULL
    Py_ssize_t PyByteArray_Size(object bytearray)

    int PyBytes_Check(object bytes)
    char * PyBytes_AsString(object bytes) except NULL
    Py_ssize_t PyBytes_Size(object bytes)

    object PyUnicode_FromStringAndSize(char *string, Py_ssize_t length)
    object PyString_FromStringAndSize(char *string, Py_ssize_t length)
    object PyByteArray_FromStringAndSize(char *string, Py_ssize_t length)


cdef extern from 'libestr.h':
    ctypedef unsigned int es_size_t

    ctypedef struct es_str_t:
        es_size_t lenStr
        es_size_t lenBuf


cdef extern from 'libee/libee.h':
    ctypedef struct ee_ctx:
        pass

    ctypedef struct ee_fieldbucket:
        pass

    ctypedef struct ee_tagbucket:
        pass

    cdef struct ee_event:
        pass

    ee_ctx ee_initCtx()
    int ee_exitCtx(ee_ctx ctx)

    ee_event* ee_newEvent(ee_ctx ctx)
    void ee_deleteEvent(ee_event *event)
    int ee_fmtEventToJSON(ee_event *event, es_str_t **str)


cdef extern from 'liblognorm.h':
    ctypedef void* event_t

    ctypedef struct ln_ctx:
        pass

    char * ln_version()
    ln_ctx ln_initCtx()
    int ln_exitCtx(ln_ctx ctx)
    void ln_setEECtx(ln_ctx ctx, ee_ctx eectx)

    int ln_setDebugCB(ln_ctx ctx,
        void (*cb)(void*, char*, size_t), void *cookie)
    void ln_enableDebug(ln_ctx ctx, int i)

    int ln_loadSamples(ln_ctx ctx, char *file)
    int ln_normalizeMsg(ln_ctx ctx,
        char *msg, size_t lenmsg, event_t *event)
    int ln_normalize(ln_ctx ctx, es_str_t *str, ee_event **event)
