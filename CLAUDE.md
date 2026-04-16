# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Overview

This is an Alfred workflow for macOS. The repo does **not** contain the actual
workflow files directly — they live in Alfred's preferences sync folder. The
Justfile bridges the git repo and Alfred's local workflow folder via rsync.

The folder name of this repo (`kill-process`) must match the folder name of the
workflow inside Alfred's preferences directory. This is a hard requirement for
the `just` commands to work.

## Architecture

The workflow's runtime logic lives entirely in [src/scripts/](src/scripts/) —
zsh scripts invoked by Alfred Script Filter objects defined in `info.plist`:

- `list-processes.sh` / `list-ports.sh` — emit Alfred Script Filter JSON
  (`{"items": [...]}`) for the `knop` / `kpop` keyword queries. They resolve
  `.app` bundles to derive display names and icons, fall back to a generic
  icon for kernel threads / unresolvable paths, and use an `awk` one-liner at
  the end of each loop to strip the trailing comma from the last JSON item.
- `kill-by-name.sh` / `kill-by-port.sh` — receive the selected item's `arg`
  (PID or port) plus `--force` / `--all` flags and send SIGTERM or SIGKILL.
  The `all:<query>` arg prefix, emitted as a special "Kill ALL matching" row
  by `list-processes.sh`, opts a row into `pkill`-based mass kill.

`info.plist` wires keyboard modifiers (`⌘↩`, `⌥↩`) to re-invoke the kill
scripts with the appropriate flags. Since `info.plist` is treated as
generated, edit this wiring through the Alfred UI rather than by hand.

## Development workflow

Alfred workflow files are edited in Alfred's preferences folder, then pulled
into this repo:

```zsh
# Pull changes from Alfred's local workflow folder into the repo
just transfer-changes-FROM-local

# Push repo changes to Alfred's local workflow folder (to test in Alfred)
# (also syncs src/WORKFLOW_README.md into info.plist's `readme` key via plutil)
just transfer-changes-TO-local

# Open the workflow in Alfred for editing
just open-local-workflow-in-alfred
```

The in-Alfred workflow description (shown in Alfred's preferences UI) is
stored in `info.plist`'s `readme` key. The source of truth is
[src/WORKFLOW_README.md](src/WORKFLOW_README.md); `just sync-readme`
(invoked automatically by `transfer-changes-TO-local`) writes it in via
`plutil -replace`. Edit the markdown file, not the plist entry.

## Releasing

```zsh
just release
```

This runs `.build-and-release.sh`, which:
1. Prompts for the next version number
2. Updates `info.plist` in both the repo and the local Alfred folder
3. Commits, pushes, and tags — the tag push triggers a GitHub Actions release
4. Opens the Alfred Gallery submission form with a generated changelog
   (filtered to user-facing commits only — excludes `build`, `ci`, `release`,
   `chore`, `test`, `style` prefixes)

Commit messages therefore follow Conventional Commits style with those
prefixes. Anything intended to appear in release notes / Alfred Gallery
changelog should use a user-facing prefix (e.g. `feat:`, `fix:`, `docs:`,
`perf:`, `refactor:`) or no prefix at all.

## Bootstrapping a new workflow from this template

Run `./BOOTSTRAP.sh` once after cloning. It replaces `{{mustache}}` placeholders
in all files using the GitHub repo metadata and Alfred preferences, then syncs
local workflow files in and makes the initial commit. The script deletes itself
as part of the process.

## Code style

- **Indentation**: tabs, width 3 (except YAML/TOML: 2 spaces; Python: 4 spaces)
- **Line length**: 100 chars (Markdown: 80 chars, with reflow enabled via
  `rumdl`)
- **Markdown linter**: `rumdl` — config in `.rumdl.toml`
- **`info.plist`** is treated as a generated file (see `.gitattributes`) —
  don't manually edit it

## Rsync exclusions

Files listed in `.rsync-exclude` are not synced to Alfred's local folder. This
includes: git files, docs, LICENSE, README, Justfile, `.github/`, build/release
scripts, and linter configs.
