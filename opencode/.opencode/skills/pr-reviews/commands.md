# PR Review Commands

**IMPORTANT: Prefix all `gh` commands with `GH_HOST=github.expedia.biz` when reviewing PRs on GitHub Enterprise (github.expedia.biz). Do NOT use `--hostname` flag -- it does not exist.**

## Fetch PR Metadata

```bash
gh pr view {number} $GH_HOST_ENV
gh pr diff {number} $GH_HOST_ENV  # Returns full diff (no file filtering possible)
gh api $GH_HOST_ENV repos/{owner}/{repo}/pulls/{number}/comments
gh pr checks {number} $GH_HOST_ENV
```

**NOTE:** On enterprise GitHub (github.expedia.biz), `gh pr view` may fail with "Fragment on Bot can't be spread inside RequestedReviewer". Use the REST API fallback:
```bash
GH_HOST=github.expedia.biz gh api repos/{owner}/{repo}/pulls/{number} | jq '{title: .title, body: .body, state: .state, head: .head.ref, base: .base.ref, changed_files: .changed_files, additions: .additions, deletions: .deletions}'
```

**NOTE on jq + special characters:** PR bodies containing emoji or special characters can cause jq parse errors. If jq fails, pipe through `cat` or use `--raw-output` / `--arg` to pass values safely:
```bash
# Fallback: extract specific fields without jq processing the body
GH_HOST=github.expedia.biz gh api repos/{owner}/{repo}/pulls/{number} --jq '{title: .title, state: .state, head: .head.ref, base: .base.ref}'
```

**Note on filtering diffs:** `gh pr diff` doesn't support file path arguments. To view specific files:
```bash
# For single file in PR:
git -C /tmp/pr-review-{number} show HEAD:path/to/file.tsx

# For diff of specific file:
git -C /tmp/pr-review-{number} diff HEAD~1 -- path/to/file.tsx
```

## Post Inline Comment

For critical/important issues on specific diff lines:

```bash
gh api $GH_HOST_ENV repos/{owner}/{repo}/pulls/{number}/comments \
  -f body="Comment text" \
  -f commit_id="$(gh pr view {number} $GH_HOST_ENV --repo {owner}/{repo} --json headRefOid -q .headRefOid)" \
  -f path="path/to/file.tsx" \
  -F line={line_number} \
  -f side=RIGHT
```

## Reply to Existing Comment

To reply to an existing reviewer comment thread:

```bash
$GH_HOST_ENV gh api repos/{owner}/{repo}/pulls/{number}/comments \
  -f body="Reply text" \
  -F in_reply_to={comment_id}
```

**WARNING:** Do NOT use `/pulls/comments/{id}/replies` -- that endpoint does not exist (returns 404). Always use `/pulls/{number}/comments` with `in_reply_to` field.

## Post Summary Comment

```bash
# Comment only
gh pr review {number} $GH_HOST_ENV --comment --body "..."

# Request changes (blocking issues)
gh pr review {number} $GH_HOST_ENV --request-changes --body "..."

# Approve
gh pr review {number} $GH_HOST_ENV --approve --body "..."
```

**Order: Post inline comments first, then summary.**

## Resolve Review Thread (GraphQL — REST cannot do this)

```bash
# Fetch all threads + identify unresolved AI threads
$GH_HOST_ENV gh api graphql -f query='
  query($owner:String!, $repo:String!, $number:Int!) {
    repository(owner:$owner, name:$repo) {
      pullRequest(number:$number) {
        reviewThreads(first:100) {
          nodes {
            id
            isResolved
            comments(first:1) {
              nodes { body path originalLine author { login } }
            }
          }
        }
      }
    }
  }
' -f owner={owner} -f repo={repo} -F number={number}

# Resolve a thread by ID
$GH_HOST_ENV gh api graphql -f query='
  mutation($threadId:ID!) {
    resolveReviewThread(input:{threadId:$threadId}) {
      thread { isResolved }
    }
  }
' -f threadId={thread_id}
```

**Filter AI threads:** `isResolved: false` AND body contains `AI-generated review comment`

## Bulk PR Comment Fetching (Bootstrap/Analysis)

To fetch review comments across multiple PRs (e.g., for style analysis):
```bash
# Works on github.com:
gh api repos/{owner}/{repo}/pulls/{number}/reviews --jq '.[].id' | while read id; do
  gh api repos/{owner}/{repo}/pulls/{number}/reviews/$id/comments
done

# Works on github.com:
gh api "search/issues?q=reviewed-by:{user}+repo:{owner}/{repo}+type:pr&per_page=100"
```

**WARNING: GitHub Enterprise Server (GHES 3.10) limitations:**
- `search/issues` with `reviewed-by:` or `commenter:` qualifiers returns HTTP 422
- `repos/{owner}/{repo}/pulls` REST endpoint may return 404 on GHES
- Workaround: Use `gh api repos/{owner}/{repo}/pulls/{number}/comments` per-PR (works on both)
- For bulk analysis, prefer github.com repos or paginate individual PR endpoints on GHES

## Deep Context Scan Questions

Before reviewing, answer explicitly:

**Intent:**
- What problem does this PR solve?
- Is there a linked issue? Full context?

**Blast radius:**
- What systems/modules does this touch?
- Related files NOT in the diff that might be affected?
- Shared state, configs, dependencies impacted?

**History:**
- Recent commits in affected areas?
- Ongoing refactors this might conflict with?

**Risk areas:**
- Auth/security implications?
- Data migration or schema changes?
- Breaking changes to APIs or contracts?
