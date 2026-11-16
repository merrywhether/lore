# The one reader of lore frontmatter, sourced by check.sh and routing.sh so the two
# scripts agree on what a valid field is.
#
# Frontmatter is the block between a first line of `---` and the next `---`. Each field is
# one plain `key: value` line. A trailing ` # comment` isn't part of the value.

# Prints the value of <key> in <file>'s frontmatter, or nothing when it's absent.
frontmatter_value() {
	awk -v key="$2" '
		NR == 1 { if ($0 != "---") exit; next }
		$0 == "---" { exit }
		index($0, key ":") == 1 {
			value = substr($0, length(key) + 2)
			sub(/^[ \t]+/, "", value)
			sub(/[ \t]+#.*$/, "", value)
			sub(/[ \t]+$/, "", value)
			print value
			exit
		}
	' "$1"
}

# Prints why <key> in <file> isn't usable, or nothing when it is. An empty value counts as
# missing. Quoted values and block scalars (`>`, `|`) are valid YAML, but the scripts read
# values as plain text, so the schema allows only plain one-line values.
frontmatter_problem() {
	local value
	if [[ $(head -1 "$1") != "---" ]]; then
		echo "has no frontmatter"
		return
	fi
	value=$(frontmatter_value "$1" "$2")
	if [[ -z $value ]]; then
		echo "frontmatter has no \"$2\""
	elif [[ $value == [\"\'\>\|]* ]]; then
		echo "frontmatter \"$2\" must be one plain line, without quotes or a block scalar (> or |)"
	fi
}

# True when <dir> holds a file named exactly <name>. A plain -f test also matches other
# cases on a case-insensitive file system (macOS), which Linux wouldn't.
has_exact_file() {
	[[ -f $1/$2 ]] && ls -1 "$1" | grep -qxF -- "$2"
}
