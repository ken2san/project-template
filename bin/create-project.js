#!/usr/bin/env node
'use strict';

const { spawnSync } = require('child_process');
const path = require('path');

const scriptPath = path.join(__dirname, '..', 'init-project.sh');
const args = process.argv.slice(2);

const result = spawnSync('zsh', [scriptPath, ...args], {
  stdio: 'inherit',
  env: process.env,
});

if (result.error) {
  if (result.error.code === 'ENOENT') {
    console.error(
      '\nError: zsh was not found on this system.\n' +
        'This tool requires zsh (macOS/Linux, or Windows via WSL2).\n' +
        'On native Windows, install WSL2 first: https://learn.microsoft.com/windows/wsl/install\n' +
        'Then re-run this command from inside the WSL2 terminal.'
    );
  } else {
    console.error(`\nError: failed to launch zsh: ${result.error.message}`);
  }
  process.exit(1);
}

process.exit(result.status ?? 1);
