#!/usr/bin/env node
// Interactive Gemini model picker for Claude Code via CCR.
// Updates settings.json with chosen model + matching effortLevel, then launches claude.

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const readline = require('readline');

const HOME = process.env.USERPROFILE || process.env.HOME;
const SETTINGS = path.join(HOME, '.claude-gemini', 'settings.json');
const CLAUDE_EXE = path.join(HOME, '.local', 'bin', 'claude.exe');

const MODELS = [
  { id: 'gemini-2.5-flash',              effort: 'low',    label: 'Gemini 2.5 Flash',          desc: '日常默认，稳定快 ~5s' },
  { id: 'gemini-2.5-pro',                effort: 'medium', label: 'Gemini 2.5 Pro',            desc: '更强、稳定 ~10s' },
  { id: 'gemini-3-flash-preview',        effort: 'low',    label: 'Gemini 3 Flash Preview',    desc: 'V3 速度，偶发空响应' },
  { id: 'gemini-3.1-pro-preview',        effort: 'high',   label: 'Gemini 3.1 Pro Preview',    desc: 'V3 强思考，慢 + 不稳' },
  { id: 'gemini-3-pro-preview',          effort: 'high',   label: 'Gemini 3 Pro Preview',      desc: 'V3 Pro，常空响应' },
  { id: 'gemini-3.1-flash-lite-preview', effort: 'off',    label: 'Gemini 3.1 Flash Lite',     desc: '极速、不思考' },
];

const RESET = '\x1b[0m', BOLD = '\x1b[1m', DIM = '\x1b[2m', PURPLE = '\x1b[1;35m', CYAN = '\x1b[36m', YELLOW = '\x1b[33m';

console.log(`\n${PURPLE}🤖 Gemini Model Picker${RESET} ${DIM}(via CCR)${RESET}\n`);
MODELS.forEach((m, i) => {
  const eff = m.effort === 'off' ? `${DIM}(no thinking)${RESET}` : `${YELLOW}effort=${m.effort}${RESET}`;
  console.log(`  ${BOLD}${i + 1}${RESET}. ${CYAN}${m.label}${RESET}  ${eff}`);
  console.log(`     ${DIM}${m.desc}${RESET}`);
});
console.log(`\n${DIM}Press Enter for default (1).${RESET}`);

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
rl.question(`${BOLD}Choice [1-${MODELS.length}]: ${RESET}`, (answer) => {
  rl.close();
  const idx = Math.max(1, Math.min(MODELS.length, parseInt((answer || '1').trim(), 10) || 1)) - 1;
  const m = MODELS[idx];
  console.log(`\n${PURPLE}→ ${m.label}${RESET} ${DIM}(${m.id}, effort=${m.effort})${RESET}\n`);

  const settings = JSON.parse(fs.readFileSync(SETTINGS, 'utf8'));
  settings.model = `gemini,${m.id}`;
  if (m.effort === 'off') {
    delete settings.effortLevel;
  } else {
    settings.effortLevel = m.effort;
  }
  fs.writeFileSync(SETTINGS, JSON.stringify(settings, null, 2));

  const env = { ...process.env };
  delete env.ANTHROPIC_API_KEY;
  delete env.ANTHROPIC_AUTH_TOKEN;
  env.CLAUDE_CONFIG_DIR = path.join(HOME, '.claude-gemini');
  env.ANTHROPIC_BASE_URL = 'http://127.0.0.1:3456';
  env.ANTHROPIC_AUTH_TOKEN = 'router-local-key';

  const args = ['--model', `gemini,${m.id}`, ...process.argv.slice(2)];
  const child = spawn(CLAUDE_EXE, args, { stdio: 'inherit', env });
  child.on('exit', (code) => process.exit(code || 0));
});
