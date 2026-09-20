#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift test
swift build -c release --arch arm64 --arch x86_64
binary=".build/apple/Products/Release/foldericon"
version="$("$binary" --version | awk '{print $2}')"
name="foldericon-${version}-macos-universal"
mkdir -p "dist/$name"
cp "$binary" "dist/$name/foldericon"
codesign --force --sign - "dist/$name/foldericon"
codesign --verify --strict "dist/$name/foldericon"
cp README.md CHANGELOG.md "dist/$name/"
COPYFILE_DISABLE=1 tar -czf "dist/$name.tar.gz" -C dist "$name"
(cd dist && shasum -a 256 "$name.tar.gz" > SHA256SUMS)
echo "Release artifacts: dist/$name.tar.gz and dist/SHA256SUMS"
