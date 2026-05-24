import Foundation
import PythonBridge

public final class PythonEngine {

    private static var isInitialized = false

    public static func start() throws {
        guard !isInitialized else { return }

        guard let frameworkPath = Bundle.main.privateFrameworksURL?
            .appendingPathComponent("Python.framework/Versions/3.13") else {
            throw PythonError.initializationFailed
        }

        let stdlibPath = frameworkPath.appendingPathComponent("lib/python3.13")

        setenv("PYTHONHOME", frameworkPath.path, 1)
        setenv("PYTHONPATH", stdlibPath.path, 1)
        setenv("PYTHONDONTWRITEBYTECODE", "1", 1)

        Py_Initialize()

        guard Py_IsInitialized() != 0 else {
            throw PythonError.initializationFailed
        }

        isInitialized = true
    }

    public static func run(_ code: String) throws -> String {
        guard isInitialized else {
            throw PythonError.notInitialized
        }

        let captureSetup = """
import sys, io as _io
_pythonkit_buf = _io.StringIO()
_pythonkit_old_stdout = sys.stdout
_pythonkit_old_stderr = sys.stderr
sys.stdout = _pythonkit_buf
sys.stderr = _pythonkit_buf
"""
        let captureFinish = """
sys.stdout = _pythonkit_old_stdout
sys.stderr = _pythonkit_old_stderr
_pythonkit_result = _pythonkit_buf.getvalue()
"""

        PyRun_SimpleString(captureSetup)
        PyRun_SimpleString(code)
        PyRun_SimpleString(captureFinish)

        guard let main = PyImport_AddModule("__main__"),
              let dict = PyModule_GetDict(main),
              let resultObj = PyDict_GetItemString(dict, "_pythonkit_result"),
              let cStr = PyUnicode_AsUTF8(resultObj) else {
            return ""
        }

        return String(cString: cStr)
    }

    public static func stop() {
        guard isInitialized else { return }
        Py_Finalize()
        isInitialized = false
    }
}
