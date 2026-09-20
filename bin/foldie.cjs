#!/usr/bin/env node
'use strict';

const { spawnSync } = require('node:child_process');
const path = require('node:path');

if (process.platform !== 'darwin' || !['arm64', 'x64'].includes(process.arch)) {
  console.error('foldie requires macOS 13 or later on Apple Silicon or Intel.');
  process.exit(1);
}

const result = spawnSync(path.join(__dirname, '..', 'vendor', 'foldie'), process.argv.slice(2), {
  stdio: 'inherit',
});

if (result.error) {
  console.error(`foldie: Could not launch the bundled executable: ${result.error.message}`);
  process.exit(1);
}
if (result.signal) {
  process.kill(process.pid, result.signal);
} else {
  process.exit(result.status ?? 1);
}
