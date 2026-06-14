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
        // Too large for git (~246 MB); distributed as a GitHub release asset.
        // Run `./setup.sh` to rebuild it locally; see README for re-releasing.
        .binaryTarget(
            name: "Python",
            url: "https://github.com/Ambriel/EmbeddedPython/releases/download/v1.0.0/Python.xcframework.zip",
            checksum: "1157294a1565f51f5446c2f8dcee25a36b931ed549df7ae2a1a2e109d7c65f41"
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
