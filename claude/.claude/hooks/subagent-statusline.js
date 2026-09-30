#!/usr/bin/env node
// Claude Code subagent status line (settings.json -> subagentStatusLine)
//
// Runs once per refresh tick with every visible subagent row on stdin:
//   { columns, tasks: [{ id, type, status, description, label, startTime(ms),
//                        model, effort?, contextWindowSize, tokenCount,
//                        tokenSamples[], name? }] }
// Emits one {"id","content"} JSON line per row to override the default row.
//
// Row: <status glyph> <agent type> <model tier> <elapsed> <ctx %> <tokens> <spark> <effort> <label>
// Agent type comes from the SubagentStart tracker (hooks/subagent-track.sh),
// which records agent_id -> agent_type; the payload itself carries no type.

const fs = require('fs');
const path = require('path');
const os = require('os');

const RESET = '\x1b[0m';
const DIM = '\x1b[2m';
const BOLD = '\x1b[1m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const ORANGE = '\x1b[38;5;208m';
const RED = '\x1b[31m';
const GRAY = '\x1b[90m';

const TIER_COLORS = {
  opus: '\x1b[38;5;141m',
  sonnet: '\x1b[38;5;75m',
  haiku: '\x1b[38;5;114m',
  fable: '\x1b[38;5;214m',
};

const SPARK = '▁▂▃▄▅▆▇█';
const SPARK_POINTS = 8;
const ANSI_RE = /^\x1b\[[0-9;]*m/;

const stdinTimeout = setTimeout(() => process.exit(0), 3000);
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => (input += chunk));
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const tasks = Array.isArray(data.tasks) ? data.tasks : [];
    const width = Math.max(20, (Number(data.columns) || 100) - 1);
    const now = Date.now();
    const stateDir = path.join(
      process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude'),
      'state',
      'subagents',
    );

    const lines = [];
    for (const task of tasks) {
      if (!task || !task.id) continue;
      lines.push(JSON.stringify({ id: task.id, content: renderRow(task, now, width, stateDir) }));
    }
    if (lines.length) process.stdout.write(lines.join('\n') + '\n');
  } catch (e) {
    // Silent fail - a broken status line must never break the panel.
  }
});

function renderRow(task, now, width, stateDir) {
  const status = String(task.status || '').toLowerCase();
  const running = status === 'running';

  const role = readAgentType(stateDir, task.id) || task.name || '';
  const tier = modelTier(task.model);
  const tierColor = TIER_COLORS[tier.family] || GRAY;

  const parts = [];
  parts.push(statusGlyph(status));
  if (role) parts.push(`${BOLD}${role}${RESET}`);
  if (tier.short) parts.push(`${tierColor}${tier.short}${RESET}`);
  if (running && task.startTime) {
    parts.push(`${GRAY}${formatDuration(Math.max(0, Math.floor((now - task.startTime) / 1000)))}${RESET}`);
  } else if (!running && status) {
    parts.push(`${GRAY}${status}${RESET}`);
  }

  const tokens = Number(task.tokenCount) || 0;
  const windowSize = Number(task.contextWindowSize) || 0;
  if (windowSize > 0 && tokens > 0) {
    const pct = Math.min(100, Math.round((tokens / windowSize) * 100));
    parts.push(`${contextColor(pct)}${pct}%${RESET} ${DIM}${formatTokens(tokens)}${RESET}`);
  } else if (tokens > 0) {
    parts.push(`${DIM}${formatTokens(tokens)}${RESET}`);
  }

  const spark = sparkline(task.tokenSamples);
  if (spark) parts.push(`${GRAY}${spark}${RESET}`);
  if (task.effort != null && task.effort !== '') parts.push(`${DIM}⚡${task.effort}${RESET}`);

  const label = String(task.label || task.description || '').replace(/\s+/g, ' ').trim();
  let head = parts.join(' ');
  if (label) head += ` ${DIM}${label}${RESET}`;
  return truncate(head, width);
}

function readAgentType(stateDir, id) {
  // Ids come from Claude Code, but never let one walk out of the state dir.
  if (!/^[A-Za-z0-9_-]+$/.test(String(id))) return '';
  try {
    return fs.readFileSync(path.join(stateDir, id), 'utf8').trim();
  } catch (e) {
    return '';
  }
}

function modelTier(model) {
  const id = String(model || '');
  if (!id) return { family: '', short: '' };
  const match = id.match(/(opus|sonnet|haiku|fable)/i);
  if (!match) return { family: '', short: id.replace(/^claude-/, '') };
  const family = match[1].toLowerCase();
  // claude-haiku-4-5-20251001 -> haiku-4-5, claude-opus-5-5 -> opus-5-5
  const version = id
    .slice(match.index + family.length)
    .replace(/-\d{8}$/, '')
    .replace(/\[.*\]$/, '');
  return { family, short: family + version };
}

function statusGlyph(status) {
  if (status === 'running') return `${ORANGE}●${RESET}`;
  if (['completed', 'complete', 'done', 'succeeded', 'success'].includes(status)) return `${GREEN}✓${RESET}`;
  if (['failed', 'error', 'errored'].includes(status)) return `${RED}✗${RESET}`;
  if (['killed', 'stopped', 'cancelled', 'canceled'].includes(status)) return `${GRAY}■${RESET}`;
  if (['pending', 'queued', 'starting'].includes(status)) return `${YELLOW}○${RESET}`;
  return `${GRAY}·${RESET}`;
}

function contextColor(pct) {
  if (pct < 50) return GREEN;
  if (pct < 65) return YELLOW;
  if (pct < 80) return ORANGE;
  return RED;
}

function sparkline(samples) {
  if (!Array.isArray(samples) || samples.length < 2) return '';
  const recent = samples.slice(-SPARK_POINTS).map(Number).filter(Number.isFinite);
  if (recent.length < 2) return '';
  const max = Math.max(...recent);
  if (max <= 0) return '';
  return recent.map(v => SPARK[Math.min(SPARK.length - 1, Math.floor((v / max) * (SPARK.length - 1)))]).join('');
}

function formatTokens(n) {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1000) return `${Math.round(n / 1000)}k`;
  return String(n);
}

function formatDuration(totalSeconds) {
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = totalSeconds % 60;
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}

// Cut to `width` visible cells, ignoring ANSI escapes, and close any open color.
function truncate(str, width) {
  if (visibleLength(str) <= width) return str + RESET;
  const limit = width - 1;
  let visible = 0;
  let out = '';
  let i = 0;
  while (i < str.length && visible < limit) {
    const ansi = str.slice(i).match(ANSI_RE);
    if (ansi) {
      out += ansi[0];
      i += ansi[0].length;
      continue;
    }
    const ch = String.fromCodePoint(str.codePointAt(i));
    out += ch;
    visible += 1;
    i += ch.length;
  }
  return `${out}…${RESET}`;
}

function visibleLength(str) {
  return Array.from(str.replace(/\x1b\[[0-9;]*m/g, '')).length;
}
