// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "foldericon",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "foldericon", targets: ["foldericon"])],
    targets: [
        .target(name: "FolderIconCore"),
        .executableTarget(name: "foldericon", dependencies: ["FolderIconCore"]),
        .testTarget(name: "FolderIconCoreTests", dependencies: ["FolderIconCore"])
    ]
)
