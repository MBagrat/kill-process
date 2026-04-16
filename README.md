# Kill process

![GitHub downloads](https://img.shields.io/github/downloads/mbagrat/alfred-kill-process/total?label=GitHub%20Downloads&style=plastic&logo=github)
![Latest release](https://img.shields.io/github/v/release/mbagrat/alfred-kill-process?label=Latest%20Release&style=plastic)

Find and kill processes by name or port.

## Usage

Pick a mode interactively via the `kill` keyword.

![Mode picker](src/assets/images/kill.png)

Search running processes by name via the `knop` keyword.

![Searching processes by name](src/assets/images/knop.png)

- <kbd>↩</kbd> Graceful kill (SIGTERM).
- <kbd>⌘</kbd><kbd>↩</kbd> Force kill (SIGKILL).
- <kbd>⌥</kbd><kbd>↩</kbd> Kill all matching processes.

Alternatively, search processes listening on a port via the `kpop` keyword.

![Searching processes by port](src/assets/images/kpop.png)

- <kbd>↩</kbd> Graceful kill (SIGTERM).
- <kbd>⌘</kbd><kbd>↩</kbd> Force kill (SIGKILL).

Configure the Hotkey for faster triggering of each mode.

## Installation

[➡️ Download the latest release.](https://github.com/mbagrat/alfred-kill-process/releases/latest)

## About the developer

In my day job, I am a software engineer. If you find this project helpful, you
can support me via [🩷 GitHub
Sponsors](https://github.com/sponsors/mbagrat?frequency=one-time).
