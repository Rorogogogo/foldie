'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

test('packed npm release installs offline and forwards arguments and exit codes', {
  skip: process.platform !== 'darwin',
}, () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'foldie-npm-'));
  const project = path.resolve(__dirname, '..');
  const invoke = (command, args, expected = 0, cwd = root) => {
    const result = spawnSync(command, args, { cwd, encoding: 'utf8' });
    assert.ifError(result.error);
    assert.equal(result.status, expected, `${command}: ${result.stdout}\n${result.stderr}`);
    return result;
  };
  const hasIcon = folder => {
    const result = spawnSync('/usr/bin/xattr', ['-px', 'com.apple.FinderInfo', folder], { encoding: 'utf8' });
    if (result.status !== 0) return false;
    const bytes = Buffer.from(result.stdout.replace(/\s/g, ''), 'hex');
    return Boolean(bytes.readUInt16BE(8) & 0x0400);
  };
  try {
    invoke('npm', ['pack', '--pack-destination', root], 0, project);
    const archive = path.join(root, fs.readdirSync(root).find(name => name.endsWith('.tgz')));
    const listing = invoke('tar', ['-tzf', archive]).stdout;
    assert.match(listing, /package\/vendor\/foldie/);
    assert.doesNotMatch(listing, /package\/(?:Sources|Tests|scripts|\.build|tests)\//);
    const prefix = path.join(root, 'install with spaces');
    invoke('npm', ['install', '--global', '--prefix', prefix, '--offline', '--ignore-scripts', '--no-audit', '--no-fund', archive]);
    const cli = path.join(prefix, 'bin', 'foldie');
    const version = require('../package.json').version;
    assert.equal(invoke(cli, ['--version']).stdout.trim(), `foldie ${version}`);
    assert.equal(invoke(cli, ['-v']).stdout.trim(), `foldie ${version}`);
    assert.match(invoke(cli, ['--help']).stdout, /Usage:/);
    const folder = path.join(root, 'Folder with spaces');
    fs.mkdirSync(folder);
    const untouched = path.join(folder, 'keep.txt');
    fs.writeFileSync(untouched, 'unchanged');
    const image = path.join(root, 'image with spaces.png');
    fs.writeFileSync(image, Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=', 'base64'));
    invoke(cli, ['set', folder, '--image', image]);
    assert.ok(hasIcon(folder));
    invoke(cli, ['reset', folder]);
    assert.ok(!hasIcon(folder));
    invoke(cli, ['set', path.join(root, 'missing'), folder, '--image', image], 1);
    assert.ok(hasIcon(folder));
    invoke(cli, ['reset', folder]);
    invoke(cli, ['set', folder], 2);
    invoke(cli, ['set', folder, '--image', untouched], 2);
    assert.equal(fs.readFileSync(untouched, 'utf8'), 'unchanged');
    // Exercise the same package through the npx/npm exec entry point.
    assert.match(invoke('npm', ['exec', '--offline', '--yes', `--package=${archive}`, '--', 'foldie', '--version']).stdout, /foldie 0\.2\.0/);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});
