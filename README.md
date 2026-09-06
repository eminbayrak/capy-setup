# capy-setup

My personal configuration for a coordinator-and-crew agent workflow on macOS.

You talk to one coordinator agent. It delegates work to crewmates, each running in
its own terminal tab and its own isolated git worktree. This repo holds the parts
that are mine: the model routing rules, the harness choices, and an installer that
reproduces the whole thing on a fresh machine.

## What this is not

This is **not** a copy of the tools. Every tool below is written by
[Kun Chen](https://github.com/kunchenguid) and installed from its own upstream
source. Nothing here vendors or forks his code.

| Tool | Author | What it does |
| --- | --- | --- |
| [firstmate](https://github.com/kunchenguid/firstmate) | kunchenguid | Coordinator instructions, skills, and scripts |
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | kunchenguid | Review, test, docs, PR, and CI gate |
| [treehouse](https://github.com/kunchenguid/treehouse) | kunchenguid | One clean git worktree per parallel task |
| [lavish-axi](https://github.com/kunchenguid/lavish-axi) | kunchenguid | Interactive HTML artifacts for design review |
| [baby-menu](https://github.com/kunchenguid/baby-menu) | kunchenguid | Self-modifying macOS menu bar |
| [axi](https://github.com/kunchenguid/axi) | kunchenguid | Agent-ergonomic CLI design principles |
| [herdr](https://herdr.dev) | herdr.dev | Agent-aware terminal multiplexer |
| [pi](https://pi.dev) | earendil-works | Crewmate harness |

All of Kun's repos are MIT licensed. This repo is MIT too, but it only covers the
configuration files I wrote.

## What is actually mine

```
config/crew-dispatch.json   model routing rules, by work type
config/crew-harness         static crewmate harness
config/backend              runtime session backend
claude/settings.local.json  delegation guard for a Claude coordinator
install.sh                  reproduces the setup on a fresh machine
```

## Routing

Work routes by type. Every lane below was smoke-tested before it was written down.

| Work type | Goes to |
| --- | --- |
| Design, architecture, ambiguous investigation | `claude / opus / xhigh` |
| Implementation, bugs, tests | copilot `gpt-5.3-codex` → copilot `claude-sonnet-5` → `claude / sonnet` |
| Docs, formatting, chores | copilot `claude-haiku-4.5` → copilot `gemini-3.8-flash` |

Claude sits last in every crew lane deliberately. Crewmates run in parallel and
would otherwise drain the same five-hour window the coordinator needs.

`select: "quota-balanced"` lets the coordinator pick whichever lane still has
subscription headroom.

## Install

```sh
./install.sh
```

Then follow the three interactive steps it prints. It cannot log you into
anything, so it stops and tells you what to do instead of guessing.

## Two things the upstream guide gets wrong for this machine

**Do not run `npm config set prefix ~/.local`.** The upstream setup guide says to.
This machine uses nvm, and a fixed npm prefix breaks nvm's version switching. The
nvm bin directory is already on PATH, so global installs resolve fine without it.

**Do not log Pi into a Claude subscription.** Anthropic restricts subscription
models to first-party surfaces. Use Claude Code for Anthropic models and Pi for
everything else. Copilot's Claude models are fine, because GitHub bills those
separately.

## Delegation guard

`claude/settings.local.json` denies the `Agent` and `Task` tools. A Claude
coordinator can otherwise spawn work through its own subagent tool, which writes
no task metadata, so the fleet cannot see or supervise it. It belongs in
`.claude/settings.local.json` inside the workspace and must stay untracked there.

## License

MIT. See [LICENSE](LICENSE). Upstream tools keep their own licenses and copyright.
