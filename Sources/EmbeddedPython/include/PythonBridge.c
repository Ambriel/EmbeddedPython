#include "PythonBridge.h"

#include <Python/Python.h>
#include <string.h>

bool PythonBridge_initialize(const char *pythonHome) {
    if (Py_IsInitialized()) {
        return true;
    }

    PyStatus status;

    // Pre-initialize so we can force UTF-8 mode (matches BeeWare's reference
    // iOS configuration; keeps stdout/stderr/filesystem encodings predictable).
    PyPreConfig preconfig;
    PyPreConfig_InitPythonConfig(&preconfig);
    preconfig.utf8_mode = 1;
    status = Py_PreInitialize(&preconfig);
    if (PyStatus_Exception(status)) {
        return false;
    }

    PyConfig config;
    PyConfig_InitPythonConfig(&config);
    // The app bundle is read-only / code-signed, so .pyc files can't be written
    // next to the stdlib.
    config.write_bytecode = 0;
    // Flush output promptly rather than buffering it.
    config.buffered_stdio = 0;

    if (pythonHome != NULL) {
        wchar_t *home = Py_DecodeLocale(pythonHome, NULL);
        if (home == NULL) {
            PyConfig_Clear(&config);
            return false;
        }
        status = PyConfig_SetString(&config, &config.home, home);
        PyMem_RawFree(home);
        if (PyStatus_Exception(status)) {
            PyConfig_Clear(&config);
            return false;
        }
    }

    status = Py_InitializeFromConfig(&config);
    PyConfig_Clear(&config);
    if (PyStatus_Exception(status)) {
        return false;
    }

    return Py_IsInitialized() != 0;
}

bool PythonBridge_isInitialized(void) {
    return Py_IsInitialized() != 0;
}

char *PythonBridge_run(const char *code) {
    if (code == NULL || !Py_IsInitialized()) {
        return NULL;
    }

    // Redirect stdout/stderr into an in-memory buffer so the output of `code`
    // can be handed back to the caller.
    PyRun_SimpleString(
        "import sys, io as _io\n"
        "_pythonkit_buf = _io.StringIO()\n"
        "_pythonkit_old_stdout = sys.stdout\n"
        "_pythonkit_old_stderr = sys.stderr\n"
        "sys.stdout = _pythonkit_buf\n"
        "sys.stderr = _pythonkit_buf\n");

    PyRun_SimpleString(code);

    PyRun_SimpleString(
        "sys.stdout = _pythonkit_old_stdout\n"
        "sys.stderr = _pythonkit_old_stderr\n"
        "_pythonkit_result = _pythonkit_buf.getvalue()\n");

    PyObject *mainModule = PyImport_AddModule("__main__");
    if (mainModule == NULL) {
        return NULL;
    }

    // PyModule_GetDict returns a borrowed reference; do not decref it.
    PyObject *globals = PyModule_GetDict(mainModule);
    if (globals == NULL) {
        return NULL;
    }

    PyObject *result = PyDict_GetItemString(globals, "_pythonkit_result");
    if (result == NULL) {
        return NULL;
    }

    const char *utf8 = PyUnicode_AsUTF8(result);
    if (utf8 == NULL) {
        return NULL;
    }

    // Copy onto the heap so the result outlives the interpreter's buffer; the
    // caller is responsible for free()-ing it.
    return strdup(utf8);
}

void PythonBridge_finalize(void) {
    if (Py_IsInitialized()) {
        Py_Finalize();
    }
}
