# GPT-5.6 Agent Selection

Evidence snapshot: 2026-07-18.

This document explains why the managed profiles under `dots/.codex/agents/` use GPT-5.6 Sol with low, medium, or high reasoning instead of distributing routine work across Sol, Terra, and Luna.

## Decision

Use Sol at the lowest reasoning effort that reliably clears the task's quality floor.

The current profile matrix follows that rule: low for exact lookup, medium for normal investigation, implementation, and review, and high for difficult or tightly bounded work that needs deeper checking. Only low uses Fast speed; medium and high use Standard speed. Sol xhigh requires a recorded one-off justification, and max is excluded.

This is a quality-constrained token decision, not a claim that Sol is cheapest or has the highest raw throughput. Terra and Luna have lower API token prices and generate tokens faster, but the two public benchmark families below show Sol producing substantially stronger results per output-token budget once the task requires a good answer.

## Current profiles

| Profile | Effort | Speed | Quality requirement |
|---------|--------|-------|---------------------|
| `lookup` | low | Fast | One exact, bounded fact with no material judgment |
| `investigate` | medium | Standard | Evidence-backed multi-file tracing or research |
| `implement` | medium | Standard | Complete bounded behavior with validation |
| `implement_fast` | high | Standard | Tightly specified change with strong reasoning and little process overhead |
| `implement_deep` | high | Standard | Cross-system, migration, security, or materially ambiguous work |
| `review` | medium | Standard | Correctness and regression review of normal scope |
| `review_fast` | high | Standard | Narrow review that still needs deep checking |

The names `implement_fast` and `review_fast` describe a reduced-process task envelope, not the Fast service tier. Their high reasoning remains on Standard speed.

## What fast means

Keep four measurements separate:

- **Output throughput** is generated tokens per second after generation starts.
- **Total output tokens** measure how much answer and reasoning text a task consumes.
- **End-to-end latency** includes time to first answer token, reasoning time, tool calls, and generation time.
- **Task success** measures whether the result actually satisfies the verifier or acceptance criteria.

[OpenAI's Codex guidance](https://learn.chatgpt.com/docs/models#recommended-models) describes Sol as the choice for complex, open-ended, high-value work, Terra as the pragmatic all-rounder, and Luna as the option for clear, repeatable, high-volume tasks. It also recommends using the lowest reasoning effort that produces the required result.

[Codex Fast mode](https://learn.chatgpt.com/docs/agent-configuration/speed) increases supported-model speed by about 1.5x and consumes GPT-5.6 ChatGPT credits at 2.5x the Standard rate. It does not mean low reasoning, fewer output tokens, or better task success. The current matrix uses it only for low-effort lookup, where latency is the priority and the task boundary prevents unnecessary work.

## Artificial Analysis

[Artificial Analysis](https://artificialanalysis.ai/models) measures broad model intelligence, token use, API generation speed, and evaluation cost. Its Intelligence Index v4.1 combines nine evaluations covering agentic work, tool use, coding, science, general reasoning, knowledge reliability, and long-context reasoning.

The output-token figure is the total generated across the Intelligence Index. Artificial Analysis also reports a weighted output-token-per-task view and separates answer and reasoning tokens in its charts. Evaluation cost includes input, cache read and write, reasoning, and answer tokens. These figures are useful for comparing model behavior at the same effort, but they are not a Codex CLI task trace.

| Model | Effort | Intelligence Index | Output tokens | Output tok/s | Evaluation cost |
|-------|--------|-------------------:|--------------:|-------------:|----------------:|
| [Sol](https://artificialanalysis.ai/models/gpt-5-6-sol-low) | low | 49 | 6.6M | 52.1 | $353.49 |
| [Terra](https://artificialanalysis.ai/models/gpt-5-6-terra-low) | low | 40 | 5.9M | 122.3 | $160.65 |
| [Luna](https://artificialanalysis.ai/models/gpt-5-6-luna-low) | low | 33 | 7.0M | 171.2 | $68.80 |
| [Sol](https://artificialanalysis.ai/models/gpt-5-6-sol-medium) | medium | 54 | 12M | 54.7 | $593.04 |
| [Terra](https://artificialanalysis.ai/models/gpt-5-6-terra-medium) | medium | 46 | 10M | 117.5 | $240.23 |
| [Luna](https://artificialanalysis.ai/models/gpt-5-6-luna-medium) | medium | 38 | 12M | 168.4 | $105.84 |
| [Sol](https://artificialanalysis.ai/models/gpt-5-6-sol-high) | high | 56 | 21M | 52.0 | $955.55 |
| [Terra](https://artificialanalysis.ai/models/gpt-5-6-terra-high) | high | 49 | 24M | 117.8 | $495.77 |
| [Luna](https://artificialanalysis.ai/models/gpt-5-6-luna-high) | high | 46 | 37M | 173.4 | $275.02 |
| [Sol](https://artificialanalysis.ai/models/gpt-5-6-sol-xhigh) | xhigh | 58 | 35M | 54.5 | $1,542.52 |
| [Terra](https://artificialanalysis.ai/models/gpt-5-6-terra-xhigh) | xhigh | 52 | 36M | 123.4 | $740.21 |
| [Luna](https://artificialanalysis.ai/models/gpt-5-6-luna-xhigh) | xhigh | 49 | 67M | 169.2 | $479.37 |
| [Sol](https://artificialanalysis.ai/models/gpt-5-6-sol) | max | 59 | 70M | 55.0 | $2,824.18 |
| [Terra](https://artificialanalysis.ai/models/gpt-5-6-terra) | max | 55 | 96M | 135.8 | $1,753.94 |
| [Luna](https://artificialanalysis.ai/models/gpt-5-6-luna) | max | 51 | 130M | 185.5 | $870.30 |

The same-effort comparison is decisive from high upward: Sol scores higher while using fewer output tokens than Terra and Luna. At medium, Sol uses 20% more output tokens than Terra but gains eight index points; it matches Luna's token total while gaining sixteen points. At low, Terra is 0.7M tokens shorter but loses nine points, while Sol is both stronger and shorter than Luna.

Artificial Analysis therefore supports Sol when response quality is constrained, while also showing why Terra or Luna can still be rational when API price or raw streaming throughput is more important than the strongest result.

## DeepSWE

[DeepSWE v1.1](https://deepswe.datacurve.ai/), updated 2026-07-17, measures 113 original long-horizon engineering tasks from 91 repositories across TypeScript, JavaScript, Python, Go, and Rust. The leaderboard reports Pass@1, average cost, average output tokens, and agent steps. Every model uses the same mini-swe-agent harness and shared Bash tool so the comparison holds scaffolding constant.

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

Use Sol medium as the default quality/token balance for work requiring planning, multi-file context, implementation, or normal review. DeepSWE shows it exceeding Terra high and Luna xhigh while using fewer tokens.

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

## Limitations

[DeepSWE's methodology and limitations](https://deepswe.datacurve.ai/blog/deepswe) are important. The common mini-swe-agent harness isolates model capability but does not reproduce native Codex CLI tools or prompts. Its corpus covers popular open-source repositories, five languages, and mostly long-horizon feature work; long-tail repositories, proprietary code, C++, Java, bug localization, and refactoring are under-represented.

DeepSWE's confidence intervals overlap for some close scores, so a one-point difference such as Sol high versus Terra max is not a reliable quality separation by itself. The large token difference is still relevant, and Sol xhigh exceeds Terra max while using substantially fewer tokens.

Artificial Analysis is a broad composite intelligence benchmark rather than a software-agent acceptance test. Its total token counts and DeepSWE's per-task averages use different denominators and must not be combined into one formula.

API evaluation prices are not the same as ChatGPT credit consumption. Fast mode's credit multiplier is an OpenAI product rule, while the benchmark cost columns use API pricing.

This evidence is a dated snapshot, not a permanent model ranking. Refresh the tables from their linked sources, preserve source-versus-derived labels, rerun the arithmetic, and require local validation before changing the profile matrix.
