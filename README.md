# Claude Code Companion

A small, opinionated layer on top of [obra/superpowers](https://github.com/obra/superpowers).

Superpowers ships the methodology: brainstorming, planning, subagent-driven
development, TDD, code review. This repo ships what Superpowers doesn't:

- **Deterministic hooks** — secrets scanning, dangerous-command blocking,
  auto-format, destructive-git warnings. These run regardless of whether
  the model remembers to invoke a skill.
- **Library verification** — Context7-first lookups for APIs the model
  shouldn't guess at.
- **Domain skills** Superpowers doesn't cover — security audits, research
  protocol with citations.
- **Toolchain conventions** — `uv`, conventional commits, path-scoped
  Python/TypeScript rules.

---

## What this is not

- Not a fork of Superpowers
- Not a replacement for Superpowers
- Not a "complete system" or "operating system for Claude"

If you don't have Superpowers installed, install that first. This repo
assumes it's there.

---

## Prerequisites

```sh
# Install Superpowers via the official Claude marketplace
/plugin install superpowers@claude-plugins-official
```

Then come back here.

---

## Install

```sh
git clone https://github.com/mueslipolo/claude-code-companion.git
cd claude-code-companion
./install.sh
```

The installer backs up your existing `~/.claude/` first. Review
`settings.template.json` before adopting — permissions are personal.

System requirements:

- Claude Code with Superpowers plugin installed and active
- `jq` for hook JSON parsing (`brew install jq` / `apt install jq`)
- `prettier`, `ruff` for the auto-format hook (optional, hook degrades gracefully)

---

## What's included

```
claude-code-companion/
├── CLAUDE.md                    # Small kernel: only what Superpowers doesn't cover
├── install.sh
├── settings.template.json
│
├── hooks/scripts/               # The most durable layer
│   ├── user-prompt-secrets.sh   # Scan secrets before they reach the API
│   ├── bash-guard.sh            # Block dangerous commands (sanitized patterns)
│   ├── write-guard.sh           # Protect sensitive files and detect secrets
│   ├── write-format.sh          # Auto-format on write (ruff/prettier)
│   ├── bash-vuln.sh             # npm/pip audit after install
│   ├── permission-git.sh        # Warn on destructive git operations
│   ├── session-start.sh         # Project detection, git context
│   ├── session-end.sh           # Cleanup
│   ├── stop.sh                  # Git summary on stop
│   ├── pre-compact.sh           # Preserve state before context compaction
│   └── posttooluse-failure.sh   # Log tool failures for debugging
│
├── skills/
│   ├── anti-hallucination/      # Context7-first library verification
│   ├── security-audit/          # Parallel agents: deps, secrets, OWASP
│   ├── research-protocol/       # Citations and source discipline
│   ├── uv-workflow/             # Python toolchain (uv init, deps, CI)
│   └── commit-message/          # Conventional commit generation
│
├── rules/
│   ├── python.md                # Loads when editing .py
│   └── typescript.md            # Loads when editing .ts/.tsx
│
├── agents/                      # Domain specialists
│   ├── research-synthesizer.md
│   ├── finance-advisor.md
│   ├── midjourney-expert.md
│   └── prompt-engineer.md
│
└── commands/
    ├── docs.md                  # /docs <library> via Context7
    └── review.md                # /review [file]
```

---

## How this composes with Superpowers

Superpowers covers the **development methodology** — the *how* of writing code:

| Concern | Owned by |
|---|---|
| Spec refinement (brainstorming) | Superpowers |
| Implementation planning | Superpowers |
| Subagent-driven execution | Superpowers |
| Test-driven development | Superpowers |
| Code review | Superpowers |
| Merge/PR/discard workflow | Superpowers |
| Systematic debugging | Superpowers |
| **Secrets scanning** | **This repo** |
| **Dangerous command blocking** | **This repo** |
| **Auto-format on write** | **This repo** |
| **Library API verification** | **This repo** |
| **Security audit (parallel fan-out)** | **This repo** |
| **Toolchain conventions (uv, ruff)** | **This repo** |
| **Commit message format** | **This repo** |

No overlap, by design. When Superpowers and this repo would both have an
opinion (e.g. "should the model debug systematically?"), this repo defers.

---

## What was removed from earlier versions

If you're coming from the older "claude-code-blueprint" fork, several
components were dropped because Superpowers covers them better:

- ❌ `core-protocols` (systematic debugging) — Superpowers has
  `systematic-debugging` with a 4-phase root cause process
- ❌ 5-phase **AAPEV** pattern — conflicts with Superpowers's phase model
  (brainstorm → plan → execute → review → finish)
- ❌ `new-project` orchestrator — Superpowers's
  brainstorming → writing-plans → subagent-driven covers this
- ❌ `brainstorm` skill (architectural variant) — overlaps with Superpowers's
  `brainstorming`; if you need architecture-specific fan-out, use
  Superpowers's `dispatching-parallel-agents`
- ❌ Confidence levels in CLAUDE.md — Superpowers's "evidence over claims"
  philosophy covers the spirit
- ❌ Generic code-standards prose — toolchain-specific stuff moved to
  `rules/python.md` and `rules/typescript.md`

The principle: if Superpowers does it, don't redo it here. If Claude does
it natively, don't write a rule for it. Hooks are exempt because they run
deterministically regardless of model behavior.

---

## Skills, briefly

Each skill activates from natural language. No special syntax.

| You say | Skill | What happens |
|---|---|---|
| "How do I use the FastAPI router?" | `anti-hallucination` | Queries Context7 before answering |
| "Is this codebase secure?" | `security-audit` | Spawns 3 parallel agents (deps, secrets, OWASP) |
| "Find recent papers on RAG" | `research-protocol` | Cites sources, dates, URLs |
| "Set up a Python project with uv" | `uv-workflow` | Full uv init + deps + CI |
| "Commit this" | `commit-message` | Conventional commit from the diff |

---

## Philosophy

Three principles, in order of priority:

1. **Don't fight Superpowers.** If Superpowers has an opinion, this repo
   stays silent.
2. **Hooks over prose.** Anything that can be enforced deterministically
   should be a hook, not a CLAUDE.md rule.
3. **Prune ruthlessly.** Following Anthropic's own guidance: if Claude
   already does it correctly, don't write it down.

---

## License

Apache 2.0
