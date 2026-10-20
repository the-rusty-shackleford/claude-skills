#!/usr/bin/env bash
# PreToolUse hook for shell tools (Bash, PowerShell). Lets read-only commands
# through (tests, grep, git log, running the program) and blocks ones that
# change files or project state.
#
# This is a seatbelt, not a jail: it catches the common ways of writing
# files from a shell, not every possible one. The skill's rules do the rest.

source "$(dirname "$0")/lib.sh"

input="$(cat)"
cmd="$(json_field "$input" '.tool_input.command')"
[ -z "$cmd" ] && exit 0

# Start of a command: line start, or after ; & | ( or $(, plus optional sudo.
S='(^|[;&|(]|\$\()[[:space:]]*(sudo[[:space:]]+)?'
E='([[:space:]]|$)'

deny() {
  block "Navigator mode: blocked a shell command that would change files or project state ($1).
Read-only commands are fine: tests, linters, grep, git log/diff/show, running the program.
Leave edits, installs and git changes to the user. Tell them what you'd check or change and why.
(To switch navigator mode off, the user disables the plugin: /plugin disable navigator)"
}

matches() { printf '%s' "$cmd" | grep -Eq -- "$1"; }

# In-place editors.
matches "${S}(sed|perl|ruby)[[:space:]][^|;&]*-[a-zA-Z]*i" && deny "in-place edit"

# Output redirection to a file. Drop harmless forms first: fd duplication
# (2>&1), /dev/null and friends, and arrow-like text (->, =>, >=).
stripped="$(printf '%s' "$cmd" | sed -E \
  -e 's#[0-9]*>&[0-9-]+##g' \
  -e 's#&>>?[[:space:]]*/dev/(null|stdout|stderr|tty)##g' \
  -e 's#[0-9]*>>?[[:space:]]*/dev/(null|stdout|stderr|tty)##g' \
  -e 's#(->|=>|>=)##g')"
printf '%s' "$stripped" | grep -q '>' && deny "output redirection"

matches "${S}tee${E}" && deny "tee"
matches "${S}(rm|rmdir|mv|cp|touch|truncate|mkdir|ln|chmod|chown|dd|unlink|shred|patch)${E}" && deny "file operation"
matches "(-delete${E}|-exec[[:space:]]+(rm|mv|cp|sed)${E}|xargs[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(rm|mv|cp|sed)${E})" && deny "bulk file operation"

# Git commands that change the working tree, index, history or remote.
matches "git([[:space:]]+-[cC][[:space:]]+[^[:space:]]+)*[[:space:]]+(add|am|apply|checkout|cherry-pick|clean|commit|merge|mv|pull|push|rebase|reset|restore|revert|rm|stash|switch|tag)${E}" && deny "git change"

# Dependency changes.
matches "(npm|pnpm|yarn|bun|pip3?|poetry|uv|cargo|gem|composer|go)[[:space:]]+((pip|-[^[:space:]]+)[[:space:]]+)*(install|i|add|remove|rm|uninstall|update|upgrade|get)${E}" && deny "dependency change"

# Inline scripts that write or delete files.
matches "(writeFile|appendFile|unlinkSync|rmSync|write_text|write_bytes|shutil\.(copy|move|rmtree)|os\.(remove|unlink|rename|makedirs)|open\([^)]*['\"][wax]b?\+?['\"])" && deny "script that writes files"

# PowerShell equivalents.
matches "(Set-Content|Add-Content|Out-File|New-Item|Remove-Item|Move-Item|Copy-Item|Rename-Item|Clear-Content)" && deny "PowerShell file operation"

exit 0
