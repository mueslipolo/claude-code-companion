#!/usr/bin/env bash
# strip-plan-leakage.sh — PostToolUse hook
#
# Strips meta-comments about the planning/execution process from files
# Claude just wrote. Logs every strip to a sidecar so you can audit
# whether the upstream CLAUDE.md rule is doing its job.
#
# What it strips:
#   - Comment-only lines that reference the planning machinery
#       (plan, step N, phase N, task #N, subagent, "as per the plan",
#        "per the spec above", "as outlined", etc.)
#   - Inline `Step N: ` / `Phase N: ` prefixes inside otherwise-keepable
#     comments (the prefix goes, the rest stays)
#   - Markdown prose lines that are pure plan-narration
#   - Commit message lines (when the file is COMMIT_EDITMSG)
#
# What it does NOT strip:
#   - Real explanatory comments
#   - TODO/FIXME/NOTE tags (only the "from plan" part)
#   - Code itself
#
# Wired in settings.json:
#   "PostToolUse": [
#     { "match": "Write", "command": "hooks/scripts/strip-plan-leakage.sh" },
#     { "match": "Edit",  "command": "hooks/scripts/strip-plan-leakage.sh" }
#   ]

set -u  # but NOT -e: never break the session

# ---------------------------------------------------------------------------
# Parse the event
# ---------------------------------------------------------------------------

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

event="$(cat)"
file_path="$(echo "$event" | jq -r '.tool_input.file_path // empty')"

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Log setup
# ---------------------------------------------------------------------------

log_dir="${CLAUDE_HOME:-$HOME/.claude}/logs"
log_file="$log_dir/plan-leakage.log"
mkdir -p "$log_dir" 2>/dev/null || exit 0
timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# ---------------------------------------------------------------------------
# Patterns — what counts as plan-leakage
# ---------------------------------------------------------------------------
#
# Built as one alternation so we can scan with a single grep -E.
# Word boundaries via [^A-Za-z0-9_] equivalents to keep it portable.
#
# Anchors that strongly indicate plan-narration:
#   - "step N" / "step N:" / "step N -"
#   - "phase N" / "phase N:"
#   - "task #N" / "task N of"
#   - "per the plan" / "per the spec" / "per the design"
#   - "as (outlined|described|specified) (above|in the plan)"
#   - "subagent" + (task|step|run)
#   - "as we (planned|discussed|specified)"
#   - "(implementation|execution) plan"
#   - "plan (task|step) #?N"

PLAN_PATTERNS='(\bstep[[:space:]]+[0-9]+\b|\bphase[[:space:]]+[0-9]+\b|\btask[[:space:]]+#?[0-9]+\b|\bper[[:space:]]+the[[:space:]]+(plan|spec|design)\b|\bas[[:space:]]+(outlined|described|specified)[[:space:]]+(above|in[[:space:]]+the[[:space:]]+plan)\b|\bsubagent\b|\b(implementation|execution)[[:space:]]+plan\b|\bas[[:space:]]+we[[:space:]]+(planned|discussed|specified)\b|\bfrom[[:space:]]+the[[:space:]]+plan\b)'

# ---------------------------------------------------------------------------
# Strip strategy by file type
# ---------------------------------------------------------------------------

tmp_file="$(mktemp)" || exit 0
trap 'rm -f "$tmp_file"' EXIT

strip_count=0

# We process line by line in Python (more reliable than sed chains for
# multi-pattern conditional logic). Python is universally available; if
# it's not, we degrade to a no-op rather than risking corruption.
if ! command -v python3 >/dev/null 2>&1; then
  exit 0
fi

python3 - "$file_path" "$tmp_file" "$log_file" "$timestamp" <<'PYEOF'
import os
import re
import sys

src_path, dst_path, log_path, ts = sys.argv[1:5]

# Compile patterns once.
PLAN_RE = re.compile(
    r"("
    r"\bstep\s+\d+\b"
    r"|\bphase\s+\d+\b"
    r"|\btask\s+#?\d+\b"
    r"|\bper\s+the\s+(plan|spec|design)\b"
    r"|\bas\s+(outlined|described|specified)\s+(above|in\s+the\s+plan)\b"
    r"|\bsubagent\b"
    r"|\b(implementation|execution)\s+plan\b"
    r"|\bas\s+we\s+(planned|discussed|specified)\b"
    r"|\b(from|per)\s+(the\s+)?plan\b"
    r")",
    re.IGNORECASE,
)

# Comment-only line markers across common languages.
# Group 1 captures the comment prefix (whitespace + marker + optional space).
COMMENT_LINE = re.compile(
    r"^(\s*(?://|#|--|;|/\*|\*)\s?)(.*?)(\s*\*/)?\s*$"
)

# Markdown: detect prose-ish lines (not code blocks, not headings, not lists
# that are part of structured content). We deliberately keep this narrow.
MD_PROSE = re.compile(r"^\s*[A-Za-z(]")

# Inline "Step N: " / "Phase N: " prefix to strip while keeping the rest.
INLINE_PREFIX = re.compile(
    r"^(Step|Phase)\s+\d+\s*[:\-\u2014]\s*",
    re.IGNORECASE,
)

# "from plan" / "from the plan" inside TODO/FIXME tags — strip just the trailer.
TODO_TRAILER = re.compile(
    r"\s*(\(|\[)?\s*(from|per)\s+(the\s+)?plan\s*(\)|\])?",
    re.IGNORECASE,
)

filename = os.path.basename(src_path).lower()
is_markdown = filename.endswith((".md", ".mdx", ".markdown"))
is_commit_msg = filename in ("commit_editmsg", "merge_msg", "squash_msg")

strip_log = []

def log_strip(line_no, original):
    strip_log.append(f"{ts}\t{src_path}\t{line_no}\t{original.rstrip()}")

with open(src_path, "r", encoding="utf-8", errors="replace") as f:
    lines = f.readlines()

in_code_fence = False
out_lines = []
for i, line in enumerate(lines, start=1):
    # Track fenced code blocks in markdown so we treat code content as code,
    # not as prose. (Plan-leakage in fenced code is comment-leakage, which
    # the comment branch handles.)
    if is_markdown and line.lstrip().startswith("```"):
        in_code_fence = not in_code_fence
        out_lines.append(line)
        continue

    # --- Commit messages ---------------------------------------------------
    # Whole-line strip if the line is pure plan-narration.
    if is_commit_msg:
        if PLAN_RE.search(line) and not line.startswith("#"):
            log_strip(i, line)
            continue  # drop the line entirely
        out_lines.append(line)
        continue

    # --- Markdown prose (outside code fences) ------------------------------
    if is_markdown and not in_code_fence:
        if MD_PROSE.match(line) and PLAN_RE.search(line):
            # Heuristic: if the line is *dominated* by plan-narration
            # (the plan reference is its main subject), drop it. Otherwise
            # leave it — we don't want to nuke a sentence that just happens
            # to mention "step 1" in passing.
            #
            # Dominant = plan pattern occurs in first half of the line OR
            # the line is short (< 80 chars).
            m = PLAN_RE.search(line)
            if m and (m.start() < len(line) / 2 or len(line.strip()) < 80):
                log_strip(i, line)
                continue
        out_lines.append(line)
        continue

    # --- Code (or fenced code in markdown) ---------------------------------
    cm = COMMENT_LINE.match(line)
    if cm:
        prefix, body, trailer = cm.group(1), cm.group(2), cm.group(3) or ""

        # Strip "Step N: " / "Phase N: " prefix, keep the rest.
        new_body, n = INLINE_PREFIX.subn("", body)
        if n > 0 and new_body.strip():
            log_strip(i, line)
            out_lines.append(f"{prefix}{new_body}{trailer}\n")
            continue

        # Whole-comment-line strip if the body is dominated by plan-talk.
        if PLAN_RE.search(body):
            # Preserve TODO/FIXME/NOTE tags — only strip the plan trailer.
            tag_match = re.match(r"^(TODO|FIXME|NOTE|XXX|HACK)\b", body, re.IGNORECASE)
            if tag_match:
                cleaned = TODO_TRAILER.sub("", body).rstrip()
                if cleaned != body.rstrip():
                    log_strip(i, line)
                    out_lines.append(f"{prefix}{cleaned}{trailer}\n")
                    continue
            else:
                # Pure plan-comment — drop the whole line.
                log_strip(i, line)
                continue

    out_lines.append(line)

# Write the cleaned file back atomically.
with open(dst_path, "w", encoding="utf-8") as f:
    f.writelines(out_lines)

# Append to the log if we changed anything.
if strip_log:
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    with open(log_path, "a", encoding="utf-8") as lf:
        for entry in strip_log:
            lf.write(entry + "\n")

# Emit count for the shell wrapper to read.
print(len(strip_log))
PYEOF

# Replace the original only if we actually changed something.
if [ -s "$tmp_file" ] && ! cmp -s "$file_path" "$tmp_file"; then
  cp "$tmp_file" "$file_path"
fi

exit 0
