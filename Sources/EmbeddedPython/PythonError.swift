import Foundation

public enum PythonError: Error, LocalizedError {
    case initializationFailed
    case executionFailed(String)
    case notInitialized

    public var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Failed to initialize the Python interpreter."
        case .executionFailed(let message):
            return "Python execution failed: \(message)"
        case .notInitialized:
            return "Python interpreter is not initialized. Call PythonEngine.start() first."
        }
    }
}
