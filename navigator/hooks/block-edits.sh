#!/usr/bin/env bash
# PreToolUse hook for file-writing tools (Write, Edit, NotebookEdit, and
# common MCP file tools). Navigator never writes the user's files.
#
# One exception: Claude Code's own files under ~/.claude/ (plans, memory),
# which aren't the user's code.

source "$(dirname "$0")/lib.sh"

input="$(cat)"
path="$(json_field "$input" '.tool_input.file_path')"
[ -z "$path" ] && path="$(json_field "$input" '.tool_input.notebook_path')"

if [ -n "$HOME" ] && [ -n "$path" ]; then
  case "$path" in
    *..*) ;;  # no path tricks
    "$HOME/.claude/"*) exit 0 ;;
  esac
fi

block "Navigator mode: you don't write or edit the user's files. They're the driver.
Describe the change in words, point at the file and line, or ask a question that leads them to it.
(To switch navigator mode off, the user disables the plugin: /plugin disable navigator)"
