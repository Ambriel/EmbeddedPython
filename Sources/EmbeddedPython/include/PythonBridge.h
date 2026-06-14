#ifndef PythonBridge_h
#define PythonBridge_h

#include <stdbool.h>

// PythonBridge is a thin C shim over the embedded CPython C API.
//
// The Python C API is exposed by the `Python.xcframework` binary target. That
// framework ships its Clang module map in a non-standard location, so the Swift
// compiler cannot import the `Python` module directly (nor through a C shim that
// re-exports it). To work around this, all CPython calls are made here in C, and
// only plain C types cross the bridge. This header therefore deliberately does
// NOT include <Python/Python.h> — keeping it Python-free is what lets Swift
// `import PythonBridge` without needing to resolve the `Python` module itself.

/// Initializes the embedded CPython interpreter using `PyConfig`.
///
/// @param pythonHome Absolute path to use as `PYTHONHOME` (the directory whose
///        `lib/python3.13` holds the standard library). On macOS this is inside
///        the embedded `Python.framework`; on iOS it is the `python` folder that
///        the app's build phase stages into the bundle. Pass NULL to fall back
///        to CPython's default path resolution.
/// @return true if the interpreter is initialized, false otherwise.
///
/// Configured to suit an app bundle: bytecode writing is disabled (the bundle is
/// read-only / code-signed) and UTF-8 mode is forced.
/// A no-op (returns true) if the interpreter is already running.
bool PythonBridge_initialize(const char *pythonHome);

/// Reports whether the embedded interpreter is currently initialized.
bool PythonBridge_isInitialized(void);

/// Executes a snippet of Python source, capturing everything it writes to
/// stdout and stderr.
///
/// @param code UTF-8 Python source to run. Must not be NULL.
/// @return A heap-allocated, NUL-terminated UTF-8 string with the captured
///         output. The caller takes ownership and must free() it. Returns NULL
///         if the interpreter is not initialized or `code` is NULL.
char *PythonBridge_run(const char *code);

/// Shuts down the embedded interpreter. A no-op if it is not running.
void PythonBridge_finalize(void);

#endif /* PythonBridge_h */
