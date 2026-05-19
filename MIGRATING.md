# Migrating from claude-code-blueprint (the old fork)

If you previously installed `mueslipolo/claude-code-blueprint` (the
fork of `Aedelon/claude-code-blueprint`), this document walks you through
moving to the companion layout.

## Why the change

The old repo was a fork of an "operating system for Claude Code" — built
before [obra/superpowers](https://github.com/obra/superpowers) shipped and
before Anthropic's May 2026 guidance to *"describe what you want and let
Claude figure out how"* and *"ruthlessly prune"* configuration.

In that landscape, the old repo was carrying three kinds of weight:

1. **Cognitive scaffolding** the model now does natively (anti-hallucination
   protocols, confidence levels, AAPEV phases)
2. **Methodology** that Superpowers does better and more rigorously
   (systematic debugging, brainstorming, planning, TDD)
3. **Genuinely useful additions** (hooks, library verification via Context7,
   security audit fan-out, toolchain rules)

The companion repo keeps category 3 and drops categories 1 and 2.

## What changed

| Old component | Status | Replacement |
|---|---|---|
| `skills/anti-hallucination/` | ✅ Kept | Same |
| `skills/core-protocols/` | ❌ Removed | Superpowers `systematic-debugging` |
| `skills/brainstorm/` | ❌ Removed | Superpowers `brainstorming` + `dispatching-parallel-agents` |
| `skills/new-project/` | ❌ Removed | Superpowers `brainstorming` → `writing-plans` → `subagent-driven-development` |
| `skills/code-patterns/` | ❌ Removed | Folded into `rules/` and Superpowers `requesting-code-review` |
| `skills/security-audit/` | ✅ Kept | Same |
| `skills/uv-workflow/` | ✅ Kept | Same |
| `skills/commit-message/` | ✅ Kept | Same |
| `skills/research-protocol/` | ✅ Kept | Same |
| 5-phase AAPEV pattern | ❌ Removed | Superpowers's phase model |
| Confidence levels in CLAUDE.md | ❌ Removed | Superpowers's "evidence over claims" |
| All 11 hooks | ✅ Kept | Same |
| `rules/python.md`, `rules/typescript.md` | ✅ Kept | Same |
| All 4 agents | ✅ Kept | Same |
| `commands/agent.md` | ❌ Removed | Superpowers covers agent dispatch |
| `commands/docs.md`, `commands/review.md` | ✅ Kept | Same |
| CLAUDE.md (~400 lines) | ⚠️ Slimmed | New ~40-line kernel |
| README (operating-system framing) | ⚠️ Rewritten | "Companion to Superpowers" framing |

## Migration steps

```sh
# 1. Back up your current Claude Code config
cp -R ~/.claude ~/.claude.pre-companion.bak

# 2. Install Superpowers if you haven't already
#    (Claude Code: /plugin install superpowers@claude-plugins-official)

# 3. Clone the new companion repo
git clone https://github.com/mueslipolo/claude-code-companion.git
cd claude-code-companion

# 4. Run the installer (it verifies Superpowers is present)
./install.sh

# 5. Diff your old CLAUDE.md to recover any *truly* project-specific lines
diff ~/.claude.pre-companion.bak/CLAUDE.md ~/.claude/CLAUDE.md
```

When you diff your old CLAUDE.md, the recovery rule is:

- **Keep**: anything about your specific toolchain, team conventions,
  project paths, custom commands.
- **Drop**: anything about how Claude should *think* (planning, debugging,
  verifying, calibrating confidence). Superpowers or the model defaults
  handle those now.

## What about the old GitHub repo?

You have three options:

1. **Recommended**: Archive `claude-code-blueprint` on GitHub with a README
   note pointing at `claude-code-companion`. This preserves history without
   continuing to maintain it.

2. Delete the old repo. Faster but loses the redirect.

3. Keep both, with the old one clearly marked "deprecated, see
   claude-code-companion." This is fine if you want time to land the
   companion before retiring the old one.

There's no way to "un-fork" on GitHub — converting requires creating the
new repo from scratch (which is what this companion is).
