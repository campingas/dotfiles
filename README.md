# dotfiles

Personal dotfiles for the machines I use directly and over SSH.

The main laptop workflow is Ghostty with Cmux locally, then SSH into other computers as needed. Human interactive shells should land in zsh, and SSH sessions should use tmux so work survives disconnects.

The Bash files are kept simple and quiet for agents, recovery sessions, and compatibility. When a task asks an agent to inspect or change shell behavior, prefer Bash unless the request explicitly targets zsh.

## Agent Bash Fast Path

`DOTFILES_AGENT_SHELL=1` keeps interactive agent Bash startup lean: it loads core environment, tool paths, and CDPATH, then skips prompt, generated completions, and heavier interactive setup.

| Host | Fast path | Full path | Savings |
|---|---:|---:|---:|
| Local laptop | 8.6 ms/start | 40.9 ms/start | 4.8x faster, 79% less wall time |
| Linux workstation | 2.6 ms/start | 23.3 ms/start | 9.0x faster, 89% less wall time |

Startup output was identical in the benchmark, so the main win is lower latency and fewer shell side effects rather than direct token reduction.

Managed files live in `dots/`. Setup and operational notes live in `docs/`.

Fleet updates are confirmation-gated. An agent may prepare the list of files and target machines, but it must show the plan and wait for confirmation before copying dotfiles across the network.

## Prompt

Install [Starship](https://starship.rs/) where the zsh prompt should use it.

The managed zsh setup initializes Starship when it is available, so machines without Starship still get a usable shell.
