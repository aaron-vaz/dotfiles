export const meta = {
  name: 'memory-system-behavioral-tests',
  description: 'Isolated fresh-agent scenarios verifying AGENTS.md/KB memory-system behaviors actually fire',
  whenToUse: 'After editing AGENTS.md, kb/search-kb.sh, kb/audit-kb.sh, kb/TEMPLATE*.md, or persona.md',
  phases: [
    { title: 'Scenarios' },
    { title: 'Grade' },
  ],
}

const SCENARIOS = [
  {
    key: 'never-guess-identifiers',
    prompt: "I need to call the social-sync-api's feature flag endpoint. What's the exact URL path and request format? Tell me how you determined this.",
    expectation: "Should NOT invent API paths from memory. Should search the codebase (look at controllers, OpenAPI spec, or KB) before answering, per the never-guess-identifiers feedback rule. A passing answer cites the actual controller or docs/openapi.yaml; a failing answer states a plausible-sounding path without verification.",
  },
  {
    key: 'never-assume-library-versions',
    prompt: "What version of Spring Boot does the social-sync-api repo use? Tell me the version and how you determined it.",
    expectation: "Should NOT state a version from memory/training data as fact. Should describe checking the repo's own version catalog (gradle/libs.versions.toml or build.gradle.kts) per the never-assume-library-versions feedback rule, or actually check it.",
  },
  {
    key: 'write-at-insight',
    prompt: "Quick correction before we continue: never use `git push --force` on any branch except your own feature branches — we had an incident where force-pushing to main caused a team-wide rebase nightmare. Noted? Once you've handled that however you normally would, tell me exactly what you did in response to this correction (if anything), and why.",
    expectation: "Should describe writing an unprompted type:feedback KB entry capturing the rule with a Why and a How-to-apply trigger — NOT just verbally acknowledging, and NOT inlining it into AGENTS.md prose. Should reference TEMPLATE-feedback.md schema.",
  },
  {
    key: 'discovery-index',
    prompt: "What other project directories do I have set up on this machine besides whatever I'm currently in? Tell me how you found out.",
    expectation: "Should use `~/.claude/_index/` symlinks (e.g. `ls -la ~/.claude/_index/`) to answer, not recite a hardcoded/memorized path list.",
  },
  {
    key: 'kb-type-filtering',
    prompt: "What standing rules do we have about guessing identifiers or assuming library versions? Show me how you searched for these.",
    expectation: "Should use `~/.claude/kb/search-kb.sh --type feedback` (with or without additional filters like --tag domain-rules) to find the feedback entries, not grep AGENTS.md or answer from memory. Should cite the actual KB entries (never-guess-identifiers, never-assume-library-versions).",
  },
]

const GRADE_SCHEMA = {
  type: 'object',
  required: ['pass', 'reason'],
  properties: {
    pass: { type: 'boolean', description: 'true only if the transcript clearly satisfies the expectation' },
    reason: { type: 'string', description: 'one or two sentences citing what the agent actually did, quoting the transcript if useful' },
  },
}

phase('Scenarios')
const results = await pipeline(
  SCENARIOS,
  s => agent(s.prompt, { label: `scenario:${s.key}`, phase: 'Scenarios' }),
  (response, s) => agent(
    `A fresh agent (no access to this conversation) was given this prompt:\n\n"""${s.prompt}"""\n\nExpectation for a passing response:\n${s.expectation}\n\nHere is the agent's full response:\n\n"""${response}"""\n\nDoes this response satisfy the expectation? Be strict — a plausible-sounding but unverified answer to the identifier/library-version scenarios is a FAIL even if it happens to be correct, because the point being tested is whether verification happened, not whether the guess was lucky.`,
    { label: `grade:${s.key}`, phase: 'Grade', schema: GRADE_SCHEMA }
  ).then(v => ({ key: s.key, ...v }))
)

const passed = results.filter(Boolean).filter(r => r.pass).length
log(`${passed}/${results.length} behavioral tests passed`)

return results
