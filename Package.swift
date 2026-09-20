// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "foldie",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "foldie", targets: ["foldie"])],
    targets: [
        .target(name: "FolderIconCore"),
        .executableTarget(name: "foldie", dependencies: ["FolderIconCore"]),
        .testTarget(name: "FolderIconCoreTests", dependencies: ["FolderIconCore"])
    ]
)
