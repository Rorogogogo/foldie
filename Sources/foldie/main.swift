import AppKit
import Darwin
import FolderIconCore

let help = """
foldie — Customize folder icons in Finder

Usage:
  foldie set <folder> [<folder> ...] --image <path>
  foldie reset <folder> [<folder> ...]
  foldie --help
  foldie --version, -v

Examples:
  foldie set ~/Projects --image ~/Downloads/icon.png
  foldie set ~/Projects ~/Documents --image icon.icns
  foldie reset ~/Projects
  foldie set --image icon.png -- ./-folder

Use quotes around paths containing spaces. PNG, JPEG, and ICNS are supported.
The image replaces any existing custom icon. Reset restores the macOS default;
it does not recover a previously replaced custom icon.

Each folder is processed independently. Exit status: 0 success, 1 any folder
failed, 2 invalid arguments or unreadable image. No administrator access needed
for folders you own and can write to. macOS may request access to protected locations.
"""

func report(_ message: String) {
    FileHandle.standardError.write(Data("foldie: \(message)\n".utf8))
}

do {
    let command = try Command.parse(Array(CommandLine.arguments.dropFirst()))
    let folders: [String]
    let image: NSImage?
    switch command {
    case .help:
        print(help)
        exit(0)
    case .version:
        print("foldie 0.2.0")
        exit(0)
    case let .set(paths, imagePath):
        folders = paths
        image = try FolderIcon.loadImage(at: imagePath)
    case let .reset(paths):
        folders = paths
        image = nil
    }
    var failed = false
    for folder in folders {
        do {
            try FolderIcon.apply(image, to: folder)
            print("\(image == nil ? "Reset" : "Set") icon: \(FolderIcon.url(for: folder).path)")
        } catch {
            failed = true
            report(error.localizedDescription)
        }
    }
    exit(failed ? 1 : 0)
} catch {
    report(error.localizedDescription)
    exit(2)
}
