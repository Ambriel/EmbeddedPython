// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PythonKit",
    platforms: [
        .macOS(.v11),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "PythonKit",
            targets: ["PythonKit"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "Python",
            path: "Frameworks/Python.xcframework"
        ),
        .target(
            name: "PythonKit",
            dependencies: ["Python"],
            path: "Sources/PythonKit",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                .linkedLibrary("resolv"),
                .linkedLibrary("z"),
                .linkedLibrary("util")
            ]
        )
    ]
)
