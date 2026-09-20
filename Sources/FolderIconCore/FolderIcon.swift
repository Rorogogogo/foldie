import AppKit
import Foundation

public struct CLIError: LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

public enum Command: Equatable {
    case help
    case version
    case set(folders: [String], image: String)
    case reset(folders: [String])

    public static func parse(_ arguments: [String]) throws -> Command {
        guard let verb = arguments.first else { return .help }
        if arguments == ["--help"] || arguments == ["-h"] { return .help }
        if arguments == ["--version"] { return .version }
        guard verb == "set" || verb == "reset" else {
            throw CLIError("Unknown command '\(verb)'. Use 'foldericon --help'.")
        }
        var folders: [String] = []
        var image: String?
        var literal = false
        var index = 1
        while index < arguments.count {
            let argument = arguments[index]
            if literal {
                folders.append(argument)
            } else if argument == "--" {
                literal = true
            } else if argument == "--help" || argument == "-h" {
                return .help
            } else if argument == "--image" {
                guard verb == "set" else { throw CLIError("'reset' does not accept --image.") }
                guard image == nil else { throw CLIError("Specify --image only once.") }
                index += 1
                guard index < arguments.count, !arguments[index].hasPrefix("--") else {
                    throw CLIError("--image requires an image path.")
                }
                image = arguments[index]
            } else if argument.hasPrefix("-") {
                throw CLIError("Unknown option '\(argument)'. Use -- before folder names beginning with '-'.")
            } else {
                folders.append(argument)
            }
            index += 1
        }
        guard !folders.isEmpty else { throw CLIError("Specify at least one folder.") }
        if verb == "reset" { return .reset(folders: folders) }
        guard let image, !image.isEmpty else { throw CLIError("'set' requires --image <path>.") }
        return .set(folders: folders, image: image)
    }
}

public enum FolderIcon {
    public static func url(for path: String) -> URL {
        URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL
    }

    public static func loadImage(at path: String) throws -> NSImage {
        let imageURL = url(for: path)
        guard let image = NSImage(contentsOf: imageURL), image.isValid,
              image.size.width > 0, image.size.height > 0 else {
            throw CLIError("Cannot read image '\(imageURL.path)'. Use a supported image such as PNG, JPEG, or ICNS.")
        }
        return image
    }

    /// A nil image removes the custom icon and restores the macOS default.
    public static func apply(_ image: NSImage?, to path: String) throws {
        let folderURL = url(for: path)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory) else {
            throw CLIError("Folder does not exist: \(folderURL.path)")
        }
        guard isDirectory.boolValue else { throw CLIError("Not a folder: \(folderURL.path)") }
        let values = try folderURL.resourceValues(forKeys: [.isSymbolicLinkKey, .isPackageKey])
        guard values.isSymbolicLink != true else {
            throw CLIError("Symbolic links are not supported. Select the actual folder: \(folderURL.path)")
        }
        guard values.isPackage != true else {
            throw CLIError("App bundles and packages are not supported: \(folderURL.path)")
        }
        guard FileManager.default.isWritableFile(atPath: folderURL.path) else {
            throw CLIError("Folder is not writable: \(folderURL.path)")
        }
        guard NSWorkspace.shared.setIcon(image, forFile: folderURL.path, options: []) else {
            throw CLIError("macOS could not update the icon: \(folderURL.path). Check folder permissions and filesystem support.")
        }
    }
}
