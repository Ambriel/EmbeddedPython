# EmbeddedPython

Embed a full **CPython 3.13** interpreter inside a macOS or iOS app and run
Python from Swift.

EmbeddedPython wraps the [BeeWare Python-Apple-support](https://github.com/beeware/Python-Apple-support)
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

For iOS, the script also keeps the Python standard library and BeeWare's
`build/` helper scripts inside the xcframework — `xcodebuild -create-xcframework`
drops them by default, but they're required to run Python on a device (see
[iOS integration](#ios-integration)).

## Usage

```swift
import EmbeddedPython

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

`PythonEngine.start()` locates the standard library differently per platform —
see the integration steps below.

## macOS integration

The standard library lives *inside* `Python.framework`, so embedding the
framework is all that's needed:

1. Add the package (or `Frameworks/Python.xcframework`) to your app target.
2. Add `Python.framework` to **Frameworks, Libraries, and Embedded Content** and
   set it to **Embed & Sign**.

`PythonEngine.start()` then finds the stdlib at
`Python.framework/Versions/3.13` via `Bundle.main.privateFrameworksURL`.

## iOS integration

iOS is more involved, and **one required step lives in your app's build, not in
this package.** An iOS `xcframework` may only contain the library binary, so the
standard library has to be copied into the app at build time — and every binary
extension module (`.so`) must be repackaged as an individual code-signed
`.framework` (iOS/App Store forbids loose `.so` files). EmbeddedPython ships
[BeeWare's](https://github.com/beeware/Python-Apple-support) `install_python`
helper inside the xcframework to do exactly that.

1. Add `Python.xcframework` to your app target and set `Python.framework` to
   **Embed & Sign**. (For iOS, adding the xcframework to the Xcode project
   directly is more reliable than pure SPM, because the build phase below needs
   a stable path to it.)

2. Add a **Run Script** build phase named e.g. *"Prepare Python"*. It must run
   **after** "Copy Bundle Resources" and **before** "Embed Frameworks" /
   signing. Point it at the xcframework and run `install_python`:

   ```sh
   set -e
   source "$PROJECT_DIR/path/to/Python.xcframework/build/utils.sh"
   install_python "path/to/Python.xcframework"
   ```

   `install_python` selects the correct slice for the build (device vs
   simulator), stages the stdlib into `<App>.app/python/lib/python3.13`, and
   converts + signs each `lib-dynload/*.so` into `<App>.app/Frameworks/*.framework`
   with your app's signing identity. If you bundle Python packages that contain
   binary modules, pass their folders too, e.g.
   `install_python "path/to/Python.xcframework" app_packages`.

3. That's it on the Swift side — `PythonEngine.start()` resolves the staged home
   at `<bundle>/python` automatically on iOS.

> **App Store note:** running Python code you *bundle* in the app is fine.
> Downloading and executing code that changes app functionality at runtime
> violates App Store Guideline 2.5.2. See the project discussion for details.

## Architecture

The package is split into three targets:

| Target         | Language | Role |
| -------------- | -------- | ---- |
| `Python`       | binary   | The CPython runtime + headers (`Python.xcframework`). |
| `PythonBridge` | C        | Thin shim that calls the CPython C API and exposes plain C functions. |
| `EmbeddedPython` | Swift  | Public API (`PythonEngine`, `PythonError`). |

Why the C shim? The `Python.xcframework` ships its Clang module map in a
non-standard location, so Swift can't `import Python` directly — and re-exporting
the `Python` module through a C shim fails the same way. `PythonBridge` sidesteps
this by making every CPython call in C and exposing **only plain C types** across
the bridge. Because its public header never includes `<Python/Python.h>`, the
Swift layer can `import PythonBridge` without needing to resolve the `Python`
module at all. See [`PythonBridge.h`](Sources/EmbeddedPython/include/PythonBridge.h)
for details.

## License

The bundled CPython and its support framework are distributed under the
[PSF License](https://docs.python.org/3/license.html).
