---
name: inference-latency-throughput-tuning
description: "Tune vLLM and SGLang batching and scheduling knobs toward a stated latency or throughput SLO by trading off TTFT, inter-token latency, and aggregate throughput; use when asked to reduce TTFT or ITL, increase tokens/sec or requests/sec, hit a latency SLO, or decide batching parameters for a serving deployment"
when_to_use: "Triggers on: 'reduce time-to-first-token', 'improve inter-token latency', 'increase throughput', 'server is too slow', 'tune max-num-batched-tokens / max-num-seqs', 'hit a p99 latency target', or choosing batching parameters for a new deployment. Applies to both single-stream latency and high-concurrency throughput goals."
metadata:
  author: mattniedelman
  version: "1.0.0"
---

# Inference Latency / Throughput Tuning

## Overview

Latency and throughput trade against each other, and the two latency metrics
(TTFT and ITL) trade against each other too. Tuning blindly optimizes one and
silently regresses the one the user actually cares about. Every knob in this
skill moves along the prefill (compute-bound) vs decode (memory-bandwidth-bound)
axis -- so the first job is to name the target metric, then move the right knob
in the right direction.

**Core principle:** Define the SLO metric before touching a knob. You cannot
maximize TTFT, ITL, and throughput simultaneously -- pick the one that matters
and accept the others degrade.

**Announce at start:** "I'm using the Inference Latency/Throughput Tuning skill."

## Step 0: Name the target metric

Do not proceed until the goal is one of these (ask if ambiguous):

| Metric | Definition | Who cares |
|--------|------------|-----------|
| **TTFT** (time to first token) | Prompt submit -> first output token | Interactive chat, anything where "it feels stuck" |
| **ITL / TPOT** (inter-token latency) | Steady-state gap between output tokens | Streaming UIs, perceived typing speed |
| **Throughput** | Aggregate tokens/sec or requests/sec across all concurrent requests | Batch jobs, offline generation, cost/token |
| **p99 latency under load** | Tail latency at target concurrency | SLO-bound production traffic |

TTFT is dominated by **prefill**; ITL by **decode**; throughput by **how many
tokens are packed per step**. These pull in different directions.

## Step 1: Read the version and current defaults

Scheduler behavior and default knob values change between releases (vLLM V1
mixes prefill+decode in one step with chunked prefill on by default; V0 did
not). Read the installed version and confirm defaults before changing them:

```bash
python -c "import vllm; print(vllm.__version__)"     # or vllm --version
python -c "import sglang; print(sglang.__version__)"
```

## Step 2: Turn the knob that matches the metric

### The master knob: `max_num_batched_tokens` (vLLM)

This is the token budget per scheduler step -- the single highest-leverage
latency/throughput lever in vLLM V1.

| Goal | Direction | vLLM starting point |
|------|-----------|---------------------|
| Better ITL (smooth streaming) | **Lower** it | ~2048 -- decode steps interleave more, less blocked by big prefill chunks |
| Better TTFT (faster first token) | **Raise** it | prompt prefills in fewer steps |
| Max throughput | **Raise** it high | **> 8192**, especially for smaller models on large GPUs -- more tokens per step amortizes overhead |

The tension: raising it for throughput/TTFT lengthens each step and can hurt
ITL; lowering it for smooth ITL costs aggregate throughput. Chunked prefill
(default in V1) is what lets decode tokens ride alongside prefill chunks --
verify it is enabled.

### Concurrency: `max_num_seqs` (vLLM) / `--max-running-requests` (SGLang)

Caps how many sequences run concurrently.

- **Raise** for throughput (more parallel work) -- until KV cache pressure
  causes preemption/recompute thrash or OOM (see `inference-oom-triage`).
- **Lower** for tail latency -- fewer concurrent sequences means each gets more
  bandwidth per step, tightening p99 ITL.

### Watch for preemption (the hidden throughput killer)

vLLM V1 defaults to **RECOMPUTE** preemption (lower overhead than SWAP in V1).
Preemption thrash tanks throughput and spikes tail latency. Reduce it by:

- raising `gpu_memory_utilization` (bigger KV pool, fewer evictions),
- lowering `max_num_seqs` / `max_num_batched_tokens` (less pressure), or
- increasing tensor/pipeline parallel size (more aggregate memory -- at a
  synchronization/latency cost).

Check logs for preemption/recompute counters before assuming a knob is the
bottleneck.

### Prefix caching (near-free TTFT win on shared prefixes)

vLLM automatic prefix caching (on by default; the default KV block size is 16
tokens via `--block-size`, which is the paging granularity for all KV cache,
not a prefix-cache-only knob) and SGLang RadixAttention reuse KV for shared
prefixes and **cut TTFT** -- they do nothing
for decode/ITL. If requests share a long system prompt or few-shot preamble,
confirm prefix caching is enabled and structure prompts so the shared part is a
common prefix. See `prefix-caching-optimizer` when it exists.

### SGLang-specific

- `--chunked-prefill-size`: analogous prefill-chunk lever; lower for smoother
  decode interleaving, higher for prefill throughput.
- `--schedule-conservativeness`: lower to admit requests more aggressively
  (throughput), raise to protect running requests (latency).
- For heavy prefill-vs-decode interference at scale, prefill/decode
  disaggregation stops prefill batches from stalling decode (a p99-ITL fix, at
  the cost of KV-transfer overhead and operational complexity).

## Step 3: Measure, do not guess

Change one knob, re-run the **same** benchmark, compare the **target** metric.

```bash
vllm bench serve --model <m> --dataset-name <...>     # vLLM
python -m sglang.bench_serving --backend sglang ...   # SGLang
```

Use a load profile that matches production: single-stream for TTFT/ITL work;
sustained concurrency at target QPS for throughput/p99. A knob that improves
throughput at batch=64 can regress ITL at batch=1 -- measure the regime you
actually serve.

## Verification Gate

Before claiming a tuning result, confirm ALL:

1. Was the target metric named (TTFT / ITL / throughput / p99) before tuning?
2. Was the engine version read and the changed default verified against it?
3. Was one knob changed per iteration and re-benchmarked on the same profile?
4. Was the **non-target** metric checked for an unacceptable regression?
5. Were preemption/recompute counters checked (they invalidate naive
   conclusions)?

Any "no" = not done.

## Red Flags -- STOP if you think any of these

- "Just make it faster" without a named metric -- faster TTFT can mean slower
  ITL.
- "Raise `max_num_batched_tokens` to the max" as a universal win -- it helps
  throughput/TTFT but can wreck streaming ITL.
- "More concurrency is always more throughput" -- past the KV ceiling it causes
  preemption thrash and *lower* throughput.
- Benchmarking at batch=1 and shipping the config for batch=64 (or vice versa).
- Comparing runs after changing two knobs.

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Optimize latency" | TTFT and ITL are different latencies that trade off -- name which one. |
| "Bigger batch is always better" | Better throughput, worse ITL. Only "better" if throughput is the SLO. |
| "Throughput dropped but I added concurrency?" | KV pressure caused preemption/recompute thrash -- classic over-concurrency regression. |
| "The default TTFT is fine" | Prefix caching may be off, or a huge batch token budget is delaying first tokens -- measure. |
| "One benchmark number proves it" | Only if it's the target metric on a production-representative load profile. |
