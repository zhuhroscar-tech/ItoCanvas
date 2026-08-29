// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ItoCanvas",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ItoCanvasCore", targets: ["ItoCanvasCore"]),
        .executable(name: "ItoCanvas", targets: ["ItoCanvas"])
    ],
    targets: [
        .target(name: "ItoCanvasCore"),
        .executableTarget(name: "ItoCanvas", dependencies: ["ItoCanvasCore"]),
        .testTarget(name: "ItoCanvasCoreTests", dependencies: ["ItoCanvasCore"]),
        .testTarget(name: "ItoCanvasAppTests", dependencies: ["ItoCanvas"])
    ]
)
