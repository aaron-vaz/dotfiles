#!/usr/bin/env node
// Claude Code Statusline
// Shows: model | current task | directory | context usage | cost | rate limits

const MONTHLY_LIMIT_USD = 2000;

const fs = require('fs');
const path = require('path');
const os = require('os');

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

    // Context window display (shows USED percentage scaled to usable context)
    // Claude Code reserves ~16.5% for autocompact buffer, so usable context
    // is 83.5% of the total window. We normalize to show 100% at that point.
    const AUTO_COMPACT_BUFFER_PCT = 16.5;
    let ctx = '';
    if (remaining != null) {
      // Normalize: subtract buffer from remaining, scale to usable range
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
            timestamp: Math.floor(Date.now() / 1000)
          });
          fs.writeFileSync(bridgePath, bridgeData);
        } catch (e) {
          // Silent fail -- bridge is best-effort, don't break statusline
        }
      }

      // Build progress bar (10 segments)
      const filled = Math.floor(used / 10);
      const bar = '█'.repeat(filled) + '░'.repeat(10 - filled);

      // Color based on usable context thresholds
      if (used < 50) {
        ctx = ` \x1b[32m${bar} ${used}%\x1b[0m`;
      } else if (used < 65) {
        ctx = ` \x1b[33m${bar} ${used}%\x1b[0m`;
      } else if (used < 80) {
        ctx = ` \x1b[38;5;208m${bar} ${used}%\x1b[0m`;
      } else {
        ctx = ` \x1b[5;31m💀 ${bar} ${used}%\x1b[0m`;
      }
    }

    // Current task from todos
    let task = '';
    const homeDir = os.homedir();
    // Respect CLAUDE_CONFIG_DIR for custom config directory setups (#870)
    const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(homeDir, '.claude');
    const todosDir = path.join(claudeDir, 'todos');
    if (session && fs.existsSync(todosDir)) {
      try {
        const files = fs.readdirSync(todosDir)
          .filter(f => f.startsWith(session) && f.includes('-agent-') && f.endsWith('.json'))
          .map(f => ({ name: f, mtime: fs.statSync(path.join(todosDir, f)).mtime }))
          .sort((a, b) => b.mtime - a.mtime);

        if (files.length > 0) {
          try {
            const todos = JSON.parse(fs.readFileSync(path.join(todosDir, files[0].name), 'utf8'));
            const inProgress = todos.find(t => t.status === 'in_progress');
            if (inProgress) task = inProgress.activeForm || '';
          } catch (e) {}
        }
      } catch (e) {
        // Silently fail on file system errors - don't break statusline
      }
    }

    // Cost tracking — session cost from Claude + monthly accumulator across sessions.
    // Monthly file: ~/.claude/costs/YYYY-MM.json → { sessions: { [id]: cost } }
    // Subagent file: ~/.claude/costs/subagent-YYYY-MM.json → { sessions: { [id]: { tokens: N } } }
    // Statusline updates the accumulator on every render (no Stop hook needed).
    // Subagent cost estimate: Sonnet 4.6 blended rate ~$6/1M tokens (60% input, 40% output).
    const SUBAGENT_RATE_PER_TOKEN = 6.0 / 1_000_000;
    let costStr = '';
    const sessionCost = data.cost?.total_cost_usd;
    if (sessionCost != null && session) {
      try {
        const costsDir = path.join(claudeDir, 'costs');
        fs.mkdirSync(costsDir, { recursive: true });

        const now = new Date();
        const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
        const monthFile = path.join(costsDir, `${monthKey}.json`);

        let monthData = { sessions: {} };
        try { monthData = JSON.parse(fs.readFileSync(monthFile, 'utf8')); } catch (e) {}

        monthData.sessions[session] = sessionCost;
        fs.writeFileSync(monthFile, JSON.stringify(monthData));

        // Read subagent accumulator for this session
        let subagentCost = 0;
        try {
          const subFile = path.join(costsDir, `subagent-${monthKey}.json`);
          const subData = JSON.parse(fs.readFileSync(subFile, 'utf8'));
          const subTokens = subData.sessions?.[session]?.tokens || 0;
          subagentCost = subTokens * SUBAGENT_RATE_PER_TOKEN;
        } catch (e) {}

        const totalSessionCost = sessionCost + subagentCost;

        // Monthly total includes subagent costs for all sessions this month
        let monthlySubagentCost = 0;
        try {
          const subFile = path.join(costsDir, `subagent-${monthKey}.json`);
          const subData = JSON.parse(fs.readFileSync(subFile, 'utf8'));
          for (const s of Object.values(subData.sessions || {})) {
            monthlySubagentCost += (s.tokens || 0) * SUBAGENT_RATE_PER_TOKEN;
          }
        } catch (e) {}

        const monthlyTotal = Object.values(monthData.sessions).reduce((a, b) => a + b, 0) + monthlySubagentCost;
        const monthPct = (monthlyTotal / MONTHLY_LIMIT_USD) * 100;

        const fmt = (v) => v < 0.01 ? `$${v.toFixed(4)}` : `$${v.toFixed(2)}`;
        const limitLabel = MONTHLY_LIMIT_USD >= 1000 ? `$${MONTHLY_LIMIT_USD / 1000}k` : `$${MONTHLY_LIMIT_USD}`;

        // Days until billing reset (1st of next month, midnight UTC)
        const nowUtc = new Date();
        const resetUtc = new Date(Date.UTC(nowUtc.getUTCMonth() === 11 ? nowUtc.getUTCFullYear() + 1 : nowUtc.getUTCFullYear(), (nowUtc.getUTCMonth() + 1) % 12, 1));
        const daysLeft = Math.ceil((resetUtc - nowUtc) / 86400000);
        const resetLabel = daysLeft <= 3 ? `\x1b[33m⏳ ${daysLeft}d\x1b[0m` : `⏳ ${daysLeft}d`;

        let color;
        if (monthPct < 50) color = '\x1b[32m';
        else if (monthPct < 75) color = '\x1b[33m';
        else color = '\x1b[31m';

        // Show subagent cost as ~$X suffix when non-zero (estimate indicator)
        const sessionLabel = subagentCost > 0
          ? `${fmt(sessionCost)}+~${fmt(subagentCost)}`
          : fmt(sessionCost);

        costStr = ` │ ${color}💸 ${sessionLabel}\x1b[0m │ ${color}📊 ${fmt(monthlyTotal)}/${limitLabel}\x1b[0m │ ${resetLabel}`;
      } catch (e) {}
    }

    // Rate limits (Claude.ai Pro/Max subscription only — absent on API/enterprise accounts)
    let rateLimits = '';
    const fiveHour = data.rate_limits?.five_hour;
    const sevenDay = data.rate_limits?.seven_day;
    const rlParts = [];

    if (fiveHour != null) {
      const pct = Math.round(fiveHour.used_percentage);
      let color = pct < 50 ? '\x1b[32m' : pct < 75 ? '\x1b[33m' : '\x1b[31m';
      let resetStr = '';
      if (pct >= 75 && fiveHour.resets_at) {
        const minsLeft = Math.max(0, Math.round((fiveHour.resets_at - Math.floor(Date.now() / 1000)) / 60));
        resetStr = ` ~${minsLeft}m`;
      }
      rlParts.push(`${color}5h:${pct}%${resetStr}\x1b[0m`);
    }
    if (sevenDay != null) {
      const pct = Math.round(sevenDay.used_percentage);
      let color = pct < 50 ? '\x1b[32m' : pct < 75 ? '\x1b[33m' : '\x1b[31m';
      rlParts.push(`${color}7d:${pct}%\x1b[0m`);
    }
    if (rlParts.length > 0) rateLimits = ` │ ${rlParts.join(' ')}`;

    // Output
    const dirname = path.basename(dir);
    if (task) {
      process.stdout.write(`\x1b[2m${model}\x1b[0m │ \x1b[1m${task}\x1b[0m │ \x1b[2m${dirname}\x1b[0m${ctx}${costStr}${rateLimits}`);
    } else {
      process.stdout.write(`\x1b[2m${model}\x1b[0m │ \x1b[2m${dirname}\x1b[0m${ctx}${costStr}${rateLimits}`);
    }
  } catch (e) {
    // Silent fail - don't break statusline on parse errors
  }
});
