# Changelog

## v2.0.0 — Companion to Superpowers

### What changed

This repo stopped being a fork of `Aedelon/claude-code-blueprint` and became
a standalone companion to [obra/superpowers](https://github.com/obra/superpowers).

The shape of the work is now:

- **Hooks** for deterministic safety (secrets, dangerous commands, format, git)
- **Domain skills** Superpowers doesn't ship (`anti-hallucination`,
  `security-audit`, `research-protocol`, `uv-workflow`, `commit-message`)
- **Path-scoped rules** for Python and TypeScript conventions
- **A short CLAUDE.md** that delegates methodology to Superpowers

### Why now

Three things shifted between v1 (March 2026) and v2 (May 2026).

**Anthropic's guidance changed.** The current best-practices page now reads
*"you describe what you want and Claude figures out how to build it"* and
*"ruthlessly prune — if Claude already does something correctly without the
instruction, delete it or convert it to a hook."* The whole posture moved
from scaffolding the model's reasoning to trusting it and intervening only
where defaults fail.

**The models got better.** Claude Opus 4.7 and Sonnet 4.6 plan before
implementing, search before answering present-day factual questions, debug
systematically when the bug warrants it, and self-calibrate confidence.
v1 was built for a model that needed protocols to do those things. v2's
model does them natively, and the protocols started getting in the way —
forcing rituals on trivial tasks, flattening judgment about when planning
is worth the latency.

**Superpowers shipped and matured.** v5.1.0 of Superpowers, available in
Anthropic's official Claude Code marketplace, owns the development
methodology end-to-end: Socratic brainstorming, written plans with 2–5
minute tasks, subagent-driven execution with two-stage review, strict
TDD, code review, merge/PR/finish workflows. v1 of this repo had its own
versions of several of these. Maintaining a parallel methodology while
Superpowers refined theirs across thousands of users was a losing
proposition.

### What was removed

| Removed | Replaced by |
|---|---|
| `skills/anti-hallucination/` protocol layer | Native model behavior + Context7 MCP lookup |
| `skills/core-protocols/` systematic debugging | Superpowers `systematic-debugging` |
| `skills/brainstorm/` design exploration | Superpowers `brainstorming` + `dispatching-parallel-agents` |
| `skills/new-project/` orchestrator | Superpowers `brainstorming` → `writing-plans` → `subagent-driven-development` |
| `skills/code-patterns/` review patterns | Superpowers `requesting-code-review` + `rules/` |
| 5-phase AAPEV pattern as universal requirement | Superpowers's brainstorm → plan → execute → review → finish |
| Confidence levels in CLAUDE.md | Model self-calibration |
| Generic code-standards prose in CLAUDE.md | `rules/python.md`, `rules/typescript.md` |
| 6-layer "operating system" framing | Honest "companion plugin" framing |

### What survived

- All 11 hooks. Hooks are the most durable layer because they run regardless
  of model upgrades. Secrets scanning, dangerous bash, write format,
  destructive git, secrets-in-writes, npm audit, session hooks.
- `anti-hallucination` retained as a Context7-lookup workflow (gap in
  Superpowers).
- `security-audit` parallel-agent fan-out (deps, secrets, OWASP).
- `research-protocol` for citation discipline.
- `uv-workflow` for the Python toolchain choice.
- `commit-message` for conventional commits.
- Path-scoped `rules/python.md` and `rules/typescript.md`.
- All 4 domain agents.

### CLAUDE.md: 400 → 57 lines

v1's CLAUDE.md tried to be a kernel: anti-hallucination protocol, confidence
levels, toolchain, code standards, /compact rules, debugging procedure.

v2's CLAUDE.md is what's left after removing everything the model does
natively and everything Superpowers covers. What survives: methodology
ownership statement, toolchain defaults, skill triggers for the domain
skills this repo adds, writing-hygiene rules, three house rules.

The writing-hygiene rules are new. They emerged from noticing how Claude
fills documentation with scaffolding from the generation process (plan
references, rejected-alternative narration, defensive "this is not"
framing, marketing adjectives). These are patterns the model produces
without instruction and that hooks can't reliably detect, so they belong
as prompt-level rules.

### Migration

If you installed v1 (`mueslipolo/claude-code-blueprint`), see
[MIGRATING.md](MIGRATING.md). The short version: back up `~/.claude/`,
install Superpowers, clone this repo, run `./install.sh`. Diff your old
CLAUDE.md against the new one and recover only project-specific lines
(toolchain, conventions, paths). Drop anything that told Claude *how to
think*.

### Repository move

v1 lived at `mueslipolo/claude-code-blueprint` as a fork. v2 lives at
`mueslipolo/claude-code-companion` as a standalone repo. The old repo
is archived with a pointer to this one.

---

## v1.0.0 — Fork of Aedelon/claude-code-blueprint

Initial fork (March 2026) with these additions:

- `new-project` orchestrator skill for full project inception
- `install.sh` script with backup-then-copy behavior
- Project-specific permission tweaks

Inherited from upstream:

- 6-layer architecture (MCP / Security / Agents / Skills / Memory / CLAUDE.md)
- 32 skills following the 5-phase AAPEV pattern
- 17-event hook coverage (9 implemented)
- 40 allow + 38 deny permission rules

v1 worked well for Sonnet 3.5 and the early Claude 4.x family. By the time
Opus 4.7 shipped, much of the scaffolding had become redundant with model
defaults. v2 is the response to that.
