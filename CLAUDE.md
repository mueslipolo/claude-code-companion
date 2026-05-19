# CLAUDE.md

## Methodology ownership

Superpowers handles brainstorming, planning, subagent execution, TDD,
code review, and systematic debugging. Don't restate those workflows or
invent parallel ones.

## Toolchain

- **Python**: `uv` for envs and deps, `ruff` for lint+format, `pytest` for tests.
- **TypeScript/JS**: `pnpm`, `prettier`, `vitest`.
- **Git**: conventional commits.

## Skill triggers

- Library or API uncertainty → `anti-hallucination`. Don't guess function signatures.
- "Is this codebase secure?" → `security-audit`.
- Research requiring citations → `research-protocol`.
- Python project bootstrap → `uv-workflow`.
- Commit a diff → `commit-message`.

For coding, planning, debugging, and reviewing — defer to Superpowers.

## Writing hygiene

**Don't leak the scaffolding into the artifact.** Plan, steps, phases,
subagent execution, "as we discussed above" — keep these out of comments,
docstrings, and commit messages.

**Don't document rejected design choices**, unless a future reader would
plausibly try the rejected approach and suffer for it. Test: would
omitting this note cause someone to re-litigate the decision or hit the
same problem we already solved?

- Keep: "Using a mutex, not a channel — channels deadlock under back-pressure with our worker pool size."
- Drop: "We considered Redis but chose Postgres."

Genuinely important rejected alternatives go in `docs/adr/`, not in code.

**Write what it is, not what it isn't.** Describe positively; let the
reader infer the rest.

**No marketing prose.** Drop:

- Value adjectives without a property: *powerful, seamless, robust, elegant, intuitive, production-grade, battle-tested*.
- Throat-clearing: *it's worth noting, importantly, of course, notably, simply*.
- Effort-signaling: *carefully designed, thoughtfully built*.
- Padding: *not only X but Y, comprehensive suite of*.

Test: would the sentence survive being read aloud in code review without anyone smirking?

## House rules

- Prefer editing existing files over creating new ones.
- When a task is ambiguous, ask one clarifying question before acting.
- Cite sources (file:line, doc URL, commit SHA) for non-obvious claims.
