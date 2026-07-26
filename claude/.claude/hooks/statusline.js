#!/usr/bin/env node
// Claude Code Statusline
// Line 1: [model]  folder-icon dirname  |  branch-icon git-branch
// Line 2: context-used %  |  5h rate limit (orange, time left)  |  7d rate limit (green)  |  tea-timer (gray, session elapsed)
// Line 3: static auto-mode footer hint (approximation — see note at bottom of file)

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

const RESET = '\x1b[0m';
const DIM = '\x1b[2m';
const BOLD = '\x1b[1m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const ORANGE = '\x1b[38;5;208m';
const RED = '\x1b[31m';
const GRAY = '\x1b[90m';

// Read JSON from stdin
let input = '';
// Timeout guard: if stdin doesn't close within 3s (e.g. pipe issues on
// Windows/Git Bash), exit silently instead of hanging. See #775.
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const model = data.model?.display_name || 'Claude';
    const dir = data.workspace?.current_dir || process.cwd();
    const session = data.session_id || '';
    const remaining = data.context_window?.remaining_percentage;
    const homeDir = os.homedir();

    // ---- Line 1: model | folder | branch ----
    const dirname = dir === homeDir ? path.basename(homeDir) : path.basename(dir);
    const folderIcon = dir === homeDir ? '🏠' : '📁';

    // Git branch: prefer explicit worktree name from workspace, fall back to `git`.
    // --no-optional-locks avoids contending with concurrent git operations.
    let branch = data.workspace?.git_worktree || '';
    if (!branch) {
      try {
        branch = execSync('git --no-optional-locks rev-parse --abbrev-ref HEAD', {
          cwd: dir,
          stdio: ['ignore', 'pipe', 'ignore'],
        }).toString().trim();
        if (branch === 'HEAD') branch = ''; // detached HEAD, not useful to show
      } catch (e) {
        branch = '';
      }
    }

    let line1 = `${BOLD}[${model}]${RESET} ${folderIcon} ${DIM}${dirname}${RESET}`;
    if (branch) line1 += ` ${DIM}|${RESET} 🌿 ${GREEN}${branch}${RESET}`;

    // ---- Context window usage (shows USED percentage scaled to usable context) ----
    // Claude Code reserves ~16.5% for autocompact buffer, so usable context
    // is 83.5% of the total window. We normalize to show 100% at that point.
    const AUTO_COMPACT_BUFFER_PCT = 16.5;
    let ctxSegment = '';
    if (remaining != null) {
      const usableRemaining = Math.max(0, ((remaining - AUTO_COMPACT_BUFFER_PCT) / (100 - AUTO_COMPACT_BUFFER_PCT)) * 100);
      const used = Math.max(0, Math.min(100, Math.round(100 - usableRemaining)));

      // Write context metrics to bridge file for the context-monitor PostToolUse hook.
      // The monitor reads this file to inject agent-facing warnings when context is low.
      if (session) {
        try {
          const bridgePath = path.join(os.tmpdir(), `claude-ctx-${session}.json`);
          const bridgeData = JSON.stringify({
            session_id: session,
            remaining_percentage: remaining,
            used_pct: used,
            timestamp: Math.floor(Date.now() / 1000),
          });
          fs.writeFileSync(bridgePath, bridgeData);
        } catch (e) {
          // Silent fail -- bridge is best-effort, don't break statusline
        }
      }

      // Green -> yellow -> orange -> red gradient as usage climbs.
      let color;
      if (used < 50) color = GREEN;
      else if (used < 65) color = YELLOW;
      else if (used < 80) color = ORANGE;
      else color = RED;

      ctxSegment = `${color}${used}%${RESET}`;
    }

    // ---- Rate limits (Claude.ai Pro/Max subscription only — absent on API/enterprise accounts) ----
    const fiveHour = data.rate_limits?.five_hour;
    const sevenDay = data.rate_limits?.seven_day;
    let fiveHourSegment = '';
    let sevenDaySegment = '';

    if (fiveHour != null) {
      const pct = Math.round(fiveHour.used_percentage);
      let leftStr = '';
      if (fiveHour.resets_at) {
        const secsLeft = Math.max(0, fiveHour.resets_at - Math.floor(Date.now() / 1000));
        leftStr = ` (${formatDuration(secsLeft)} left)`;
      }
      // Screenshot uses a consistent orange for the 5h session window regardless of %.
      fiveHourSegment = `${ORANGE}5h ${pct}%${leftStr}${RESET}`;
    }
    if (sevenDay != null) {
      const pct = Math.round(sevenDay.used_percentage);
      sevenDaySegment = `${GREEN}7d ${pct}%${RESET}`;
    }

    // ---- Tea-timer: elapsed time since this session was first seen ----
    // Not exposed in the stdin JSON (no session-start timestamp field), so we
    // approximate by persisting a first-seen timestamp per session id.
    let teaSegment = '';
    if (session) {
      try {
        const stateDir = path.join(process.env.CLAUDE_CONFIG_DIR || path.join(homeDir, '.claude'), 'state');
        fs.mkdirSync(stateDir, { recursive: true });
        const statePath = path.join(stateDir, `session-start-${session}`);
        let startEpoch;
        if (fs.existsSync(statePath)) {
          startEpoch = parseInt(fs.readFileSync(statePath, 'utf8'), 10);
        } else {
          startEpoch = Math.floor(Date.now() / 1000);
          fs.writeFileSync(statePath, String(startEpoch));
        }
        const elapsed = Math.max(0, Math.floor(Date.now() / 1000) - startEpoch);
        teaSegment = `${GRAY}🍵 ${formatDuration(elapsed)}${RESET}`;
      } catch (e) {
        // Silent fail -- timer is best-effort
      }
    }

    const line2Parts = [ctxSegment, fiveHourSegment, sevenDaySegment, teaSegment].filter(Boolean);
    const line2 = line2Parts.join(` ${DIM}|${RESET} `);

    // Static footer hint. NOTE: this line normally comes from Claude Code's own
    // input-box UI (based on live permission mode / vim mode), not from the
    // statusLine stdin payload -- the schema has no permission-mode field to
    // drive it dynamically. Kept here only because it was explicitly requested
    // to match the reference screenshot; Claude Code may render its own copy
    // of this hint immediately below, which can look duplicated.
    const line3 = `${DIM}▶▶ auto mode on (shift+tab to cycle) · ← for agents${RESET}`;

    const lines = [line1];
    if (line2) lines.push(line2);
    lines.push(line3);
    process.stdout.write(lines.join('\n'));
  } catch (e) {
    // Silent fail - don't break statusline on parse errors
  }
});

function formatDuration(totalSeconds) {
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = totalSeconds % 60;
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}
