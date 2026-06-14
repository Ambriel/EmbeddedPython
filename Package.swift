// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "EmbeddedPython",
    platforms: [
        .macOS(.v11),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "EmbeddedPython",
            targets: ["EmbeddedPython"]
        )
    ],
    targets: [
        // Embedded CPython 3.13 runtime + headers, as a universal xcframework.
        // Not in git — run `./setup.sh` to download and assemble it.
        .binaryTarget(
            name: "Python",
            path: "Frameworks/Python.xcframework"
        ),
        // C shim over the CPython C API. Lives in its own target because Swift
        // and C sources cannot be mixed in a single SwiftPM target, and because
        // the Python C API has to be reached from C (see PythonBridge.h for why).
        .target(
            name: "PythonBridge",
            dependencies: ["Python"],
            path: "Sources/EmbeddedPython/include",
            publicHeadersPath: "."
        ),
        // Public Swift API. Talks to CPython exclusively through PythonBridge,
        // so it never imports the `Python` module directly.
        .target(
            name: "EmbeddedPython",
            dependencies: ["PythonBridge"],
            path: "Sources/EmbeddedPython",
            exclude: ["include"],
            linkerSettings: [
                .linkedLibrary("resolv"),
                .linkedLibrary("z"),
                .linkedLibrary("util")
            ]
        )
    ]
)
