#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$(uname -s)" != Darwin ]; then
  echo 'Package releases must be built on macOS with Xcode installed.' >&2
  exit 1
fi

swift build -c release --arch arm64 --arch x86_64
mkdir -p vendor
cp .build/apple/Products/Release/foldie vendor/foldie
chmod 755 vendor/foldie bin/foldie.cjs
codesign --force --sign - vendor/foldie
codesign --verify --strict vendor/foldie
lipo vendor/foldie -verify_arch arm64 x86_64

expected="$(node -p 'require("./package.json").version')"
actual="$(vendor/foldie --version)"
if [ "$actual" != "foldie $expected" ]; then
  echo "Version mismatch: package.json is $expected but executable reports $actual" >&2
  exit 1
fi
