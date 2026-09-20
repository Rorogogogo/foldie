# foldericon

A small macOS CLI to apply custom images to folder icons in Finder. Written in Swift using AppKit's `NSWorkspace.setIcon`, with no third-party dependencies or background service.

## Install with npm

Requires macOS 13 or later and Node.js 18 or later. The package includes the compiled universal Swift executable for Apple Silicon and Intel; users do not need Swift, Xcode, or an install script.

```sh
npm install -g https://github.com/Rorogogogo/foldericon/releases/download/v0.1.0/rorogogogo-foldericon-0.1.0.tgz
foldericon set ~/Projects --image ~/Downloads/icon.png
foldericon reset ~/Projects
```

Or run directly:

```sh
npx --yes --package=https://github.com/Rorogogogo/foldericon/releases/download/v0.1.0/rorogogogo-foldericon-0.1.0.tgz foldericon set ~/Projects --image ~/Downloads/icon.png
```

The commands above install the npm package directly from GitHub Releases. Publication to the npm registry is pending; once published, the shorter `npm install -g @rorogogogo/foldericon` and `npx @rorogogogo/foldericon ...` commands will also work.

## Install a release

Download `foldericon-0.1.0-macos-universal.tar.gz` from this repository's GitHub Releases page. It includes Apple Silicon and Intel builds and requires macOS 13 or later.

```sh
tar -xzf foldericon-0.1.0-macos-universal.tar.gz
mkdir -p "$HOME/.local/bin"
cp foldericon-0.1.0-macos-universal/foldericon "$HOME/.local/bin/foldericon"
"$HOME/.local/bin/foldericon" --version
```

Add `export PATH="$HOME/.local/bin:$PATH"` to your `~/.zshrc` if that directory is not already on PATH. The release includes `SHA256SUMS`; verify the downloaded archive with `shasum -a 256 -c SHA256SUMS` from the directory containing both files.

The binary is ad-hoc signed, not Apple Developer ID signed or notarized. macOS may block a browser-downloaded copy; if that happens, build from source using the instructions below. The release is tested on Apple Silicon; the Intel slice is cross-compiled but has not been run on Intel hardware.

## Build from source

Requires macOS 13 or later and Swift 5.9 or later (Xcode or its Command Line Tools).

```sh
swift build -c release
.build/release/foldericon --help
```

Optionally install the binary in a directory on your PATH:

```sh
mkdir -p "$HOME/.local/bin"
cp .build/release/foldericon "$HOME/.local/bin/foldericon"
```

If needed, add `export PATH="$HOME/.local/bin:$PATH"` to your `~/.zshrc`.

## Usage

```sh
foldericon set ~/Projects --image ~/Downloads/icon.png
foldericon set ~/Projects ~/Documents --image icon.icns
foldericon set "~/My Folder" --image "./my icon.png"
foldericon reset ~/Projects
foldericon reset ~/Projects ~/Documents
```

PNG, JPEG, ICNS, and other image formats readable by AppKit work. Square transparent PNGs are a good starting point. Paths can be absolute, relative, or begin with `~`. Use `--` before folder paths that begin with a dash.

`set` replaces the current custom icon. `reset` removes it and restores the macOS default; previous custom icons are not backed up. Only the explicitly named folders are changed, without recursion. Files, symbolic links, and app bundles/packages are rejected.

The CLI processes each folder independently and reports failures to stderr while continuing with the others. Exit codes are `0` for success, `1` if any folder fails, and `2` for invalid arguments or an unreadable image. An unreadable image causes no folder changes.

You need write access to each folder. macOS may request permission for protected locations. Cloud storage, network shares, and non-Mac filesystems may handle custom icons differently; cross-device syncing is not guaranteed. Finder may take a moment to refresh the icon.

## Verify

```sh
swift test
```

Tests apply and remove a real icon on a temporary folder, verify the Finder custom-icon flag, check that folder contents stay intact, and exercise argument validation and invalid targets.

Colors, symbols, and icon packs are future additions; this version provides `set --image` and `reset`.

## Package a release

```sh
./scripts/release.sh
```

This runs tests, builds both architectures, ad-hoc signs the universal executable, and writes a tar archive and SHA-256 checksums to `dist/`. Building a universal release requires full Xcode.

For npm, run `npm test` to build, pack, install into a temporary directory, and verify real folder operations through the installed CLI and the npm exec entry point. `npm pack` builds a publishable `.tgz`; `npm publish --access public` builds and publishes the package using your authenticated npm account. Keep the version in `package.json` and the Swift CLI in sync. The npm package has no runtime dependencies and no install-time scripts.
