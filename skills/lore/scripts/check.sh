#!/usr/bin/env bash
# Check a scope repo against the readme contract in the lore skill's schema.md.
set -euo pipefail

# shellcheck source=frontmatter.sh
source "$(dirname "${BASH_SOURCE[0]}")/frontmatter.sh"

# The schema version these skills follow. Bump it, with a migration in lore-setup's migrations.md, whenever
# existing scope repos have to change.
current_schema=1

if [[ ${1:-} == --schema ]]; then
	echo "$current_schema"
	exit 0
fi

repo=${1:?usage: check.sh <scope repo> | check.sh --schema}
repo=${repo%/}
problems=0
problem() { echo "$repo: $*"; problems=$((problems + 1)); }

# check_fields <file, relative to the repo> <key>…: one problem per unusable field, or one
# for a file with no frontmatter at all.
check_fields() {
	local file=$1 key why
	shift
	for key in "$@"; do
		why=$(frontmatter_problem "$repo/$file" "$key")
		if [[ -n $why ]]; then
			problem "$file $why"
			if [[ $why == "has no frontmatter" || $why == *"no closing ---" ]]; then return 0; fi
		fi
	done
}

if has_exact_file "$repo" readme.md; then
	check_fields readme.md scope machines writes schema
	schema=$(frontmatter_value "$repo/readme.md" schema 2>/dev/null || true)
	# A plain decimal with no leading zero and at most 9 digits, so bash compares it safely.
	if [[ -n $schema && ! $schema =~ ^(0|[1-9][0-9]{0,8})$ ]]; then
		problem "readme.md frontmatter \"schema\" must be a whole number like 1, not \"$schema\""
	elif [[ -n $schema ]] && ((schema < current_schema)); then
		problem "readme.md follows schema $schema, and these skills follow schema $current_schema: migrate it with the lore-setup skill"
	elif [[ -n $schema ]] && ((schema > current_schema)); then
		problem "readme.md follows schema $schema, newer than these skills (schema $current_schema): update them (https://github.com/merrywhether/lore#update)"
	fi
	grep -q '^# Lore: ' "$repo/readme.md" || problem "readme.md has no '# Lore: <scope>' title"
	for section in "Never put here" "Layout" "Status"; do
		grep -qx "## $section" "$repo/readme.md" || problem "readme.md has no '## $section' section"
	done
else
	problem "no readme.md (the name is lowercase)"
fi

for folder in projects skills; do
	[[ -d $repo/$folder ]] || problem "no $folder/ folder"
done
for entry in "$repo"/* "$repo"/.[!.]*; do
	[[ -e $entry ]] || continue
	case $(basename "$entry") in
	readme.md | agents.md | projects | skills | repos | .git | .gitignore | .gitleaks.toml) ;;
	*) problem "unexpected top-level entry: $(basename "$entry") (scripts, hooks and other tooling go in skills/<name>/)" ;;
	esac
done

for page in "$repo"/repos/*.md; do
	[[ -f $page ]] || continue
	check_fields "repos/$(basename "$page")" repo upstream local
done

if [[ $problems -eq 0 ]]; then echo "$repo: ok"; else exit 1; fi
