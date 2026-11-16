#!/usr/bin/env bash
# Run the skill scripts against fixtures. The scope repo fixture is built from the examples in
# docs/schema.md, so the schema and the scripts can't drift apart.
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
check="$here/skills/lore/scripts/check.sh"
routing="$here/skills/lore/scripts/routing.sh"
collab="$here/skills/lore-collab/scripts/collab.sh"
schema="$here/docs/schema.md"

tmp=$(mktemp -d)
trap '[[ -n $tmp && -d $tmp ]] && rm -rf -- "$tmp"' EXIT

failures=0
pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; failures=$((failures + 1)); }
expect() { # expect <name> <command…>: the command succeeds
	local name=$1
	shift
	if "$@" >"$tmp/out" 2>&1; then pass "$name"; else fail "$name"; sed 's/^/     /' "$tmp/out"; fi
}
refuse() { # refuse <name> <command…>: the command fails
	local name=$1
	shift
	if "$@" >"$tmp/out" 2>&1; then fail "$name"; sed 's/^/     /' "$tmp/out"; else pass "$name"; fi
}
contains() { # contains <name> <file> <text>
	[[ -f $2 ]] || { fail "$1 (no file $2)"; return; }
	if grep -qF -- "$3" "$2"; then pass "$1"; else fail "$1"; sed 's/^/     /' "$2"; fi
}
lacks() { # lacks <name> <file> <text>
	[[ -f $2 ]] || { fail "$1 (no file $2)"; return; }
	if grep -qF -- "$3" "$2"; then fail "$1"; sed 's/^/     /' "$2"; else pass "$1"; fi
}

# The n-th ```yaml block in the schema.
yaml_block() { awk -v n="$1" '/^```yaml$/ { i++; on = (i == n); next } /^```$/ { on = 0 } on' "$schema"; }

# --- A scope repo built from the schema ---------------------------------------------------

root="$tmp/lore"
work="$root/work"
mkdir -p "$work/projects/widget-app" "$work/skills/sync" "$work/repos"
{
	echo "---"
	yaml_block 1
	echo "---"
	echo
	echo "# Lore: work"
	echo
	echo "A fixture scope."
	# The required sections, as the schema lists them: - `## <name>`: …
	sed -n 's/^- `\(## [^`]*\)`:.*/\1/p' "$schema" | while read -r heading; do
		printf '\n%s\n\nFixture text.\n' "$heading"
	done
} >"$work/readme.md"
{
	echo "---"
	yaml_block 2
	echo "---"
	echo
	echo "Notes: none."
} >"$work/repos/widget-app.md"
echo "# widget-app" >"$work/projects/widget-app/readme.md"
echo "# sync" >"$work/skills/sync/SKILL.md"

expect "check.sh accepts a scope repo built from the schema" "$check" "$work"

"$routing" --root "$root" >"$tmp/routing.md"
contains "routing.sh lists the scope" "$tmp/routing.md" '- **`work/`**: Everything for the widget-app employer.'
contains "routing.sh lists its machines" "$tmp/routing.md" "  - Cloned on: work machines only"
expect "routing.sh --write writes a complete root" "$routing" --root "$root" --write
contains "the written routing file lists the scope" "$root/readme.md" '- **`work/`**'

# --- A scope without frontmatter ----------------------------------------------------------

home="$root/home"
mkdir -p "$home/projects" "$home/skills"
printf '# Lore: home\n\n## Never put here\n\n## Layout\n\n## Status\n' >"$home/readme.md"
cp "$root/readme.md" "$tmp/routing-before.md"

refuse "routing.sh --write refuses a scope without frontmatter" "$routing" --root "$root" --write
expect "and leaves the routing file as it was" cmp "$tmp/routing-before.md" "$root/readme.md"
"$routing" --root "$root" >"$tmp/routing.md" 2>"$tmp/warnings"
contains "routing.sh names the missing field" "$tmp/warnings" 'home: readme.md frontmatter has no "scope"'
lacks "routing.sh leaves the scope out" "$tmp/routing.md" 'home/'
refuse "check.sh rejects a readme without frontmatter" "$check" "$home"

# --- Top-level tooling and upstream pages -------------------------------------------------

mkdir "$work/bin"
refuse "check.sh rejects a top-level bin/" "$check" "$work"
contains "and says where tooling goes" "$tmp/out" "skills/<name>/"
rmdir "$work/bin"
printf -- '---\nrepo: example-lore/widget-app\n---\n' >"$work/repos/broken.md"
refuse "check.sh rejects an upstream page without upstream and local" "$check" "$work"
contains "and names the missing field" "$tmp/out" "frontmatter has no 'upstream'"

# --- lore-collab --------------------------------------------------------------------------

# A plain folder, not a git repo, so posting writes the log without committing.
log="$tmp/collab/demo"
"$collab" start "$log" design >/dev/null
first=$("$collab" post "$log" kit Opening --waiting rook <<'EOF'
An example section, fenced, which must not count:

```markdown
## [ab12] Fake — 2026-01-01 (rook)
**Ack (rook):** zzzz
Waiting on: kit
```
EOF
)
printf '\n## [cd34] Half written — 2026-01-01 (rook)\n\nWaiting on: kit\n\nText after the footer.\n' \
	>>"$("$collab" current "$log")"

"$collab" waiting "$log" rook >"$tmp/out"
contains "collab.sh: a section waits on its recipient" "$tmp/out" "$first"
"$collab" waiting "$log" kit >"$tmp/out"
lacks "collab.sh: a fenced footer waits on nobody" "$tmp/out" "ab12"
lacks "collab.sh: a section without a final footer waits on nobody" "$tmp/out" "cd34"
"$collab" unread "$log" kit >"$tmp/out"
contains "collab.sh: that section is still unread" "$tmp/out" "cd34"

"$collab" post "$log" rook Reply --ack "$first" --waiting kit </dev/null >/dev/null
"$collab" unread "$log" rook >"$tmp/out"
lacks "collab.sh: an ack marks a section read" "$tmp/out" "$first"
expect "collab.sh: wait returns at once when a section is waiting" \
	"$collab" wait "$log" kit --interval 1 --then -- true
refuse "collab.sh: wait reports a failing wake-up" "$collab" wait "$log" kit --interval 1 --then -- false

echo
if [[ $failures -eq 0 ]]; then echo "all tests passed"; else echo "$failures failed" && exit 1; fi
