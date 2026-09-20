import AppKit
import XCTest
@testable import FolderIconCore

final class FolderIconTests: XCTestCase {
    func testParsing() throws {
        XCTAssertEqual(try Command.parse(["set", "one", "two", "--image", "icon.png"]),
                       .set(folders: ["one", "two"], image: "icon.png"))
        XCTAssertEqual(try Command.parse(["set", "--image", "icon.png", "--", "-folder"]),
                       .set(folders: ["-folder"], image: "icon.png"))
        XCTAssertEqual(try Command.parse(["reset", "folder with spaces"]), .reset(folders: ["folder with spaces"]))
        for invalid in [["set", "folder"], ["set", "folder", "--image"],
                        ["reset"], ["reset", "folder", "--image", "icon.png"],
                        ["set", "folder", "--color", "purple"],
                        ["set", "folder", "--image", "a", "--image", "b"]] {
            XCTAssertThrowsError(try Command.parse(invalid), "\(invalid)")
        }
    }

    func testRealFolderSetAndReset() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("Folder with spaces")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        let contents = folder.appendingPathComponent("keep.txt")
        try Data("unchanged".utf8).write(to: contents)

        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 64, pixelsHigh: 64,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let purple = NSColor(deviceRed: 0.6, green: 0.2, blue: 0.8, alpha: 1)
        for x in 0..<64 {
            for y in 0..<64 { bitmap.setColor(purple, atX: x, y: y) }
        }
        let imageURL = root.appendingPathComponent("icon.png")
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: imageURL)
        let image = try FolderIcon.loadImage(at: imageURL.path)
        try FolderIcon.apply(image, to: folder.path)
        XCTAssertTrue(try hasCustomIcon(folder))
        try FolderIcon.apply(nil, to: folder.path)
        XCTAssertFalse(try hasCustomIcon(folder))
        XCTAssertEqual(try String(contentsOf: contents, encoding: .utf8), "unchanged")
        XCTAssertThrowsError(try FolderIcon.apply(image, to: contents.path))
        XCTAssertThrowsError(try FolderIcon.apply(image, to: root.appendingPathComponent("missing").path))
        XCTAssertThrowsError(try FolderIcon.loadImage(at: contents.path))
        let link = root.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: folder)
        XCTAssertThrowsError(try FolderIcon.apply(image, to: link.path))
    }

    private func hasCustomIcon(_ url: URL) throws -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-px", "com.apple.FinderInfo", url.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        if process.terminationStatus != 0 { return false }
        let hex = String(decoding: data, as: UTF8.self).filter { !$0.isWhitespace }
        guard hex.count >= 20 else { return false }
        let start = hex.index(hex.startIndex, offsetBy: 16)
        let end = hex.index(start, offsetBy: 4)
        let flags = try XCTUnwrap(UInt16(hex[start..<end], radix: 16))
        return flags & 0x0400 != 0
    }
}
