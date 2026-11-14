#!/usr/bin/env bash
# Shared helpers for navigator hooks.

# Print one field from the hook's JSON input (passed as $1).
# Usage: json_field "$input" '.tool_input.command'
# Tries jq, then python. If neither exists, prints the whole input so the
# guards still run against it (they may then block a little more than needed).
json_field() {
  local input="$1" path="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r "$path // empty" 2>/dev/null && return
  fi
  local py
  for py in python3 python; do
    if command -v "$py" >/dev/null 2>&1; then
      printf '%s' "$input" | "$py" -c '
import json, sys
d = json.load(sys.stdin)
for key in sys.argv[1].lstrip(".").split("."):
    d = d.get(key) if isinstance(d, dict) else None
print(d if isinstance(d, str) else "")
' "$path" 2>/dev/null && return
    fi
  done
  printf '%s' "$input"
}

# Block the tool call: exit code 2 tells Claude Code to stop it and show
# the message (stderr) to Claude.
block() {
  printf '%s\n' "$1" >&2
  exit 2
}
