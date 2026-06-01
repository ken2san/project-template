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

process.exit(result.status ?? 1);
