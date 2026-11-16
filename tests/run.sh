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
# Keep git from finding a repo above the temp folder, so no fixture is ever committed or
# pushed, wherever $TMPDIR is.
export GIT_CEILING_DIRECTORIES=$tmp

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

# The n-th ```yaml block in the schema, --- lines included.
yaml_block() { awk -v n="$1" '/^```yaml$/ { i++; on = (i == n); next } /^```$/ { on = 0 } on' "$schema"; }

# make_scope <dir> <name>: a scope repo built from the schema's examples.
make_scope() {
	local dir=$1 name=$2
	mkdir -p "$dir/projects/widget-app" "$dir/skills/sync" "$dir/repos"
	{
		yaml_block 1
		echo
		echo "# Lore: $name"
		echo
		echo "A fixture scope."
		# The required sections, as the schema lists them: - `## <name>`: …
		sed -n 's/^- `\(## [^`]*\)`:.*/\1/p' "$schema" | while read -r heading; do
			printf '\n%s\n\nFixture text.\n' "$heading"
		done
	} >"$dir/readme.md"
	{
		yaml_block 2
		echo
		echo "Notes: none."
	} >"$dir/repos/widget-app.md"
	echo "# widget-app" >"$dir/projects/widget-app/readme.md"
	echo "# sync" >"$dir/skills/sync/SKILL.md"
}

# A readme body with every required section, for the broken scopes below.
sections_only() { printf '\n# Lore: %s\n\n## Never put here\n\n## Layout\n\n## Status\n' "$1"; }

# --- A scope repo built from the schema ---------------------------------------------------

root="$tmp/lore"
work="$root/work"
make_scope "$work" work

expect "check.sh accepts a scope repo built from the schema" "$check" "$work"

"$routing" --root "$root" >"$tmp/routing.md"
contains "routing.sh lists the scope" "$tmp/routing.md" '- **`work/`**: Everything for the widget-app employer.'
contains "routing.sh lists its machines" "$tmp/routing.md" "  - Cloned on: work machines only"
expect "routing.sh --write writes a complete root" "$routing" --root "$root" --write
contains "the written routing file lists the scope" "$root/readme.md" '- **`work/`**'

# --- Scopes routing.sh must refuse --------------------------------------------------------

# broken_root <case> <expected warning> <name>: add one broken scope, <name>, to a copy of the
# good root, then check that --write refuses and keeps the old file, that the warning names
# the problem, and that printing leaves the broken scope out.
broken_root() {
	local case=$1 warning=$2 name=$3
	if "$routing" --root "$broken" --write >"$tmp/out" 2>&1; then
		fail "routing.sh --write refuses $case"
	else
		pass "routing.sh --write refuses $case"
	fi
	expect "  and leaves the routing file as it was" cmp "$tmp/routing-before.md" "$broken/readme.md"
	"$routing" --root "$broken" >"$tmp/routing.md" 2>"$tmp/warnings"
	contains "  and names the problem" "$tmp/warnings" "$warning"
	lacks "  and leaves the scope out" "$tmp/routing.md" "\`$name/\`"
}
new_broken_root() {
	broken="$tmp/broken-$1"
	cp -R "$root" "$broken"
	cp "$broken/readme.md" "$tmp/routing-before.md"
}

new_broken_root no-frontmatter
mkdir -p "$broken/home/projects" "$broken/home/skills"
sections_only home >"$broken/home/readme.md"
broken_root "a scope without frontmatter" 'home: readme.md has no frontmatter' home
refuse "check.sh rejects a readme without frontmatter" "$check" "$broken/home"

new_broken_root one-field
mkdir -p "$broken/home/projects" "$broken/home/skills"
{
	printf -- '---\nscope: The home scope.\nmachines: home machines\n---\n'
	sections_only home
} >"$broken/home/readme.md"
broken_root "a scope missing only writes" 'home: readme.md frontmatter has no "writes"' home
refuse "check.sh rejects a readme missing only writes" "$check" "$broken/home"

new_broken_root quoted
mkdir -p "$broken/home/projects" "$broken/home/skills"
{
	printf -- '---\nscope: "The home scope."\nmachines: home machines\nwrites: >\n  Folded text.\n---\n'
	sections_only home
} >"$broken/home/readme.md"
broken_root "a quoted value" 'home: readme.md frontmatter "scope" must be one plain line' home
contains "  and a block scalar" "$tmp/warnings" 'frontmatter "writes" must be one plain line'
refuse "check.sh rejects quoted and folded values" "$check" "$broken/home"

new_broken_root comment-only
mkdir -p "$broken/home/projects" "$broken/home/skills"
{
	printf -- '---\nscope: The home scope.\nmachines: home machines\nwrites: # TODO\n---\n'
	sections_only home
} >"$broken/home/readme.md"
broken_root "a comment-only value" 'home: readme.md frontmatter has no "writes"' home
refuse "check.sh rejects a comment-only value" "$check" "$broken/home"

new_broken_root continued
mkdir -p "$broken/home/projects" "$broken/home/skills"
{
	printf -- '---\nscope: The home scope.\nmachines: home machines\nwrites: Home projects\n  except shared ones.\n---\n'
	sections_only home
} >"$broken/home/readme.md"
broken_root "a value with a continuation line" 'home: readme.md frontmatter "writes" must be one plain line' home
refuse "check.sh rejects a continuation line" "$check" "$broken/home"

new_broken_root unclosed
mkdir -p "$broken/home/projects" "$broken/home/skills"
{
	printf -- '---\nscope: The home scope.\nmachines: home machines\nwrites: Home projects.\n'
	sections_only home
} >"$broken/home/readme.md"
broken_root "frontmatter without a closing ---" 'home: readme.md frontmatter has no closing ---' home
refuse "check.sh rejects frontmatter without a closing ---" "$check" "$broken/home"

new_broken_root no-readme
mkdir -p "$broken/home/projects" "$broken/home/skills"
broken_root "a scope folder without a readme" 'home: no readme.md' home

new_broken_root uppercase
mkdir -p "$broken/home/projects" "$broken/home/skills"
cp "$work/readme.md" "$broken/home/README.md"
broken_root "a readme named README.md" 'home: no readme.md (the name is lowercase)' home
refuse "check.sh rejects README.md, on any file system" "$check" "$broken/home"

# --- Top-level tooling and upstream pages -------------------------------------------------

mkdir "$work/bin"
refuse "check.sh rejects a top-level bin/" "$check" "$work"
contains "  and says where tooling goes" "$tmp/out" "skills/<name>/"
rmdir "$work/bin"

printf -- '---\nrepo: example-lore/widget-app\n---\n' >"$work/repos/broken.md"
refuse "check.sh rejects an upstream page without upstream and local" "$check" "$work"
contains "  and names the missing field" "$tmp/out" 'frontmatter has no "upstream"'
printf 'Notes: none.\n' >"$work/repos/broken.md"
refuse "check.sh rejects an upstream page without frontmatter" "$check" "$work"
contains "  and says so" "$tmp/out" "repos/broken.md has no frontmatter"
rm -- "$work/repos/broken.md"
expect "check.sh accepts the scope again once it's fixed" "$check" "$work"

# --- lore-collab --------------------------------------------------------------------------

# A plain folder, not a git repo, so posting writes the log without committing.
log="$tmp/collab/demo"
"$collab" start "$log" design >/dev/null
# The real section waits on kit too: a parser that read fenced lines would make the fake
# ab12 section (by rook) wait on kit, and the fence test below would fail.
first=$("$collab" post "$log" kit Opening --waiting rook,kit --no-push <<'EOF'
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

"$collab" post "$log" rook Reply --ack "$first" --waiting kit --no-push </dev/null >/dev/null
"$collab" unread "$log" rook >"$tmp/out"
lacks "collab.sh: an ack marks a section read" "$tmp/out" "$first"
expect "collab.sh: wait returns at once when a section is waiting" \
	"$collab" wait "$log" kit --interval 1 --then -- true
refuse "collab.sh: wait reports a failing wake-up" "$collab" wait "$log" kit --interval 1 --then -- false

echo
if [[ $failures -eq 0 ]]; then echo "all tests passed"; else echo "$failures failed" && exit 1; fi
