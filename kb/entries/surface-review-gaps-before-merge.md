---
name: surface-review-gaps-before-merge
description: A conditional merge ("merge if we're all ok") means stop and ask when review finds a gap in what the PR claims to fix. Never merge with the gap only listed in the PR body and report it afterwards.
type: feedback
tags: [pull-requests, review, merge, communication]
status: active
---

When the user authorises a merge conditionally ("self review then merge if we are all ok"), any review finding that means the PR does not fully fix what it claims is a "not ok". Stop before merging. Put the gap to the user with the options (fix it in this PR, or merge now and follow up) and let them choose. Writing the gap into the PR body and merging anyway is making their decision for them.

**Why:** Aaron, after a merge where self-review had found a way round the fix and I disclosed it only in the PR body and the post-merge summary: "why are you telling me gaps after the pr has been merged when we could have fixed it then". The fix for that gap was small enough to fit in the same PR. Reporting it after the merge cost a second PR and took the choice away from him.

**How to apply:** After self-review or code review, before any `gh pr merge`, sort the findings. Anything that is a gap in the PR's own stated goal, or a behaviour change the user hasn't signed off, blocks the merge until the user answers. Cosmetic or unrelated pre-existing findings don't block. An advisor or subagent saying "doesn't block" does not override a condition the user set.

The merge itself may not be yours to run: in Claude Code's auto mode the permission classifier refuses an agent's `gh pr merge` ("Merge Without Review"). Don't retry it or route around it. Report the review state, then hand the user the exact merge command.

## Related

- [[pr-describes-the-change-not-the-decision-history]]
