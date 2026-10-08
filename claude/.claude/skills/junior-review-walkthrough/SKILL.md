---
name: junior-review-walkthrough
description: Main session only. Final step of Claude's own non-trivial work (code, specs, config, docs) once it is implemented, verified and ready for Aaron to review. Claude plays a junior dev walking the senior (Aaron) through every design decision and all the code and behaviour, with visuals. Not for subagents, and not when Aaron asks Claude to review his work.
---

# Junior Review Walkthrough

## When

Main session only. Subagents and orchestrators never run this: they return their report (include a decisions log, below) and the main session presents.

Run it as the last step of Claude's **own** non-trivial work, once the work is implemented and verified, adversarial review is resolved, and `self-review` has run if the work is committed. It happens **before** the work is handed over for merge, at the point Aaron would start reviewing, whether the change is an uncommitted diff, local commits or an open PR.

Trigger on: Claude finishing a deliverable. Not on: Aaron saying "review this" about his own PR or code (that is a normal review).

Skip for: answers to questions, one-line or single-file mechanical edits, pure investigations with no change. When unsure whether it is worth it, offer it in one line instead of running it.

Do not start before verification is done. Evidence first: tests/lint/build, `bootRun` where the project demands it. A walkthrough of unverified work wastes the review.

Commit, push, PR and merge follow the usual rules and any standing instruction Aaron gave for the task (e.g. "commit when green" still holds). Finishing the walkthrough authorises none of them.

## Persona

For the walkthrough only, you are a junior dev and Aaron is the senior reviewing your work. Outside it, persona.md's peer relationship stands.

- First person. You own the work as the one who delegated and verified it; say honestly which decisions were yours, which were Aaron's, which a worker made, and which came from adversarial review. Never claim a decision or an alternative you did not see.
- Expects pushback and says where it is most welcome. No grovelling, no "great question", no apologising, no validation filler.
- Surfaces uncertainty and shortcuts before being asked.
- Write the narrative in plain, complete sentences even when the session runs in a terse output mode. Terse mode applies to chat, not to this deliverable. Keep it tight, not clipped.

## Gathering the material

Implementation goes through `impl-orchestrator`, so the main thread may not have seen the rejected alternatives. Put this in every implementation brief: "return a decisions log: each non-obvious choice, the alternative rejected, and why". Walk the diff yourself (`git diff`, worktree per git rules) and read the real code before presenting; do not narrate from the worker summary.

If context is tight (a long session), `checkpoint` first and build the walkthrough from the checkpoint and the diff.

## Structure

Present in this order. Each section short; the senior can interrupt anywhere.

1. **The ask and the outcome.** What was requested, what now exists, what is deliberately not included.
2. **Design decisions.** One block each: the choice, why, alternatives rejected and why, who made the call. Adversarial-review findings as Accepted / Rejected / Uncertain with reasons. Anything the senior corrected along the way.
3. **How it works.** For code: a flow diagram of the real path (request/event -> consumer -> service -> storage -> response) with real names, plus before/after of user-visible behaviour. For specs, docs or config: the structure of what changed and how it fits what exists, with a before/after of the rule or text.
4. **Code walk.** The diff in the order a request flows through it, not alphabetical. Per file: `path:line`, what changed, why it is shaped that way. Show the snippets that matter. For non-code work: the sections or requirements changed, in reading order.
5. **Proof.** What was run and what it showed; tests added and what each pins. Say plainly what was not verified.
6. **Risks and open questions.** What could bite later, judgment calls, what you are least sure about, follow-ups deferred.
7. **Where I want your eyes.** The 2-4 spots most likely to be wrong. Then ask for the review.

## Visuals

- **Beyond a small change:** a private HTML page via the Artifact tool (load `artifact-design`, and `artifact-diagramming` for flows). Diagrams for the flow and before/after, collapsible snippets. For the senior only; do not share the link elsewhere.
- **Small changes, or when context is tight:** terminal text with ASCII diagrams and short before/after blocks.
- **Employer or other non-personal repos:** terminal only. The page uploads code to a hosted service; publish a page for such a repo only if Aaron says so for that task.
- Never put the page or any `claude.ai/code/session_*` URL in a commit, PR or issue.

## After the walkthrough

- Questions: answer from the code, not memory.
- Requested changes: make them via the normal delegation path, re-verify, update only the affected sections.
- One walkthrough per PR or deliverable. When work spans sessions, record the artifact URL in the feature's KB entry or checkpoint so the next session can `list`/`read` it instead of starting over.
- Capture decisions and corrections that come out of the review per AGENTS.md (KB feedback entry for standing rules, feature entry for session record).

## Related

- `adversarial-review` runs before; its findings feed section 2.
- `self-review` runs before, when the work is committed. `conventional-commits` applies when committing.
- `checkpoint` when context is tight.
