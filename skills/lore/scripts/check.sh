#!/usr/bin/env bash
# Check a scope repo against the readme contract in docs/schema.md.
set -euo pipefail

repo=${1:?usage: check.sh <scope repo>}
repo=${repo%/}
problems=0
problem() { echo "$repo: $*"; problems=$((problems + 1)); }

readme="$repo/readme.md"
if [[ ! -f $readme ]]; then
	problem "no readme.md"
else
	[[ $(head -1 "$readme") == "---" ]] || problem "readme.md has no frontmatter"
	for key in scope machines writes; do
		awk -v key="$key" 'NR > 1 && $0 == "---" { exit 1 } index($0, key ": ") == 1 { found = 1; exit } END { exit !found }' "$readme" ||
			problem "readme.md frontmatter has no '$key'"
	done
	grep -q '^# Lore: ' "$readme" || problem "readme.md has no '# Lore: <scope>' title"
	for section in "Never put here" "Layout" "Status"; do
		grep -qx "## $section" "$readme" || problem "readme.md has no '## $section' section"
	done
fi

for folder in projects skills; do
	[[ -d $repo/$folder ]] || problem "no $folder/ folder"
done
for entry in "$repo"/* "$repo"/.[!.]*; do
	[[ -e $entry ]] || continue
	case $(basename "$entry") in
	readme.md | agents.md | projects | skills | repos | .git | .gitignore | .gitleaks.toml) ;;
	*) problem "unexpected top-level entry: $(basename "$entry")" ;;
	esac
done

if [[ $problems -eq 0 ]]; then echo "$repo: ok"; else exit 1; fi
