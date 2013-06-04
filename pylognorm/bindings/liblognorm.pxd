cdef extern from 'libestr.h':
    ctypedef unsigned int es_size_t

    ctypedef struct es_str_t:
        es_size_t lenStr
        es_size_t lenBuf

cdef extern from 'libee/libee.h':
    ctypedef struct ee_ctx:
        pass

    ctypedef struct ee_event:
        pass

cdef extern from 'liblognorm.h':
    ctypedef void* event_t

    ctypedef struct ln_ctx:
        pass

    char* ln_version()
    ln_ctx ln_initCtx()
    int ln_exitCtx(ln_ctx ctx)
    void ln_setEECtx(ln_ctx ctx, ee_ctx eectx)

    int ln_setDebugCB(ln_ctx ctx, void (*cb)(void*, char*, size_t), void *cookie)
    void ln_enableDebug(ln_ctx ctx, int i)

    int ln_loadSamples(ln_ctx ctx, char *file)
    int ln_normalizeMsg(ln_ctx ctx, char *msg, size_t lenmsg, event_t *event)
    int ln_normalize(ln_ctx ctx, es_str_t *str, ee_event **event)
