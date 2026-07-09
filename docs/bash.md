# Bash

Bash is the agent and compatibility shell. Keep `.bashrc`, `.profile`, and `.inputrc` simple, portable, and quiet in non-interactive sessions.

Interactive agent Bash should stop after core environment, tool PATHs, and CDPATH setup. `DOTFILES_AGENT_SHELL=1` forces that fast path, while `DOTFILES_AGENT_SHELL=0` forces the full interactive setup.

Prefer non-interactive commands such as `bash -lc 'command'` when no prompt behavior is needed.

Avoid printing full `PATH` or environment dumps unless debugging path resolution.

## Fast Path Benchmark

Measured over 100 interactive Bash startups.

| Host | Fast path | Full path | Savings |
|---|---:|---:|---:|
| Local laptop | 8.6 ms/start | 40.9 ms/start | 4.8x faster, 79% less wall time |
| Linux workstation | 2.6 ms/start | 23.3 ms/start | 9.0x faster, 89% less wall time |

Startup output was identical in the benchmark, so the main win is lower latency and fewer shell side effects rather than direct token reduction.

## Validation

Run `bash -n dots/.bashrc dots/.profile`.

Run `shellcheck dots/.bashrc dots/.profile`.

Verify the fast path with `DOTFILES_AGENT_SHELL=1 bash --noprofile --rcfile dots/.bashrc -ic true`.

Verify the full path with `DOTFILES_AGENT_SHELL=0 bash --noprofile --rcfile dots/.bashrc -ic true`.
