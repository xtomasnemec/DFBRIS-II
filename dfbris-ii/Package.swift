// swift-tools-version: 6.1
// This is a Skip (https://skip.dev) package.
import PackageDescription

let package = Package(
    name: "dfbris-ii",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "DFBRIS2", type: .dynamic, targets: ["DFBRIS2"]),
        .executable(name: "DFBRIS2App", targets: ["DFBRIS2App"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.9.3"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "DFBRIS2", dependencies: [
            .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .executableTarget(name: "DFBRIS2App", dependencies: [
            "DFBRIS2",
            .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
        ], path: "Darwin/Sources", plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
