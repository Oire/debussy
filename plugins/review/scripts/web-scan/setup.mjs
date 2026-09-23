#!/usr/bin/env node
/**
 * Install the toolchain scan.mjs runs on: Playwright, axe-core, and
 * Chromium's headless shell, into a directory outside the plugin (the plugin
 * directory is replaced on every update).
 *
 *   node setup.mjs <toolchain-dir> [--update]
 *
 * Idempotent: an existing toolchain is left alone unless --update is given.
 * Only the headless shell is installed, which never shows a window.
 */

import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const [dirArg, ...flags] = process.argv.slice(2);
if (!dirArg) {
  console.error('usage: node setup.mjs <toolchain-dir> [--update]');
  process.exit(2);
}
const dir = resolve(dirArg);
const update = flags.includes('--update');
const browsers = join(dir, 'browsers');
const ready = existsSync(join(dir, 'node_modules', 'playwright')) && existsSync(browsers);

if (ready && !update) {
  console.log(`toolchain ready: ${dir}`);
  process.exit(0);
}

mkdirSync(dir, { recursive: true });
if (!existsSync(join(dir, 'package.json'))) {
  writeFileSync(join(dir, 'package.json'), `${JSON.stringify({ private: true, description: 'debussy web-scan toolchain' }, null, 2)}\n`);
}

// npm is a .cmd on Windows, which Node only spawns through a shell.
const run = (command, args, env = {}) => {
  const result = spawnSync(command, args, {
    cwd: dir,
    stdio: 'inherit',
    shell: process.platform === 'win32',
    env: { ...process.env, ...env },
  });
  if (result.status !== 0) {
    console.error(`setup failed: ${command} ${args.join(' ')} exited with ${result.status}`);
    process.exit(1);
  }
};

run('npm', ['install', '--no-audit', '--no-fund', 'playwright@1', 'axe-core@4']);
run(process.execPath, [join(dir, 'node_modules', 'playwright', 'cli.js'), 'install', '--only-shell', 'chromium'],
  { PLAYWRIGHT_BROWSERS_PATH: browsers });
console.log(`toolchain ready: ${dir}`);
