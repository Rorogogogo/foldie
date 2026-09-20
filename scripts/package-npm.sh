#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$(uname -s)" != Darwin ]; then
  echo 'Package releases must be built on macOS with Xcode installed.' >&2
  exit 1
fi

swift build -c release --arch arm64 --arch x86_64
mkdir -p vendor
cp .build/apple/Products/Release/foldericon vendor/foldericon
chmod 755 vendor/foldericon bin/foldericon.cjs
codesign --force --sign - vendor/foldericon
codesign --verify --strict vendor/foldericon
lipo vendor/foldericon -verify_arch arm64 x86_64

expected="$(node -p 'require("./package.json").version')"
actual="$(vendor/foldericon --version)"
if [ "$actual" != "foldericon $expected" ]; then
  echo "Version mismatch: package.json is $expected but executable reports $actual" >&2
  exit 1
fi
