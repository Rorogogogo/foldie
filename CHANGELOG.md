# Changelog

## 0.2.0 — 2026-09-20

- Rename the project, executable, and npm package to Foldie (`foldie`, `@rorogogogo/foldie`).
- Include the universal executable in the npm package for installation without Swift or Xcode.
- Add `-v` as an alias for `--version`.


## 0.1.0 — 2026-09-20

- Apply an image to one or more folder icons with `set --image`.
- Remove custom folder icons with `reset`.
- Support spaces, relative paths, and home-directory expansion.
- Report per-folder failures and provide script-friendly exit codes.
- Reject files, symbolic links, and app bundles/packages.
- Ship a universal macOS binary for Apple Silicon and Intel, requiring macOS 13 or later.

Reset restores the default icon; replaced custom icons are not backed up.
