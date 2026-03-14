---
name: pr-reviews
description: Use when reviewing pull requests, PRs shared via link or number, code review requests, or when asked to give feedback on code changes before merge.
model: opus
last_reviewed: 2026-03-13
updated: 2026-03-13
---

# PR Review Workflow

**IMPORTANT: This skill requires using Opus model for thorough analysis and judgment.**

## When to Use
- User shares a PR link or number
- Asked to review code changes before merge

## When NOT to Use
- Reviewing your own uncommitted changes → use `pr-review-toolkit:code-reviewer`
- Post-merge review → just read the code

## Red Flags - STOP

These thoughts mean you're about to violate the workflow:
- "Too simple for full workflow"
- "Running all agents is overkill"
- "This is just a config/docs change"
- "Time pressure justifies shortcuts"
- "I'll include the refinement question in the PR comment"
- **"User said 'post it', so I should submit the review to GitHub"** ← NO! Only create PENDING review.

**All of these mean: Follow the workflow. No shortcuts.**

**CRITICAL: Your job ends at creating the PENDING review:**
- When user says "post it" or "looks good", create the PENDING review
- Show them the GitHub URL
- **STOP - Do NOT submit the review**
- User will submit the review themselves on GitHub

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Overkill for simple change" | "Simple" changes hide big bugs. Run all agents. |
| "Takes too long" | 2-3 minutes prevents hours of debugging. |
| "Generates irrelevant feedback" | You don't know what you don't know. Run all. |
| "Context-dependent, not mandatory" | Workflow is mandatory. Consistency prevents misses. |
| "Poor judgment to run full workflow" | Poor judgment is skipping proven process. |
| "User said post it, so I should submit" | NO. Create PENDING review, show URL, then STOP. User submits. |
| "Pending review created, can submit now" | NEVER submit. User will do it themselves on GitHub. |

## Permissions

| Operation | Allowed |
|-----------|---------|
| `gh pr view/diff/checks`, `gh api` GET | Yes |
| `gh api` POST to create PENDING reviews | Yes |
| `gh api` POST to `/events` endpoint (submit reviews) | **NEVER allowed** |

## Workflow

**Copy this checklist and track your progress:**

```
PR Review Progress:
- [ ] Step 0: Detect GitHub host (github.com vs github.expedia.biz)
- [ ] Step 1: Clone repository
- [ ] Step 2: Fetch PR metadata
- [ ] Step 3: Deep context scan (intent, blast radius, history, risk areas)
- [ ] Step 3.5: Read repo guidance files (REVIEW.md, .github/copilot-instructions.md, AGENTS.md, CLAUDE.md)
- [ ] Step 4: Invoke domain-specific skills
- [ ] Step 5: Run ALL review agents in parallel
- [ ] Step 6: Synthesize findings
- [ ] Step 6.4: On re-review, resolve addressed AI comment threads
- [ ] Step 6.5: Check for existing reviewer comments to reinforce
- [ ] Step 6.6: Prepare inline comments (try inline first, summary for non-inline)
- [ ] Step 6.8: Wait for required checks to pass
- [ ] Step 7: Reply to existing comments + create PENDING review + show URL
```

### 0. Detect GitHub Host

**IMPORTANT: Parse the PR URL to determine which GitHub instance to use.**

```bash
# If PR URL contains an enterprise GitHub host (e.g., github.company.com):
GH_HOST_ENV="GH_HOST=github.company.com"

# If PR URL contains "github.com" or no specific host mentioned:
GH_HOST_ENV=""
```

**Prefix ALL `gh` commands with `$GH_HOST_ENV` throughout the workflow.**

**WARNING:** The `--hostname` flag does NOT exist for `gh` commands. Always use the `GH_HOST` environment variable prefix instead. Example: `GH_HOST=github.company.com gh pr view 42`

### 1. Clone Repository
```bash
rm -rf /tmp/pr-review-*
$GH_HOST_ENV gh repo clone {owner}/{repo} /tmp/pr-review-{number} -- --depth 50
cd /tmp/pr-review-{number}
git fetch origin {pr_branch_name} && git checkout FETCH_HEAD
```
**NOTE:** `gh pr checkout` consistently fails on shallow clones (even `--depth 50`) with "cannot set up tracking information" because the clone refspec only tracks the default branch. Use `git fetch origin <branch> && git checkout FETCH_HEAD` as the primary checkout method. Get the branch name from `$GH_HOST_ENV gh pr view {number} --json headRefName -q .headRefName` (or from `gh api` if `gh pr view` fails on enterprise).

### 2. Fetch PR Metadata
Read `commands.md` for gh commands.

### 3. Deep Context Scan
Answer explicitly: Intent? Blast radius? History? Risk areas?

### 3.5. Read Repo Guidance Files

Check for and read these files from the cloned repo — they define what the team cares about:

```bash
# Check which exist (separate ls calls to avoid non-zero exit when some are missing)
for f in REVIEW.md .github/copilot-instructions.md AGENTS.md CLAUDE.md; do
  test -f "/tmp/pr-review-{number}/$f" && echo "Found: $f"
done
```

| File | Purpose |
|------|---------|
| `REVIEW.md` | Review-specific rules: what to always flag, what to skip, team conventions |
| `.github/copilot-instructions.md` | Coding standards, patterns, architectural rules the team has codified |
| `CLAUDE.md` / `AGENTS.md` | General project instructions (may overlap with review guidance) |

**Incorporate into the review:** Treat violations of rules in these files as findings. Newly-introduced violations are blocking or should-fix. Pre-existing violations (not introduced by this PR) are pre-existing (🟣).

### 4. Invoke Domain Skills

| File Types | Skill |
|------------|-------|
| React/Next.js | `react-best-practices` |
| Kotlin | `kotlin-review` |

### 5. Run Review Agents (parallel)

**Run ALL relevant agents. NO EXCEPTIONS.**

| Change Type | Required Agents |
|-------------|-----------------|
| Any PR | `code-reviewer` |
| Error handling | `silent-failure-hunter` |
| Complex logic | `code-simplifier` |
| Tests | `pr-test-analyzer` |
| New types | `type-design-analyzer` |

**Agent guidance - API/pattern suggestions:**

When running `code-simplifier` and `code-reviewer`, look for:

**Better library APIs:**
```kotlin
// Instead of manual iteration
for (item in list) {
  if (item.active) results.add(item.name)
}
// Suggest: list.filter { it.active }.map { it.name }

// Instead of null checks
if (value != null) {
  doSomething(value)
}
// Suggest: value?.let { doSomething(it) }
```

**Better stdlib usage:**
```java
// Instead of manual collection creation
List<String> empty = new ArrayList<>();
// Suggest: List<String> empty = Collections.emptyList()

// Instead of StringBuilder loops
StringBuilder sb = new StringBuilder();
for (String s : list) {
  sb.append(s).append(",");
}
// Suggest: String.join(",", list)
```

**Only suggest when:**
- Library/stdlib is already a dependency
- Meaningfully more readable (not subjective preference)
- Mark as **non-blocking suggestion**

**Why "simple" PRs need full review:**
- Config changes hide unit mismatches (5s vs 5000ms)
- "2-line fixes" often mask underlying issues
- Agents take 2-3 minutes, prevent hours of debugging
- You don't know what you don't know until agents check

### 6. Synthesize & Refine

Group findings by severity: blocking → should-fix → suggestions → nit → pre-existing.

| Severity | Meaning |
|----------|---------|
| 🔴 blocking | Must fix before merge |
| 🟡 should-fix | Not blocking, but worth doing |
| 💡 suggestion | Non-blocking improvement |
| 🟣 pre-existing | Bug exists but was NOT introduced by this PR — worth noting, not blocking |

**Suggestions category (non-blocking improvements):**
- Better APIs from libraries already in use (e.g., library has a more concise/readable method)
- Modern language features (streams vs complex loops, collection APIs, functional patterns)
- Kotlin stdlib improvements (use `let`, `apply`, `also`, `run` when clearer)
- Java/Kotlin standard APIs that simplify the code (e.g., `Collections.emptyList()` vs `new ArrayList<>()`)

**Key principle:** Only suggest when the alternative is:
- Meaningfully more readable/maintainable
- Part of library/stdlib they're already using
- Not a subjective style preference

**Post directly — no refinement loop.** The review is always PENDING; the user reviews and submits/dismisses on GitHub.

### 6.4. Resolve Addressed AI Comment Threads (Re-reviews Only)

**RULE: On re-reviews, resolve threads where your previous AI comments were addressed by the new commits.**

**Detection:** This step applies when there are already AI-generated review comments on the PR from a previous round. Skip if this is a first review.

**1. Fetch all review threads via GraphQL:**

```bash
$GH_HOST_ENV gh api graphql -f query='
  query($owner:String!, $repo:String!, $number:Int!) {
    repository(owner:$owner, name:$repo) {
      pullRequest(number:$number) {
        reviewThreads(first:100) {
          nodes {
            id
            isResolved
            comments(first:1) {
              nodes {
                body
                path
                originalLine
                author { login }
              }
            }
          }
        }
      }
    }
  }
' -f owner={owner} -f repo={repo} -F number={number}
```

**2. Identify unresolved AI threads:**
- Filter for `isResolved: false`
- Filter for comments whose body contains `AI-generated review comment`

**3. Check if each flagged issue was addressed in new commits:**

```bash
# Check if the flagged file/line changed since the previous review round
git -C /tmp/pr-review-{number} log --oneline {previous_head}..HEAD -- {path}

# View what changed at that location
git -C /tmp/pr-review-{number} diff {previous_head}..HEAD -- {path}
```

If the flagged code was modified, treat the thread as addressed.

**4. Resolve addressed threads:**

```bash
$GH_HOST_ENV gh api graphql -f query='
  mutation($threadId:ID!) {
    resolveReviewThread(input:{threadId:$threadId}) {
      thread { isResolved }
    }
  }
' -f threadId={thread_id}
```

**Important notes:**
- REST API cannot resolve threads — GraphQL mutation is required
- On GitHub Enterprise: use `GH_HOST=<enterprise-host>` prefix on `gh api graphql` calls
- If `previous_head` is unknown, use the second-to-last commit on the PR branch: `git -C /tmp/pr-review-{number} rev-parse HEAD~1`
- Do NOT auto-resolve threads from other human reviewers — only yours (AI disclaimer present)

### 6.5. Check for Existing Reviewer Comments (IMPORTANT)

**RULE: When your findings match existing reviewer comments, reply to their threads instead of creating duplicate comments.**

Before creating new inline comments, check if other reviewers have already commented on the same issues:

```bash
# Fetch existing review comments
gh api $GH_HOST_ENV repos/{owner}/{repo}/pulls/{number}/comments | \
  jq -r '.[] | "\(.id) | \(.user.login) | \(.path):\(.line) | \(.body[0:100])"'
```

**Strategy:**

1. **Map your findings to existing comments:**
   - Read through existing reviewer comments
   - Identify which of your findings overlap with existing feedback
   - Note the comment ID for each overlap

2. **For overlapping findings:**
   - ✅ Reply to the existing comment thread
   - ✅ Reinforce the finding with additional context
   - ✅ Include code examples showing the fix
   - ✅ Start with AI disclaimer: `🤖 **AI-generated review comment**`

3. **For non-overlapping findings:**
   - ✅ Create new inline comments (see section 6.6 below)

**Why this matters:**
- Avoids duplicate comment threads on the same issue
- Shows alignment with human reviewers
- Provides value by adding code examples and technical depth
- Keeps discussion consolidated in one thread

**Example workflow:**
- Total findings: 16
- Match existing comments: 5 (reply to these threads)
- New findings: 9 (create inline comments)
- Non-inline findings: 2 (add to summary)
- **Result:** 5 replies + 9 inline comments + 1 summary comment

### 6.6. Prepare Inline Comments (IMPORTANT)

**RULE: Always use inline comments. Only use summary comments for findings that can't be inline.**

**GitHub API Limitation:** Inline comments can ONLY be placed on:
- ✅ Lines that were added (`+` in diff)
- ✅ Lines that were removed (`-` in diff)
- ✅ Context lines near changes (typically 3-5 lines before/after modifications)
- ❌ Unchanged code far from any diff

**Strategy (no thresholds, no decision trees):**

1. **For each finding, try inline first:**
```bash
# Check if your target line appears in the PR diff
gh pr diff {number} | grep -B3 -A3 "pattern from target line"
```

2. **If line IS in diff context:**
   - ✅ Post as inline comment on that specific line
   - ✅ Use the exact file path and line number from diff

3. **If line is NOT in diff context:**
   - ❌ Cannot post inline (will fail with HTTP 422 "Unprocessable Entity")
   - ✅ Include in summary comment with file:line reference like `` `useNoteForm.ts:225-256` ``

4. **Final result:**
   - All inline-eligible findings → inline comments
   - All non-inline-eligible findings → grouped in summary comment
   - Both posted together in ONE pending review

**Example:**
- Total findings: 16
- Can be inline: 9 (malformed JSON, query methods × 3, variable typo, magic numbers × 4)
- Cannot be inline: 7 (test coverage gaps referencing missing test files)
- **Result:** Post 9 inline comments + 1 summary comment with 7 findings (grouped by file/area)

**When is summary comment acceptable?**

Summary comments are ONLY acceptable when:
1. Finding references code that's NOT in the PR diff at all (e.g., "missing tests" for test files not in PR)
2. Finding references architecture/patterns across multiple files (can't pin to one line)
3. GitHub API returns HTTP 422 "Unprocessable Entity" when trying inline (line outside diff context)

**When is summary comment NOT acceptable?**
1. "Too many inline comments" → Not a valid reason, post them all inline
2. "Findings are similar" → Each finding gets its own inline comment
3. "Easier to group in summary" → Convenience is not a criterion
4. Line appears in `gh pr diff` output → MUST be inline

**If uncertain, default to inline.** Summary is the exception.

### 6.7. Pre-Posting Self-Check (MANDATORY)

**Before creating the pending review, verify ALL of these:**

```
Self-Check Checklist:
□ Attempted inline comments for ALL findings (checked each line in pr diff)
□ Only using summary for findings that CANNOT be inline (verified line not in diff)
□ AI disclaimer present on EVERY comment (inline AND replies): 🤖 **AI-generated review comment**
□ Replied to existing reviewer comments where findings overlap (checked gh api comments)
□ Using git -C pattern (not cd && git) in all examples and commands
□ Pending review (NO event parameter, not calling /events endpoint)
□ Required checks passed (or user explicitly said to skip waiting)
□ Ready to open review URL in browser, show it to user, and STOP (not submitting to GitHub)
```

**If ANY checkbox fails, go back and fix before posting.**

**Common self-check failures:**
- "I put some findings in summary because there were too many" → Try inline for each one first
- "I didn't check existing comments" → Run `gh api repos/{owner}/{repo}/pulls/{number}/comments` now
- "I forgot AI disclaimer on one inline comment" → Add it to ALL comments
- "I used cd && git in an example" → Change to git -C pattern
- "Review is complete, should I submit it?" → NO, create PENDING and show URL only

### 6.8. Wait for Required Checks to Pass (MANDATORY)

**RULE: Do NOT post the review until all required checks have passed. No point reviewing code the author needs to fix for CI first.**

**Why:** Posting review comments while tests/lint/build are failing creates noise. The author already knows they need to fix CI. Your code review is most valuable when the PR is in a "CI green" state.

**1. Check current status of required checks:**

```bash
$GH_HOST_ENV gh pr checks {number} --repo {owner}/{repo} --required
```

**If `--required` flag is not supported** (older gh versions or enterprise), fall back to:
```bash
# Get all checks and filter for required ones via branch protection
$GH_HOST_ENV gh pr checks {number} --repo {owner}/{repo}
```

**2. Evaluate results:**

| Status | Action |
|--------|--------|
| All required checks pass | Proceed to Step 7 |
| Required checks still running | Inform user, wait for completion |
| Required checks failing | Inform user: "Required checks are failing — holding review until they pass. Let me know if you'd like me to post anyway." |
| No required checks configured | Proceed to Step 7 (nothing to gate on) |

**3. Waiting behavior:**

- **Interactive mode:** Tell the user checks are still running/failing. Ask if they want to wait or post anyway. If waiting, poll every 60 seconds (up to 10 minutes), then ask user how to proceed.
- **Automated mode (`-p`):** Poll every 60 seconds up to 15 minutes. If checks still not green after 15 minutes, post the review anyway (the team can triage).

```bash
# Poll loop (automated mode)
for i in $(seq 1 15); do
  STATUS=$($GH_HOST_ENV gh pr checks {number} --repo {owner}/{repo} --required 2>&1)
  if echo "$STATUS" | grep -qE "^(pass|✓)"; then
    break
  fi
  if echo "$STATUS" | grep -qi "fail"; then
    echo "Required checks failing — posting review anyway after timeout"
    break
  fi
  sleep 60
done
```

**4. User override:** If the user explicitly says "post anyway" or "don't wait for checks", skip this step and proceed to Step 7 immediately.

### 7. Create PENDING Review (Final Step)

Read `comment-formats.md` for templates. **Never post without user approval.**

**CRITICAL: Your job is to create the PENDING review, then STOP. User will submit it themselves.**

**Workflow:**

1. **Reply to existing comments** (if you have findings that match existing reviewer feedback):
```bash
$GH_HOST_ENV gh api repos/{owner}/{repo}/pulls/{number}/comments \
  -f body="$(cat <<'EOF'
🤖 **AI-generated review comment**

{reinforcement_text_with_code_examples}
EOF
)" \
  -F in_reply_to={comment_id}
```
**IMPORTANT for replies:**
- Use `POST /pulls/{number}/comments` with `in_reply_to` field (NOT `/comments/{id}/replies` -- that endpoint does not exist and returns 404)
- Use single quotes around `'EOF'` to prevent variable expansion
- Do NOT add extra backslashes or escaping in heredoc
- MUST start with: `🤖 **AI-generated review comment**`
- Provide additional context and code examples to reinforce the finding

2. **Create PENDING review** (NO event parameter) with remaining comments:
```bash
gh api $GH_HOST_ENV repos/{owner}/{repo}/pulls/{number}/reviews \
  -f commit_id="{commit_sha}" \
  -f body="{summary_comment}" \
  --field 'comments[][path]={file_path}' \
  --field 'comments[][side]=RIGHT' \
  --field 'comments[][line]={line_number}' \
  --field 'comments[][body]=🤖 **AI-generated review comment**\n\n{comment_text}'
```
**IMPORTANT:**
- Do NOT include `-f event=COMMENT` - omitting `event` creates PENDING review
- Response includes `id` and `html_url`
- **Use `$GH_HOST_ENV` for GitHub Enterprise instances (github.expedia.biz)**
- **ALL inline comments MUST start with: `🤖 **AI-generated review comment**`**

3. **Log the review for learning analysis**:
```bash
echo "{\"url\":\"{pr_url}\",\"repo\":\"{owner}/{repo}\",\"pr_number\":{number},\"reviewed_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"review_id\":\"{review_id}\",\"host\":\"{github_host}\",\"learned\":false}" >> ~/.claude/pr-reviews/log.jsonl
```

4. **Open review in browser and show URL to user, then STOP**:
```bash
open {html_url}
```
```
✅ Pending review created!

Review URL: {html_url}
Review ID: {review_id}

The review is ready for you to submit on GitHub.
```

4. **DO NOT submit the review**:
   - ⚠️ **NEVER call the `/events` endpoint**
   - ⚠️ User will submit the review themselves on GitHub
   - ⚠️ Your job ends at creating the PENDING review

**Posting guidelines:**
- ❌ NEVER include `event` parameter (creates PENDING)
- ❌ NEVER call the `/events` endpoint to submit
- ✅ Reply to existing comments when findings match (with AI disclaimer)
- ✅ Group all inline comments + summary in ONE review
- ✅ ALL comments MUST have AI disclaimer: `🤖 **AI-generated review comment**` (inline AND replies)
- ✅ Always try inline first, use summary only when line is outside diff context
- ✅ Show user the pending review URL
- ✅ User submits the review themselves on GitHub

## Automated Mode (CI / Webhooks)

When invoked via `claude -p "Review PR {url}"` (non-interactive), behavior differs:

| Step | Interactive | Automated (`-p`) |
|------|-------------|-----------------|
| Step 6: Refinement loop | **Skipped** — post directly | **Skipped** — post directly |
| Step 6.4: Resolve threads | Manual | Runs normally |
| Step 6.8: Wait for required checks | Ask user, wait or skip on request | Poll up to 15 min, then post anyway |
| Step 7: Create PENDING review | Always | Runs normally |

**In automated mode:** Reviews post directly without human sign-off. This is expected and intentional for GitHub Actions and webhook server setups. The team reviews and dismisses AI comments on GitHub instead.

## Large PR Strategy

If diff is huge:

1. **Ask if it can be split** (if not already merged)
2. **Focus on architectural changes first**
3. **Review file-by-file if needed**
4. **Prioritize new code over moved/renamed code**

**Triage order:**
1. New files - Most likely to have issues
2. Modified core logic - High impact
3. Test files - Verify coverage
4. Config changes - Check for security/breaking changes
5. Renamed/moved files - Lowest priority (usually safe)

**When to suggest splitting:**
- Multiple unrelated features
- Both refactoring AND new features
- Changes spanning 3+ unrelated modules
- More than ~500 lines of meaningful changes

**Breaking down large reviews:**
```bash
# Get changed files list (gh pr diff has no --name-only flag)
$GH_HOST_ENV gh pr diff {number} | grep "^diff --git" | sed 's|.*b/||'

# Review by directory (gh pr diff doesn't support file path filtering)
git -C /tmp/pr-review-{number} diff main -- src/components/
git -C /tmp/pr-review-{number} diff main -- src/api/
```

## Common Mistakes

**Skipping review agents for "simple" PRs**
- Problem: Miss hidden bugs in config changes, docs errors
- Fix: Run all relevant agents. Takes 2-3 minutes.

**Skipping Deep Context Scan**
- Problem: Miss architectural implications
- Fix: Answer all 4 questions explicitly every time

**Not asking if large PR can be split**
- Problem: Miss issues due to review fatigue
- Fix: Always suggest splitting PRs >500 meaningful lines

**Including refinement questions in public PR comments**
- Problem: Refinement loop question appears in public GitHub comment
- Fix: Ask "Review ready?" to human partner BEFORE posting, not in PR comment
- Refinement happens privately, not publicly on GitHub

**Posting comments separately instead of grouped review**
- Problem: Using individual API calls creates separate mini-reviews, hard to track
- Fix: Create ONE pending review with all comments, user will submit themselves
- Benefit: All feedback grouped together, easier for PR author to navigate

**Attempting inline comments on unchanged code**
- Problem: GitHub API rejects comments on lines outside diff context (HTTP 422)
- Fix: ALWAYS try inline first, verify line is in `gh pr diff` output
- Fallback: Put non-inline-eligible findings in summary comment with file:line references
- Detection: If you see "Line could not be resolved" error, the line is outside diff context
- Rule: No thresholds or decision trees - use inline when possible, summary when not

**Extracting line numbers from diff context**
- Problem: Using source file line numbers directly fails with HTTP 422. Inline comments MUST use line numbers from the actual PR diff, not source file
- Fix: Parse `gh pr diff {number}` output to extract actual line numbers. Look for `@@ -X,Y +A,B @@` markers that show diff context boundaries
- Pattern: Lines shown with `+` or `-` prefix in diff output are the only valid line numbers for inline comments
- Example: If diff shows `+58: const newValue = 42`, then line=58 is valid. If line 58 is unchanged in diff, it's not inline-eligible
- Detection: If you see "Invalid request" or "Unprocessable Entity" when posting inline comments, likely wrong line number format
- Tool: Use `gh pr diff {number} | grep -B2 -A2 "pattern"` to verify target line appears in diff context first

**Search patterns in diff output (special character escaping)**
- Problem: Using grep with literal special characters (like parentheses) in patterns piped from `gh pr diff` fails with "parentheses not balanced"
- Example failure: `gh pr diff 243 | grep -B2 -A2 "\.with\("` → `grep: parentheses not balanced`
- Root cause: Parentheses are special regex metacharacters and must be escaped when using ERE (Extended Regular Expression) mode
- Fix options:
  - Use `grep -F` (literal string search, no regex): `gh pr diff 243 | grep -F ".with("`
  - Use proper escaping with `grep -E`: `gh pr diff 243 | grep -E -B2 -A2 '\\.with\\('` (double-escape backslashes)
  - Use `grep -P` (Perl regex): `gh pr diff 243 | grep -P -B2 -A2 '\.with\('`
- Best practice: Use `-F` for literal searches (no regex needed), `-E` only when pattern needs regex features
- Detection: "parentheses not balanced" or "Invalid regular expression" errors when piping `gh pr diff`

**Submitting review instead of leaving it PENDING**
- Problem: You call the `/events` endpoint and submit the review to GitHub
- Fix: NEVER submit reviews. Create PENDING review, show URL, then STOP
- Detection: If review appears on GitHub immediately, you submitted it (wrong)
- Rule: Create PENDING (no event parameter), show URL, user submits themselves

**Missing AI disclaimers on inline comments**
- Problem: Inline comments don't start with the AI disclaimer
- Fix: ALL inline comments MUST start with: `🤖 **AI-generated review comment**\n\n`
- Detection: Check every inline comment has the disclaimer prefix
- Why: Users need to know which comments came from AI review agents

**Forgetting to use GH_HOST env var for GitHub Enterprise**
- Problem: Commands fail with 404, "unknown flag: --hostname", or API errors when reviewing enterprise GitHub PRs
- Fix: Prefix gh commands with `GH_HOST=<enterprise-host>` env var. Example: `GH_HOST=github.company.com gh pr view 42`
- WARNING: `--hostname` flag does NOT exist for `gh` commands. Use env var prefix instead
- Detection: "unknown flag: --hostname" or "Not Found" errors on enterprise PRs
- Rule: Parse PR URL first (Step 0), use `GH_HOST=<enterprise-host> gh <command>` pattern

**gh pr checkout fails on ALL shallow clones (including --depth 50)**
- Problem: `gh pr checkout` fails with "cannot set up tracking information" on shallow clones regardless of depth
- Root cause: `gh repo clone --depth N` sets refspec to only track the default branch (`+refs/heads/master:refs/remotes/origin/master`). `gh pr checkout` fetches the PR branch but cannot create a local tracking branch because the refspec is restricted
- Fix: Do NOT use `gh pr checkout` after shallow clone. Use `git fetch origin <branch> && git checkout FETCH_HEAD` as the primary checkout method
- Get branch name: `gh pr view {number} --json headRefName -q .headRefName`
- Detection: "fatal: cannot set up tracking information; starting point 'origin/...' is not a branch"
- History: 10+ failures across 6 days (02-24 through 03-09), --depth 50 does NOT fix the issue

**Vague architectural comments without context**
- Problem: Comments like "use of JSON is not recommended for GraphQL" don't explain tradeoffs
- Fix: Always provide context for architectural guidance:
  - WHEN this pattern IS appropriate (use cases, constraints)
  - WHEN this pattern ISN'T appropriate (anti-patterns, gotchas)
  - WHY (tradeoffs, performance, maintainability implications)
- Example: "JSON for GraphQL responses loses type safety - better for dynamic/unknown schemas, but typed approaches (codegen, TypeScript types) are preferred when schema is stable and types can be generated"
- Detection: If comment prescribes a rule without explaining context or tradeoffs

**Not checking for existing reviewer comments to reinforce**
- Problem: Creating duplicate comment threads when teammates already flagged the same issue
- Fix: Always check existing comments first using `gh api repos/{owner}/{repo}/pulls/{number}/comments`
- Strategy: Reply to existing threads with reinforcement + code examples when findings match
- Benefit: Consolidated discussion, shows alignment with team, adds value through examples
- Detection: Multiple comments on same line/issue in PR thread

**Shell interprets backticks in Python/bash heredocs as command substitution**
- Problem: When markdown content contains backticks (e.g., `` `FilterAndSortMenu.tsx` ``), passing it through `python3 -c` in bash causes shell to interpret backticks as command substitution
- Fix: Write content to a temp file first (`/tmp/pr-body.txt`), then read it from Python/curl/gh. Or use `$()` syntax exclusively and avoid backtick-heavy content in inline bash
- Detection: "command not found: SomeComponent.tsx" errors, exit code 127
- Alternative: Use `gh api` with `-f body=@/tmp/pr-body.txt` to read body from file

**Copilot already reviewed the PR (coexistence workflow)**
- Situation: GitHub Copilot (or another AI reviewer) has already posted review comments before you start
- Strategy: Do NOT duplicate their findings. Instead:
  1. Read Copilot's comments: `gh api repos/{owner}/{repo}/pulls/{number}/comments`
  2. For findings that match Copilot's: Reply to their threads with reinforcement + code examples
  3. For findings Copilot missed: Create summary-only PENDING review with additional findings
  4. If you already created a pending review with duplicates: Delete it (`gh api repos/{owner}/{repo}/pulls/{number}/reviews/{id} -X DELETE`) and recreate
- Detection: Check for existing AI review comments in Step 6.5 — if present, adapt workflow
- Benefit: Reinforces teammate findings, avoids noise, adds value through unique findings only

**Missing AI disclaimers on reply comments**
- Problem: Reply comments to existing threads don't start with AI disclaimer
- Fix: ALL comments (inline AND replies) MUST start with: `🤖 **AI-generated review comment**`
- Detection: Check every comment and reply has the disclaimer prefix
- Why: Users need transparency that AI agents generated the feedback

**Using wrong API endpoint for PR comment replies (404 error)**
- Problem: Using `POST /repos/{owner}/{repo}/pulls/comments/{comment_id}/replies` returns 404 on both github.com and github.expedia.biz
- Root cause: The `/replies` sub-endpoint does not exist in the GitHub API for pull request review comments
- Fix: Use `POST /repos/{owner}/{repo}/pulls/{number}/comments` with the `in_reply_to` field set to the comment ID
- Correct: `gh api repos/{owner}/{repo}/pulls/{number}/comments -F in_reply_to={comment_id} -f body="..."`
- Wrong: `gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies -f body="..."`
- Detection: HTTP 404 "Not Found" when trying to reply to PR review comments
- History: Failed on github.com (03-09, PR 3360) and github.expedia.biz (03-03, PR 369)

**Over-escaping markdown in bash heredocs**
- Problem: Adding extra backslashes in heredoc causes broken markdown rendering (e.g., `\*\*bold\*\*` instead of **bold**)
- Fix: Use single quotes around EOF marker (`<<'EOF'`) to prevent variable expansion, no extra escaping needed
- Example (correct): `cat <<'EOF'\n**bold** text\nEOF`
- Example (wrong): `cat <<'EOF'\n\\*\\*bold\\*\\* text\nEOF`
- Detection: If markdown in posted comments shows literal backslashes or escaped characters

**Attempting to filter `gh pr diff` by file path**
- Problem: `gh pr diff {number} -- path/to/file.tsx` fails with "accepts at most 1 arg(s)"
- Fix: `gh pr diff` doesn't support file filtering. Use git to view specific files:
  - `git -C /tmp/pr-review-{number} show HEAD:path/to/file.tsx` (view single file)
  - `git -C /tmp/pr-review-{number} diff HEAD~1 -- path/to/file.tsx` (view diff for file)
- Detection: Error message "accepts at most 1 arg(s), received 2"

**`gh pr view` fails with GraphQL Bot fragment error on enterprise GitHub**
- Problem: `gh pr view` fails with "Fragment on Bot can't be spread inside RequestedReviewer" on enterprise GitHub
- Root cause: Enterprise GitHub Server (3.x) has a GraphQL schema that doesn't support Bot type in RequestedReviewer union
- Fix: Use `gh api` instead of `gh pr view` for enterprise PRs:
  - `GH_HOST=<enterprise-host> gh api repos/{owner}/{repo}/pulls/{number}` (REST API, no GraphQL)
  - Parse JSON response with `jq` for fields you need
- Detection: "Fragment on Bot can't be spread inside RequestedReviewer" error
- Scope: Only affects enterprise GitHub, not github.com

**Posting review while required checks are failing**
- Problem: Review comments add noise when CI is already red — author needs to fix tests/build first
- Fix: Check `gh pr checks {number} --required` before posting. Wait for green or ask user
- Detection: Required checks show "fail" or "pending" status when about to post
- Rule: Don't review code the author will have to change anyway for CI. Wait for required checks
- Override: User can say "post anyway" to skip the gate

**Reading large files without offset/limit**
- Problem: Files >256KB fail with "exceeds maximum allowed size". Test files often 400KB+
- Fix: Use offset/limit parameters for large files: `Read(file_path, offset=0, limit=100)`
- Alternative: Use Grep to search instead of full file read
- Example: `Grep(pattern="testMethodName", path=file_path)` instead of reading entire file
- Detection: If getting "exceeds maximum allowed size/tokens" error, file is too large for direct read

## Re-read Triggers

- For gh commands: Read `commands.md`
- For comment templates: Read `comment-formats.md`

## Principles
- Assume competence
- Challenge design decisions if they smell off
- Distinguish "wrong" from "I'd do it differently"
- Don't bikeshed style if there's a formatter
- Architectural comments need context: explain WHEN pattern works, WHEN it doesn't, and WHY (tradeoffs)

## Reviewer Patterns

These are recurring patterns identified from 576 real review comments across 147 PRs. Flag these proactively.

### Architecture

**Hand-rolling logic the framework already provides**
- Flag: Spring Data generated queries, Spring beans, Kotlin stdlib, reactive type conversions — if the framework does it, don't allow hand-rolled code alongside it
- Voice: "There's already an API for this" / "You get this for free with [framework]"
- Examples: custom query methods when Spring Data generates them, manual DI when Spring can inject, `asException` already exists

**Proper layer boundaries — code placed in the wrong layer or module**
- Flag: Repository logic in services, service logic in controllers, modules too granular/broad, circular deps worked around rather than fixed
- Voice: "That breaks encapsulation" / "Circular dep points to a design problem, not something to work around"
- Rule: Service layer is the public API. Circular deps = design smell. Modules map to domains, not individual features

**Spring DI instead of manual object creation**
- Flag: `new Mapper()` inside methods, manual registry patterns, manually managed impl lists when Spring can inject them
- Voice: "Spring gives you a bean, please inject that" / "Make each impl a bean"

**Scope containment — isolate temporary/backfill code**
- Flag: Backfill logic, migration code, or feature-flag methods added to core service classes
- Voice: "Instead of polluting the service, move to the processor so it's not forgotten to be removed"
- Rule: Temporary code must live in a dedicated processor/class so it can be cleanly deleted

**Over-broad changes — question scope and necessity**
- Flag: Flags/parameters propagated further than needed, changes with unintended blast radius
- Voice: "Is this needed outside of [scope]?" / "This will affect all X — is that what you want?"

### Domain

**Incorrect metric IDs, field names, or domain terminology**
- Flag: Wrong metric ID format, inactive metrics in templates, inconsistent naming of domain concepts
- Rule: Metric ID = metric `id` field with `_v1` suffix removed. Never guess — look them up from source
- Terms to enforce: `readoutDate` (not analysisDate), `criticalValue` (not significance), `DefaultScenario` (test sizing)
- Voice: "This metric is in the incorrect format" / "That is the term we use already"

**Data precision belongs in ETL/UI, not the source API**
- Flag: Rounding or precision changes in APIs that serve raw/source data
- Voice: "This is the source data and shouldn't be adjusted for consumers — do it in the ETL job instead"

**Data accuracy over convenience — use the most accurate source**
- Flag: Convenient approximations (e.g. instance problems) used instead of accurate source (e.g. ERS API)
- Voice: "We should be accurate with this data and only do best guess when we can't be accurate"

### Error Handling

**Silent errors or insufficient logging context**
- Flag: Catch blocks without logging, error messages without source context, swallowed stack traces
- Fix: Always pass exception `e` as a log argument (not just message). Include enough context to identify WHERE it came from
- Voice: "We will not know what the issue is" / "Pass e as another argument, you'll lose the stack otherwise"

**Locale-dependent or timezone-ambiguous formatting**
- Flag: Date/number formatting that varies by user locale, timestamps without explicit UTC zone
- Voice: "This will change based on the user's locale — do we want that?" / "Our dates are UTC, should we enforce that?"

### Kotlin

**Named parameter consistency — all or none**
- Flag: Mixing named and positional parameters in the same call loses the benefit of explicitness
- Voice: "Better to be consistent — we either don't use named params or we use them for all fields"

**Top-level declarations over companion objects**
- Flag: Constants or functions in companion objects when there's no Java interop requirement
- Voice: "Unless you want to use this in Java, it can just be top-level"

**Delegation style over manual wrapping**
- Flag: Classes that wrap another type and forward calls manually
- Fix: `class Foo(calc: Bar = Bar()) : BarInterface by calc`
- Voice: "Move this to Kotlin's delegation style — the current approach isn't customisable"

**Coroutine-aware patterns — never block inside coroutines**
- Flag: `.block()`, `runBlocking`, or blocking calls inside suspend functions or coroutine contexts
- Voice: "You are inside a coroutine, you shouldn't block"

**Value classes for single-type wrappers**
- Flag: Data classes that wrap a single primitive/type with no added behaviour
- Fix: `@JvmInline value class MetricId(val value: String)`

### Testing

**Test through the public API, not internal methods**
- Flag: Tests that call private methods directly or test internal state instead of observable behaviour
- Voice: "Tests should test it using the public API — the data is still available for testing"

**Use JUnit assertions, not JVM asserts**
- Flag: `assert(condition)` (JVM), `assertTrue`/`assertEquals` without import from JUnit, missing `assertThrows`
- Voice: "These are all JVM asserts, please switch to JUnit assertions"

**Test unique constraints with duplicate saves**
- Flag: Database constraint/index added without a test that tries to save two identical records
- Voice: "Have a test that enforces your index using 2 saves to ensure your constraints are protected"

### React / TypeScript

**Duplicate data-fetching calls across components**
- Flag: Multiple components independently fetching the same expensive data (e.g. full readout response)
- Fix: Lift data fetching higher in the tree and share via context
- Voice: "We are making the readout calls multiple times in different components — move the data to a context"

**Inline types instead of declared types**
- Flag: Inline type annotations in React components instead of named/declared types
- Voice: "We should declare types like this rather than using inline types"
