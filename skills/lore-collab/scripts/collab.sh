#!/usr/bin/env bash
# lore-collab: a shared, append-only log between agent sessions.
#
# A collaboration is a folder of logs, one per phase: 01-<topic>.md, 02-<topic>.md, ...
# Sections look like "## [a1b2] <topic> — <date> (<name>)" and end with "Waiting on: <names>".
# Acks look like "**Ack (<name>):** a1b2, c3d4".
set -euo pipefail

usage() {
	cat <<'EOF'
usage: collab.sh <command> <folder> [args]

  start <folder> <topic>                 create the folder and its first log; prints its path
  post <folder> <name> <topic> [options] append a section; the body is read from stdin
      --ack <id,id>                      ids this section acknowledges
      --waiting <name,name>              who acts next (default: nobody)
      --no-push                          commit, but don't push
  unread <folder> <name>                 sections by others that <name> hasn't acked
  waiting <folder> <name>                unread sections that wait on <name>
  wait <folder> <name> [--interval <seconds>] [--repeat] [--then -- <command> [args]]
                                         block until a section waits on <name>, print it,
                                         run <command> if given, then exit; with --repeat,
                                         keep watching and fire once per new batch
  next <folder> <name> <topic>           close this phase and start the next log
  close <folder> <name>                  end the collaboration
  current <folder>                       print the newest log's path
EOF
	exit 2
}

die() {
	echo "collab.sh: $*" >&2
	exit 1
}

slug() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//'; }

# The phase logs, oldest first, into the array "logs". Globs keep paths with spaces whole.
list_logs() {
	shopt -s nullglob
	logs=("$1"/[0-9][0-9]-*.md)
	shopt -u nullglob
}

current() {
	local logs
	list_logs "$1"
	[[ ${#logs[@]} -gt 0 ]] || die "no log in $1; run start first"
	printf '%s\n' "${logs[${#logs[@]}-1]}"
}

# Shared by the parsers below: fenced code is never read as log structure, so an example
# section inside a fence is not a section. Fences follow CommonMark: an opener is three or
# more backticks or tildes, indented up to three spaces, and only a run of the same character
# at least as long, with nothing after it, closes it. A fence left open runs to the end of the
# file, so the section it is in has no footer. (No regex intervals: mawk lacks them.)
fence_awk='
	FNR == 1 { fence = 0 }
	{
		in_fence_line = 0
		s = $0
		indent = 0
		while (indent < 4 && substr(s, 1, 1) == " ") { s = substr(s, 2); indent++ }
		c = substr(s, 1, 1)
		run = 0
		if (indent < 4 && (c == "`" || c == "~")) {
			while (substr(s, run + 1, 1) == c) run++
		}
		if (run >= 3) {
			rest = substr(s, run + 1)
			if (!fence) {
				# A backtick opener cannot have a backtick in its info string.
				if (!(c == "`" && index(rest, "`"))) {
					fence = 1; fence_char = c; fence_len = run; in_fence_line = 1
				}
			} else if (c == fence_char && run >= fence_len && rest ~ /^[ \t]*$/) {
				fence = 0; in_fence_line = 1
			}
		}
	}
'

# One line per section, across every phase: id<TAB>author<TAB>waiting<TAB>heading.
# "waiting" is empty unless the section ends with a real "Waiting on:" footer, so a section
# that is incomplete, or only quotes a footer inside a fence, waits on nobody.
sections() {
	local logs
	list_logs "$1"
	[[ ${#logs[@]} -gt 0 ]] || return 0
	awk "$fence_awk"'
		function flush() {
			if (id != "") print id "\t" author "\t" (footer ? waiting : "") "\t" heading
			id = ""; waiting = ""; footer = 0
		}
		FNR == 1 { flush() }
		in_fence_line || fence { if (id != "") footer = 0; next }
		/^## \[[a-z0-9][a-z0-9][a-z0-9][a-z0-9]\] / {
			flush()
			id = substr($2, 2, 4)
			heading = substr($0, 4)
			author = heading
			sub(/.*\(/, "", author); sub(/\).*/, "", author); sub(/,.*/, "", author)
			next
		}
		/^Waiting on: / { waiting = substr($0, 13); footer = 1; next }
		NF { footer = 0 }
		END { flush() }
	' "${logs[@]}"
}

# Ids that <name> has acked, or posted itself.
seen() {
	local folder=$1 name=$2 logs
	list_logs "$folder"
	[[ ${#logs[@]} -gt 0 ]] || return 0
	awk -v name="$name" "$fence_awk"'
		in_fence_line || fence { next }
		index($0, "**Ack (" name ")") == 1 || index($0, "**Ack (" name ",") == 1 {
			line = $0; sub(/^[^:]*:\*\* */, "", line)
			n = split(line, ids, /[^a-z0-9]+/)
			for (i = 1; i <= n; i++) if (length(ids[i]) == 4) print ids[i]
		}
	' "${logs[@]}"
	sections "$folder" | awk -F '\t' -v name="$name" '$2 == name { print $1 }'
}

unread() {
	local folder=$1 name=$2 seen_ids
	seen_ids=$(seen "$folder" "$name" | sort -u | tr '\n' ',')
	sections "$folder" | awk -F '\t' -v seen="$seen_ids" '
		BEGIN { n = split(seen, s, ","); for (i = 1; i <= n; i++) done[s[i]] = 1 }
		!($1 in done) { print }
	'
}

waiting() {
	local folder=$1 name=$2
	unread "$folder" "$name" | awk -F '\t' -v name="$name" '
		{
			n = split($3, who, /, */)
			for (i = 1; i <= n; i++) if (who[i] == name) { print; next }
		}
	'
}

new_id() {
	local folder=$1 id
	for _ in 1 2 3 4 5 6 7 8; do
		id=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 4)
		if ! sections "$folder" | cut -f1 | grep -qx "$id"; then
			printf '%s\n' "$id"
			return
		fi
	done
	die "could not find a free id"
}

save() {
	local file=$1 message=$2 push=$3 root
	root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null) || return 0
	git -C "$root" add -- "$file"
	git -C "$root" commit -q -m "$message" -- "$file"
	[[ $push == yes ]] || return 0
	for _ in 1 2 3; do
		if git -C "$root" push -q 2>/dev/null; then return 0; fi
		if ! git -C "$root" pull -q --rebase --autostash; then
			git -C "$root" rebase --abort 2>/dev/null || true
			die "pull --rebase conflicted in $root; the commit is local, resolve it by hand, then push"
		fi
	done
	die "push failed in $root"
}

append() {
	local folder=$1 name=$2 topic=$3 acks=$4 waiting_on=$5 push=$6 body=$7 file id
	file=$(current "$folder")
	id=$(new_id "$folder")
	{
		printf '\n## [%s] %s — %s (%s)\n\n' "$id" "$topic" "$(date +%F)" "$name"
		[[ -n $acks ]] && printf '**Ack (%s):** %s\n\n' "$name" "${acks//,/, }"
		[[ -n $body ]] && printf '%s\n\n' "$body"
		printf 'Waiting on: %s\n' "${waiting_on:-nobody}"
	} >>"$file"
	save "$file" "docs(collab): $topic" "$push"
	printf '%s\n' "$id"
}

start_log() {
	local folder=$1 topic=$2 number=$3 file
	file="$folder/$number-$(slug "$topic").md"
	[[ -e $file ]] && die "$file already exists"
	mkdir -p "$folder"
	printf '# %s: %s\n' "$(basename "$folder")" "$topic" >"$file"
	printf '%s\n' "$file"
}

[[ $# -ge 2 ]] || usage
command=$1 folder=${2%/}
shift 2

case $command in
start)
	[[ $# -eq 1 ]] || usage
	list_logs "$folder"
	[[ ${#logs[@]} -eq 0 ]] || die "$folder already has a log"
	file=$(start_log "$folder" "$1" 01)
	save "$file" "docs(collab): start $(basename "$folder")" no
	printf '%s\n' "$file"
	;;
post)
	[[ $# -ge 2 ]] || usage
	name=$1 topic=$2 acks="" waiting_on="" push=yes
	shift 2
	while [[ $# -gt 0 ]]; do
		case $1 in
		--ack) acks=$2; shift 2 ;;
		--waiting) waiting_on=$2; shift 2 ;;
		--no-push) push=no; shift ;;
		*) usage ;;
		esac
	done
	body=""
	[[ -t 0 ]] || body=$(cat)
	append "$folder" "$name" "$topic" "$acks" "$waiting_on" "$push" "$body"
	;;
unread)
	[[ $# -eq 1 ]] || usage
	unread "$folder" "$1"
	;;
waiting)
	[[ $# -eq 1 ]] || usage
	waiting "$folder" "$1"
	;;
wait)
	[[ $# -ge 1 ]] || usage
	name=$1 interval=5 repeat=no then=()
	shift
	while [[ $# -gt 0 ]]; do
		case $1 in
		--interval) interval=$2; shift 2 ;;
		--repeat) repeat=yes; shift ;;
		--then)
			shift
			[[ ${1:-} == -- ]] && shift
			[[ $# -gt 0 ]] || usage
			then=("$@")
			break
			;;
		*) usage ;;
		esac
	done
	# The first scan runs at once, so sections that arrived before arming are found. "fired"
	# holds ids already sent and still unacked, so --repeat never sends the same batch twice.
	fired=" "
	while true; do
		found=$(waiting "$folder" "$name")
		kept=" " fresh=""
		while IFS=$'\t' read -r id _; do
			[[ -n $id ]] || continue
			if [[ $fired == *" $id "* ]]; then kept+="$id "; else fresh+="$id "; fi
		done <<<"$found"
		if [[ -n $fresh ]]; then
			awk -F '\t' -v fresh=" $fresh" 'index(fresh, " " $1 " ")' <<<"$found"
			if [[ ${#then[@]} -gt 0 ]]; then
				"${then[@]}" || die "the --then command failed (exit $?); the sections above are still unread"
			fi
			[[ $repeat == yes ]] || exit 0
		fi
		fired="$kept$fresh"
		sleep "$interval"
	done
	;;
next)
	[[ $# -eq 2 ]] || usage
	name=$1 topic=$2
	old=$(current "$folder")
	number=$(printf '%02d' $((10#$(basename "$old" | cut -c1-2) + 1)))
	file="$folder/$number-$(slug "$topic").md"
	append "$folder" "$name" "Phase closed" "" "" no "Continued in [$(basename "$file")]($(basename "$file"))." >/dev/null
	start_log "$folder" "$topic" "$number" >/dev/null
	printf '\nContinued from [%s](%s).\n' "$(basename "$old")" "$(basename "$old")" >>"$file"
	save "$file" "docs(collab): next phase $topic" yes
	printf '%s\n' "$file"
	;;
close)
	[[ $# -eq 1 ]] || usage
	append "$folder" "$1" "Collaboration closed" "" "" yes "This collaboration is closed."
	;;
current)
	current "$folder"
	;;
*) usage ;;
esac
