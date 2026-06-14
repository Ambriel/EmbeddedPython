import Foundation
import PythonBridge

/// A minimal Swift front-end for an embedded CPython 3.13 interpreter.
///
/// `PythonEngine` owns a single process-wide interpreter. Call ``start()`` once
/// before running code, ``run(_:)`` to execute snippets, and ``stop()`` to tear
/// the interpreter down. All CPython calls are funneled through the C
/// `PythonBridge` shim; this type only manages lifecycle and environment setup.
public final class PythonEngine {

    private static var isInitialized = false

    /// Boots the embedded interpreter.
    ///
    /// Resolves the Python home for the current platform, then initializes
    /// CPython. Subsequent calls are no-ops.
    ///
    /// - Throws: ``PythonError/initializationFailed`` if the standard library
    ///   cannot be located or the interpreter fails to start.
    public static func start() throws {
        guard !isInitialized else { return }

        let home = try pythonHome()

        guard PythonBridge_initialize(home) else {
            throw PythonError.initializationFailed
        }

        isInitialized = true
    }

    /// Locates `PYTHONHOME` for the running platform.
    ///
    /// - macOS: the standard library ships *inside* the embedded
    ///   `Python.framework`, so home is `Python.framework/Versions/3.13`.
    /// - iOS (and other embedded Apple platforms): the app's "Prepare Python"
    ///   build phase stages the standard library into `<bundle>/python`
    ///   (see the README for the required build phase).
    private static func pythonHome() throws -> String {
        #if os(macOS)
        guard let home = Bundle.main.privateFrameworksURL?
            .appendingPathComponent("Python.framework/Versions/3.13") else {
            throw PythonError.initializationFailed
        }
        return home.path
        #else
        guard let resourceURL = Bundle.main.resourceURL else {
            throw PythonError.initializationFailed
        }
        return resourceURL.appendingPathComponent("python").path
        #endif
    }

    /// Executes Python source and returns whatever it printed to stdout/stderr.
    ///
    /// - Parameter code: Python source to run.
    /// - Returns: The captured stdout + stderr output, or an empty string if the
    ///   snippet produced none.
    /// - Throws: ``PythonError/notInitialized`` if ``start()`` has not been called.
    public static func run(_ code: String) throws -> String {
        guard isInitialized else {
            throw PythonError.notInitialized
        }

        guard let cResult = PythonBridge_run(code) else {
            return ""
        }
        defer { free(cResult) }

        return String(cString: cResult)
    }

    /// Shuts the interpreter down. Safe to call when it is not running.
    public static func stop() {
        guard isInitialized else { return }
        PythonBridge_finalize()
        isInitialized = false
    }
}
