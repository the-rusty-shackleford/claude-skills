#!/usr/bin/env bash
# Tests for the navigator hooks. Run: bash navigator/tests/test-hooks.sh

HOOKS="$(cd "$(dirname "$0")/../hooks" && pwd)"
pass=0
fail=0

# json_string "text" -> text as a JSON string literal
json_string() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"
}

# check <expect: allow|block> <hook script> <json input> <label>
check() {
  local expect="$1" hook="$2" input="$3" label="$4" code got
  printf '%s' "$input" | bash "$HOOKS/$hook" >/dev/null 2>&1
  code=$?
  if [ "$code" -eq 2 ]; then got=block; elif [ "$code" -eq 0 ]; then got=allow; else got="error($code)"; fi
  if [ "$got" = "$expect" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL [$hook] expected $expect, got $got: $label"
  fi
}

bash_cmd() {
  check "$1" guard-bash.sh "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":$(json_string "$2")}}" "$2"
}

# Read-only commands: allowed.
for c in \
  'ls -la' \
  'cat src/main.py' \
  'grep -rn "TODO" src/' \
  'grep -i error log.txt' \
  'git status' \
  'git log --oneline -10' \
  'git diff HEAD~1' \
  'git show main:src/app.ts' \
  'git -C repo log' \
  'npm test' \
  'npm ci' \
  'pytest -x tests/ 2>&1 | tail -20' \
  'cargo test 2>/dev/null' \
  'go test ./... > /dev/null' \
  'node -e "console.log(1 >= 0)"' \
  "awk '\$3 >= 10' data.txt" \
  'find . -name "*.py" -type f' \
  'sed -n "1,20p" file.txt' \
  'python3 -c "import sys; print(sys.version)"' \
  'make lint' \
  'echo hi 2>&1'
do bash_cmd allow "$c"; done

# Commands that change files or state: blocked.
for c in \
  'sed -i "s/foo/bar/" file.txt' \
  'sed -E -i.bak "s/a/b/" f' \
  'perl -pi -e "s/a/b/" f' \
  'echo "x = 1" > config.py' \
  'cat >> notes.md <<EOF' \
  'printf data | tee out.txt' \
  'rm -rf build' \
  'sudo rm file' \
  'ls && mv a.py b.py' \
  'cp a b' \
  'touch new.py' \
  'mkdir src/new' \
  'patch -p1 < fix.diff' \
  'git apply fix.patch' \
  'git commit -m "wip"' \
  'git add .' \
  'git checkout -- file.py' \
  'git -C repo reset --hard' \
  'git stash' \
  'git push origin main' \
  'npm install lodash' \
  'pip install requests' \
  'uv pip install requests' \
  'cargo add serde' \
  'find . -name "*.pyc" -delete' \
  'find . -name x -exec rm {} \;' \
  'ls | xargs rm' \
  "python3 -c \"open('a.py','w').write('x')\"" \
  'node -e "require(\"fs\").writeFileSync(\"a.js\", \"\")"' \
  'Set-Content -Path a.txt -Value hi' \
  'Remove-Item a.txt'
do bash_cmd block "$c"; done

# File-writing tools: blocked, except Claude Code's own files under ~/.claude/.
check block block-edits.sh '{"tool_name":"Write","tool_input":{"file_path":"/repo/src/app.py","content":"x"}}' "Write to project"
check block block-edits.sh '{"tool_name":"Edit","tool_input":{"file_path":"/repo/a.ts","old_string":"a","new_string":"b"}}' "Edit project file"
check block block-edits.sh '{"tool_name":"NotebookEdit","tool_input":{"notebook_path":"/repo/n.ipynb"}}' "NotebookEdit"
check block block-edits.sh '{"tool_name":"mcp__github__create_or_update_file","tool_input":{"path":"a.py"}}' "MCP file write"
check allow block-edits.sh "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$HOME/.claude/plans/plan.md\"}}" "Write plan file"
check block block-edits.sh "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$HOME/.claude/../repo/a.py\"}}" "path escape via .."

# Context hooks print something and succeed.
for h in session-start.sh prompt-reminder.sh; do
  out="$(bash "$HOOKS/$h" </dev/null)"
  if [ $? -eq 0 ] && [ -n "$out" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $h printed nothing or errored"; fi
done

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
