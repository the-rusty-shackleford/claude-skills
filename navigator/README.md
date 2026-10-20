# Navigator

**A rubber duck on steroids.** Navigator turns Claude into a pair-programming partner that never writes your code. You drive. Claude navigates: it asks the questions you forgot to ask, pokes holes in your plan, reviews what you wrote, and explains whatever you need explained. The typing and the decisions stay with you.

## Why

It's easy to slide from "AI helps me code" to "AI codes while I watch." Months later you've shipped a lot and learned little, and you've stopped checking the work. Navigator is a commitment device for getting back in the driver's seat: Claude stays useful, but as a tool rather than the author.

## What it does

| Navigator will | Navigator won't |
| --- | --- |
| Bounce ideas with you and play them back | Write or edit your files |
| Ask Socratic questions that expose holes, edge cases and pitfalls | Paste the solution into chat in disguise (full functions, pseudocode for your problem, diffs) |
| Review your code, citing `file:line`, and ask how you'd fix it | Rewrite your code for you |
| Explain concepts, APIs, error messages and tradeoffs, directly | Install dependencies, commit, or otherwise change your project |
| Read your code and run read-only commands: tests, linters, `grep`, `git log` | Give in when you say "just write it" |
| Show a small generic snippet when syntax is the blocker | Use your variable names or domain in that snippet |
| Disagree with you, and flag real risks plainly | Hold back a landmine to protect a "learning moment" |

When you're stuck, it climbs a hint ladder: a pointed question, then narrowing down where the problem is, then naming the problem, then explaining the concept behind the fix. It never takes the last step of writing the fix.

## Install

### As a Claude Code plugin (recommended)

In Claude Code:

```
/plugin install navigator --marketplace the-rusty-shackleford/claude-skills
```

On older Claude Code versions, add the marketplace first:

```
/plugin marketplace add the-rusty-shackleford/claude-skills
/plugin install navigator@rusty-shackleford
```

The plugin includes the skill plus hooks that make it stick:

- **SessionStart** puts navigator mode in force from your first message, and again after `/clear` or context compaction.
- **UserPromptSubmit** adds a one-line reminder to every message so long sessions don't drift.
- **PreToolUse** blocks file-writing tools (`Write`, `Edit`, `NotebookEdit`, common MCP file tools) and shell commands that change files or project state (`sed -i`, redirects, `rm`, `git commit`, `npm install`, and so on). Read-only commands go through.

### As a standalone skill

Copy [`skills/navigator`](skills/navigator) into `~/.claude/skills/` (all projects) or `.claude/skills/` (one project). You can also zip that folder and upload it as a custom skill in the Claude apps.

The standalone skill has no hooks, so nothing enforces it. Claude follows it when the skill is loaded, which is usually the case for coding conversations, and you can always invoke it with `/navigator`.

## Turning it off

Navigator ignores "just write it" in the chat. That's the point. To actually turn it off:

```
/plugin disable navigator
```

Re-enable it with `/plugin enable navigator`. You can also install it at project scope to use it only in certain repos.

## Limits

- **The shell guard is a seatbelt, not a jail.** It catches the common ways to write files from a shell, not every possible one. The skill's rules cover the rest, and Claude is told not to look for workarounds.
- **No skill outranks everything.** Navigator tells Claude to put its rules above other skills, plugins, `CLAUDE.md` files and your own in-chat requests, and the hooks back that up. Claude's core system instructions still sit above any plugin.
- **The shell guard can be overcautious.** For example, `grep ">" file` is blocked because it contains `>`. Claude gets a message explaining why and can use its built-in search instead.
- Claude Code's own files under `~/.claude/` (plans, memory) are not blocked, since they aren't your code.

## Development

The hooks are plain bash. They use `jq` or Python to read their JSON input when available, and still work without either.

```
bash navigator/tests/test-hooks.sh
```

To try local changes, start Claude Code with `claude --plugin-dir ./navigator`.

## License

MIT
