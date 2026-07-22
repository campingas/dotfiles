# GPT-5.6 Agent Selection

Evidence snapshot: 2026-07-22.

This document defines the managed Codex multi-agent V2 fleet under `dots/.codex/agents/` and the evidence required to change it.

## Decision

Use native named-role spawning with five narrow profiles.

Use GPT-5.6 Sol for every managed role. This is a deliberate quality-per-accepted-result policy: first clear the task's quality floor, then minimize reasoning effort and output tokens among configurations that pass. Use Fast only for low-effort lookup, keep every other role on Standard speed, and keep integration and final decisions in the root session.

`dots/.codex/AGENTS.md` owns orchestration policy, the TOML files in this directory are the declared role configuration truth, and app-managed global configuration owns multi-agent feature and capacity settings.

## Profiles

| Profile | Model | Effort | Speed | Sandbox | Use |
|---------|-------|--------|-------|---------|-----|
| `lookup` | GPT-5.6 Sol | low | Fast | read-only | Exact mechanical facts with no material judgment |
| `investigate` | GPT-5.6 Sol | medium | Standard | read-only | Multi-file tracing, research, and distilled evidence |
| `implement` | GPT-5.6 Sol | medium | Standard | workspace-write | Normal bounded implementation |
| `implement_deep` | GPT-5.6 Sol | high | Standard | workspace-write | Security, migrations, cross-system debugging, and material ambiguity |
| `review` | GPT-5.6 Sol | high | Standard | read-only | Consequential correctness, regression, security, and test-gap review |

Historical migration note: the V2 simplification removed two overlapping fast-named roles. They both used high reasoning at Standard speed, so their names implied a speed distinction that did not exist.

## What fast means

Keep four measurements separate:

- **Output throughput** is generated tokens per second after generation starts.
- **Total output tokens** measure how much answer and reasoning text a task consumes.
- **End-to-end latency** includes time to first answer token, reasoning time, tool calls, and generation time.
- **Task success** measures whether the result actually satisfies the verifier or acceptance criteria.

[OpenAI's Codex guidance](https://learn.chatgpt.com/docs/models#recommended-models) describes Sol as the choice for complex, open-ended, high-value work, Terra as the pragmatic all-rounder, and Luna as the option for clear, repeatable, high-volume tasks. That family-tier guidance is not wrong; it optimizes a broader price-and-volume boundary. This repo instead prioritizes quality per accepted result across a small managed fleet, while following the same recommendation to use the lowest reasoning effort that produces the required result.

[Codex Fast mode](https://learn.chatgpt.com/docs/agent-configuration/speed) increases supported-model speed by about 1.5x and consumes GPT-5.6 ChatGPT credits at 2.5x the Standard rate. It does not mean low reasoning, fewer output tokens, or better task success. The current matrix uses it only for low-effort lookup, where latency is the priority and the task boundary prevents unnecessary work.

- Use low effort only for objective work that is cheap to verify.
- Use medium for normal investigation and implementation.
- Use high when failure is expensive or the task requires complex logic, security analysis, edge-case reasoning, or consequential review.
- Sol xhigh is a one-off override after a failed Sol-high attempt or for a genuinely long-horizon frontier task, with the reason recorded. Max effort is excluded.
- Lookup alone uses Fast speed. Every other managed profile uses Standard speed. Keep Fast only while local measurements support its wall-time benefit for the latency-sensitive lookup role and its higher credit consumption remains acceptable.

## Artificial Analysis

[Artificial Analysis](https://artificialanalysis.ai/models) measures broad model intelligence, token use, API generation speed, and evaluation cost. Its Intelligence Index v4.1 combines nine evaluations covering agentic work, tool use, coding, science, general reasoning, knowledge reliability, and long-context reasoning.

The output-token figure is the total generated across the Intelligence Index. Artificial Analysis also reports a weighted output-token-per-task view and separates answer and reasoning tokens in its charts. Evaluation cost includes input, cache read and write, reasoning, and answer tokens. These figures are useful for comparing model behavior at the same effort, but they are not a Codex CLI task trace.

| Model | Effort | Intelligence Index | Output tokens | Output tok/s | Evaluation cost |
|-------|--------|-------------------:|--------------:|-------------:|----------------:|
| [Sol](https://artificialanalysis.ai/models/gpt-5-6-sol-low) | low | 49 | 6.6M | 55.9 | $353.49 |
| [Terra](https://artificialanalysis.ai/models/gpt-5-6-terra-low) | low | 40 | 5.9M | 130.1 | $199.96 |
| [Luna](https://artificialanalysis.ai/models/gpt-5-6-luna-low) | low | 33 | 7.0M | 179.8 | $68.80 |
| [Sol](https://artificialanalysis.ai/models/gpt-5-6-sol-medium) | medium | 54 | 12M | 58.3 | $593.04 |
| [Terra](https://artificialanalysis.ai/models/gpt-5-6-terra-medium) | medium | 46 | 10M | 122.8 | $285.91 |
| [Luna](https://artificialanalysis.ai/models/gpt-5-6-luna-medium) | medium | 38 | 12M | 192.7 | $105.84 |
| [Sol](https://artificialanalysis.ai/models/gpt-5-6-sol-high) | high | 56 | 21M | 58.7 | $955.55 |
| [Terra](https://artificialanalysis.ai/models/gpt-5-6-terra-high) | high | 49 | 24M | 129.6 | $604.75 |
| [Luna](https://artificialanalysis.ai/models/gpt-5-6-luna-high) | high | 46 | 37M | 192.8 | $275.02 |
| [Sol](https://artificialanalysis.ai/models/gpt-5-6-sol-xhigh) | xhigh | 58 | 35M | 61.4 | $1,542.52 |
| [Terra](https://artificialanalysis.ai/models/gpt-5-6-terra-xhigh) | xhigh | 52 | 36M | 125.1 | $909.61 |
| [Luna](https://artificialanalysis.ai/models/gpt-5-6-luna-xhigh) | xhigh | 49 | 67M | 197.1 | $479.37 |
| [Sol](https://artificialanalysis.ai/models/gpt-5-6-sol) | max | 59 | 70M | 63.5 | $2,824.18 |
| [Terra](https://artificialanalysis.ai/models/gpt-5-6-terra) | max | 55 | 96M | 135.4 | $2,060.40 |
| [Luna](https://artificialanalysis.ai/models/gpt-5-6-luna) | max | 51 | 130M | 183.3 | $870.30 |

The same-effort comparison is decisive from high upward: Sol scores higher while using fewer output tokens than Terra and Luna. At medium, Sol uses 20% more output tokens than Terra but gains eight index points; it matches Luna's token total while gaining sixteen points. At low, Terra is 0.7M tokens shorter but loses nine points, while Sol is both stronger and shorter than Luna.

Artificial Analysis therefore supports Sol when response quality is constrained, while also showing why Terra or Luna can still be rational when API price or raw streaming throughput is more important than the strongest result.

## DeepSWE

[DeepSWE v1.1](https://deepswe.datacurve.ai/), source snapshot dated July 21, 2026, measures 113 original long-horizon engineering tasks from 91 repositories across TypeScript, JavaScript, Python, Go, and Rust. The leaderboard reports Pass@1, average cost, average output tokens, and agent steps. Every model uses the same mini-swe-agent harness and shared Bash tool so the comparison holds scaffolding constant.

| Model | Effort | Pass@1 | Avg cost | Output tokens | Steps |
|-------|--------|-------:|---------:|--------------:|------:|
| Sol | low | 45% ±2% | $1.07 | 11k | 23 |
| Sol | medium | 61% ±2% | $1.86 | 18k | 31 |
| Sol | high | 69% ±1% | $3.47 | 28k | 37 |
| Sol | xhigh | 71% ±1% | $4.70 | 41k | 44 |
| Sol | max | 73% ±3% | $8.39 | 60k | 61 |
| Terra | low | 24% ±1% | $0.43 | 8.6k | 21 |
| Terra | medium | 35% ±3% | $0.58 | 12k | 25 |
| Terra | high | 54% ±4% | $1.13 | 22k | 34 |
| Terra | xhigh | 60% ±2% | $2.13 | 40k | 43 |
| Terra | max | 70% ±3% | $4.95 | 72k | 76 |
| Luna | low | 2% ±1% | $0.07 | 3.1k | 12 |
| Luna | medium | 11% ±1% | $0.22 | 8.2k | 24 |
| Luna | high | 44% ±3% | $0.78 | 26k | 49 |
| Luna | xhigh | 57% ±2% | $1.54 | 45k | 71 |
| Luna | max | 67% ±4% | $3.03 | 73k | 102 |

The cross-effort comparisons are more useful than comparing model names at the same effort:

- Sol low reaches 45% with 11k tokens; Terra medium reaches 35% with 12k.
- Sol medium reaches 61% with 18k tokens; Terra high reaches 54% with 22k.
- Sol high reaches 69% with 28k tokens; Terra max reaches 70% with 72k, a statistically overlapping result using about 2.6x the tokens.
- Sol low reaches 45% with 11k tokens; Luna high reaches 44% with 26k.
- Sol medium reaches 61% with 18k tokens; Luna xhigh reaches 57% with 45k.
- Sol high reaches 69% with 28k tokens; Luna max reaches 67% with 73k.

These rows show why raw price and throughput are incomplete routing criteria. Terra and Luna can be cheaper per attempt, but a lower-quality attempt is not token-efficient when it must be retried, escalated, or repaired.

## Derived efficiency view

Pass@1 percentage points per 1,000 output tokens is a useful secondary heuristic, calculated from DeepSWE's published values:

| Model | low | medium | high | xhigh | max |
|-------|----:|-------:|-----:|------:|----:|
| Sol | 4.09 | 3.39 | 2.46 | 1.73 | 1.22 |
| Terra | 2.79 | 2.92 | 2.45 | 1.50 | 0.97 |
| Luna | 0.65 | 1.34 | 1.69 | 1.27 | 0.92 |

This ratio is derived here; neither benchmark publishes it as a headline metric. It must never be optimized without a quality floor because a short failure can appear efficient. The valid procedure is: first require an acceptable answer, then minimize tokens among configurations that clear that requirement.

Sol also shows diminishing returns inside its own effort ladder on DeepSWE:

| Change | Pass@1 gain | Extra output tokens |
|--------|------------:|--------------------:|
| low → medium | +16 points | +7k |
| medium → high | +8 points | +10k |
| high → xhigh | +2 points | +13k |
| xhigh → max | +2 points | +19k |

This is the direct evidence for managed low, medium, and high profiles and for keeping xhigh exceptional and max unavailable. Artificial Analysis shows the same shape: Sol gains five index points from low to medium, two from medium to high, two from high to xhigh, and only one from xhigh to max while output tokens rise from 6.6M to 12M, 21M, 35M, and 70M.

## Policy interpretation

Use Sol low when the answer is objective, narrowly scoped, and cheap to verify. Fast speed improves responsiveness without raising reasoning effort.

Use Sol medium as the default quality/token balance for work requiring planning, multi-file context, investigation, or normal implementation. DeepSWE shows it exceeding Terra high and Luna xhigh while using fewer tokens.

Use Sol high when failure is expensive or the task needs complex logic, edge-case analysis, or consequential review. It nearly matches Terra max and exceeds Luna max with less than 40% of their output tokens on DeepSWE.

Do not select Terra or Luna solely because their output rate is higher. They are valid challengers for explicitly price-sensitive, high-volume, or latency-first workflows, but current evidence does not justify them as defaults for these managed profiles under a strong-quality, low-token objective.

Do not normalize xhigh or max. Both benchmarks show sharply declining gains after high, and the repo's stop conditions should address overreach before increasing reasoning.

## Local validation protocol

Public benchmarks cannot prove performance in this repository's exact Codex harness. Re-evaluate the matrix when benchmark data changes materially or when a real profile repeatedly misses its acceptance criteria.

1. Freeze the repository commit, task prompt, acceptance criteria, sandbox, tools, context, and service tier.
2. Select at least three representative tasks for each affected class: lookup, investigation, implementation, or review.
3. Compare the incumbent with one challenger at the same reasoning effort and Standard speed first; test Fast versus Standard separately after selecting the model and effort.
4. Run each task three times and record hard acceptance-criteria pass/fail, output and reasoning tokens, wall time, tool steps, and cost.
5. For research or writing without a binary verifier, score correctness, completeness, evidence, and concision from 0 to 2 under a blinded rubric; require at least 7/8 and no correctness failure.
6. Among configurations clearing the quality floor, prefer the lowest median output-token use. Replace an incumbent only when the challenger causes no loss in accepted runs and reduces median output tokens by at least 20%.
7. Keep Fast only when it materially reduces median wall time for the latency-sensitive profile and its higher credit consumption is acceptable; do not treat it as a token-saving feature.

## Concurrency

The app-managed Codex configuration currently provides this global runtime boundary:

```toml
[features]
multi_agent_v2 = true

[agents]
max_threads = 4
max_depth = 1
```

`agents.max_threads` is a safety cap, not a target. Run at most three independent read-only subagents concurrently and never more than one writing agent. Do not run concurrent writers against overlapping files.

Keep `agents.max_depth = 1`. Children should not delegate recursively because repeated fan-out increases token use, latency, and coordination risk.

When selecting a custom `agent_type`, use an isolated fork. Codex 0.145.0 rejected a full-history fork that tried to override the parent role; the equivalent isolated fork selected the configured role successfully.

## Routing

Delegate only a concrete independent objective.

Use one matching profile for normal investigation, implementation, or review. Use multiple read-only profiles only when separate concerns can run independently and their combined result materially improves speed or quality.

The root owns requirements, task division, integration, final validation, and the user-facing result.

Require confirmation before `implement_deep`, more than three read-only subagents, multiple sequential delegated runs, or an xhigh override.

## Native Validation

Current validation on 2026-07-22: after activating the all-Sol matrix, Codex CLI 0.145.0 passed the native role-plumbing control with multi-agent V2.

The fresh root recorded `multi_agent_version = "v2"`, GPT-5.6 Sol at medium effort, and a read-only sandbox. Its isolated native child recorded `agent_role = "lookup"`, GPT-5.6 Sol at low effort, and a read-only sandbox. Root session `019f8833-33c4-7512-87e1-d2a50620d841` and child session `019f8833-68a0-73d3-a236-70e542743d11` validate the active lookup runtime and fresh-root sandbox narrowing. The live profile separately confirms Fast speed because rollout records do not persist service tier.

Persisted `agent_role`, model, effort, sandbox, and multi-agent version are runtime evidence. An agent path, nickname, task label, or self-report is not sufficient. Service tier is checked separately from the profile and launcher configuration because the rollout record does not persist it.

The lookup control proves explicit named-role plumbing and the active lookup runtime.

An earlier activation smoke selected a temporary Terra-low `lookup` profile under V2 but retained the active root's `workspace-write` sandbox. Keep it as historical plumbing evidence only; the fresh read-only control above supersedes its sandbox result for the active all-Sol lookup profile.

Neutral automatic selection passed later on 2026-07-22. Root session `019f883f-ff31-7210-ba92-8b89fabc84de` received a real multi-file review prompt with no routing vocabulary and autonomously selected `review`. Child session `019f8840-3ea8-7f42-b650-0f1da029c0c5` recorded `agent_role = "review"`, GPT-5.6 Sol at high effort, a read-only sandbox, and multi-agent V2. The root waited for the child, integrated three actionable findings, and completed the review. The live profile separately confirms Standard speed.

## Evidence Limits

[DeepSWE](https://deepswe.datacurve.ai/) is useful evidence for long-horizon implementation quality, but its shared mini-swe-agent harness does not reproduce native Codex behavior and does not represent mechanical lookup well.

[Artificial Analysis](https://artificialanalysis.ai/models) is useful for broad intelligence, throughput, token use, and API-cost comparisons, but its live values change frequently and API evaluation prices are not ChatGPT credit consumption.

Keep benchmark links and conclusions here instead of copying full volatile leaderboards. Record a new dated snapshot only when it changes a routing decision.
