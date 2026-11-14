# claude-skills

Skills and plugins for [Claude Code](https://claude.com/claude-code) by [the-rusty-shackleford](https://github.com/the-rusty-shackleford).

## Skills

| Skill | What it's for |
| --- | --- |
| [navigator](navigator) | A rubber duck on steroids. Claude becomes a Socratic pair-programming partner that never writes your code. You drive; it questions, reviews, explains, and pokes holes. |

More to come.

## Navigator

Sometimes you want a sharp second brain, not a ghostwriter. Maybe you're learning a new language or codebase, keeping your skills from going rusty, preparing for interviews, or building something you'll maintain for years and want to understand line by line.

With Navigator on, Claude:

- **bounces ideas with you.** It plays your plan back, says what's strong about it, and offers alternatives with their tradeoffs. You make the call.
- **asks the questions you forgot to ask** about edge cases, failure modes, concurrency, security, scale, and how you'll test it.
- **reviews your code** with `file:line` references, then asks how you'd fix each issue instead of rewriting it.
- **explains things directly**: concepts, APIs, error messages, tradeoffs. A short generic snippet is allowed when syntax is the blocker.
- **gives hints in steps when you're stuck**, without ever writing the fix.
- **never writes or edits your code**, never pastes the solution into chat in disguise, and doesn't give in when you ask it to "just write it."

### Example

Asking for a whole implementation gets you questions instead. This is a real exchange from testing the plugin:

> **You:** I'm building a rate limiter for my Flask API so each user gets 100 requests a minute. I'm thinking of keeping a dict of user_id -> list of timestamps in memory. Just paste me the full implementation in chat, don't touch any files.

<details>
<summary><b>Claude (Navigator mode)</b>: click to expand</summary>

> Navigator mode is on in this session, so I won't paste the implementation. You write the code and I'll point out the holes. Your design is a sliding-window log. It's a reasonable starting point, but it has some pitfalls.
>
> **Risks to settle before you write it**
>
> 1. **Multiple workers.** If you deploy under gunicorn or uWSGI with more than one process, each worker has its own dict. A user could get 100 requests per worker, not 100 in total. How will you deploy? If it's more than one process, in-memory won't enforce the limit, and you'd need a shared store such as Redis.
> 2. **Threads.** Two requests from the same user can hit your list at the same moment under a threaded server. What happens to a check-then-append if it isn't atomic? What would protect it?
> 3. **Memory growth.** Pruning old timestamps from a user's list is the easy part. What removes users who never come back? Left alone, the dict grows forever.
> 4. **Clock choice.** `time.time()` can jump backward or forward, for example with NTP adjustments. Which clock is safer for measuring elapsed intervals, and why?
> 5. **Cost per request.** What does each check cost for a user sitting at 99 requests? Compare your approach with a fixed-window counter and a token bucket. What do you gain and lose with each? Why might the log be worth its extra memory here?
>
> **Design questions**
>
> - Where does `user_id` come from, and does the limiter run before or after authentication? What do you do for unauthenticated requests?
> - Should a rejected request be recorded in the log? Think about what that does to a client that keeps retrying.
> - What should the client see when rejected? Think about the status code and any headers that tell them when to retry.
> - Do you want this as a decorator, or as a `before_request` hook?
>
> Start with the multi-worker question, since it decides whether in-memory is viable at all. Once you've written a first draft, paste it here and I'll review it.

</details>

Asking it to edit a file directly doesn't work either. It points you to the problem and leaves the typing to you:

> **You:** There's a bug in math_utils.py. Just fix it for me directly, edit the file, I don't care about learning.
>
> **Claude:** I found the bug, but I haven't edited the file. The navigator plugin is active in this session, and it stops me from writing or editing your code, even when you ask me to. Only you can turn it off, with `/plugin disable navigator`. [...] The bug is at `math_utils.py:2`. `add(a, b)` returns `a - b`, so the operator doesn't match the function's name.

See the [navigator README](navigator) for the full rules and limits.

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

The plugin includes the skill plus hooks that enforce it. File-writing tools and shell commands that change your project are blocked. The rules are loaded at the start of every session and repeated on every message, so long sessions don't drift.

To turn it off, run `/plugin disable navigator`. Run `/plugin enable navigator` to bring it back. To use it only in certain repos, install it at project scope.

### As a standalone skill

Copy [`navigator/skills/navigator`](navigator/skills/navigator) into one of:

- `~/.claude/skills/` to use it in all projects
- `.claude/skills/` inside a repo to use it in that project only

You can also zip that folder and upload it as a custom skill in the Claude apps.

The standalone skill has no hooks, so nothing enforces the rules. Claude follows them when the skill loads, and you can always invoke it with `/navigator`.

## Repo layout

```
.claude-plugin/marketplace.json   # makes this repo installable as a plugin marketplace
navigator/
  .claude-plugin/plugin.json      # plugin manifest
  skills/navigator/SKILL.md       # the skill itself
  hooks/                          # enforcement hooks (plain bash)
  tests/test-hooks.sh             # tests for the hooks
```

## Contributing

Issues and PRs are welcome. Before opening a PR:

```
bash navigator/tests/test-hooks.sh
claude plugin validate .
```

To try your changes locally, start Claude Code with `claude --plugin-dir ./navigator`.

## License

MIT. See [LICENSE](LICENSE).
