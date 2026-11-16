#!/usr/bin/env bash
# Syntax-check every skill script. Biome doesn't read bash.
set -euo pipefail
status=0
for script in skills/*/scripts/*.sh scripts/*.sh; do
	bash -n "$script" || status=1
done
exit "$status"
