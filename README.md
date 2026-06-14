# PythonKit

Embed a full **CPython 3.13** interpreter inside a macOS or iOS app and run
Python from Swift.

PythonKit wraps the [BeeWare Python-Apple-support](https://github.com/beeware/Python-Apple-support)
builds in a Swift package with a small, friendly Swift API.

## Requirements

- Swift 5.9+ / Xcode 15+
- macOS 11+ or iOS 13+

## Setup

The Python runtime is a large binary `xcframework` and is **not** checked into
git. Build it locally before opening the package:

```sh
./setup.sh
```

This downloads the macOS and iOS Python 3.13 support packages and assembles a
universal `Frameworks/Python.xcframework` (macOS arm64/x86_64, iOS device, iOS
simulator). Once it completes, `swift build` and Xcode builds will work.

## Usage

```swift
import PythonKit

try PythonEngine.start()

let output = try PythonEngine.run("""
print("Hello from Python!")
print(sum(range(10)))
""")
print(output)   // "Hello from Python!\n45\n"

PythonEngine.stop()
```

- `PythonEngine.run(_:)` returns whatever the snippet writes to `stdout`/`stderr`.
- The interpreter is process-wide; `start()` / `stop()` are idempotent.

### Embedding in an app

`PythonEngine.start()` expects `Python.framework` to be embedded in the host
app (it resolves the standard library relative to
`Bundle.main.privateFrameworksURL`). Add the framework to your app target's
**Embed Frameworks** / **Frameworks, Libraries, and Embedded Content** so it
ships inside the `.app`/`.ipa`.

## Architecture

The package is split into three targets:

| Target         | Language | Role |
| -------------- | -------- | ---- |
| `Python`       | binary   | The CPython runtime + headers (`Python.xcframework`). |
| `PythonBridge` | C        | Thin shim that calls the CPython C API and exposes plain C functions. |
| `PythonKit`    | Swift    | Public API (`PythonEngine`, `PythonError`). |

Why the C shim? The `Python.xcframework` ships its Clang module map in a
non-standard location, so Swift can't `import Python` directly — and re-exporting
the `Python` module through a C shim fails the same way. `PythonBridge` sidesteps
this by making every CPython call in C and exposing **only plain C types** across
the bridge. Because its public header never includes `<Python/Python.h>`, the
Swift layer can `import PythonBridge` without needing to resolve the `Python`
module at all. See [`PythonBridge.h`](Sources/PythonKit/include/PythonBridge.h)
for details.

## License

The bundled CPython and its support framework are distributed under the
[PSF License](https://docs.python.org/3/license.html).
