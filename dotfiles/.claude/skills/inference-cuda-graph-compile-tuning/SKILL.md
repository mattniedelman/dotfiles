---
name: inference-cuda-graph-compile-tuning
description: "Configure torch.compile and CUDA graph capture in vLLM and SGLang to cut per-step CPU overhead and cold-start time without breaking correctness; use when tuning compilation level, choosing piecewise vs full CUDA graph capture, deciding whether to run eager, diagnosing a graph-capture OOM or a compile-vs-eager numerical mismatch, or persisting the compile cache to speed pod cold starts"
when_to_use: "Triggers on: 'per-step CPU overhead / low GPU utilization at small batch', 'torch.compile level / -O flag', 'piecewise vs full CUDA graphs', 'cudagraph capture failed / OOM at capture', 'enforce-eager', 'SGLang compile / sglang --disable-cuda-graph / --cuda-graph-max-bs', 'compile is slow to warm up', 'copy the torch_compile_cache to speed cold start', or a numerical difference between eager and compiled runs. Applies to overhead/cold-start tuning, not to authoring custom kernels (see inference-triton-kernel-authoring)."
metadata:
  author: mattniedelman
  version: "1.0.0"
---

# Inference CUDA Graph / torch.compile Tuning

## Overview

torch.compile and CUDA graphs both attack the same problem -- CPU-side launch
overhead that dominates at small batch sizes -- but they fail in different ways
and are tuned with different knobs. Operators routinely either leave both off
(and eat the overhead), crank compilation to a level that never pays back its
warm-up cost, or capture full graphs on a backend that cannot support them and
get a startup crash. The right setting depends on the batch-size regime, the
attention backend, and whether cold-start latency matters.

**Core principle:** These are launch-overhead optimizations, not compute
optimizations. They matter most at **small batch / low concurrency** where the
GPU is idle waiting on the CPU to launch the next kernel. At high throughput
the kernels are already back-to-back and the win shrinks -- so tune for the
regime you actually serve.

**Announce at start:** "I'm using the Inference CUDA Graph / Compile Tuning
skill."

## Step 0: Read the version and current defaults (do not skip)

Compilation defaults, the `-O` level meaning, and the CUDA-graph capture mode
change between releases. **Read the installed version and verify the default
before changing it.**

```bash
python -c "import vllm; print(vllm.__version__)"     # or vllm --version
python -c "import sglang; print(sglang.__version__)"
```

Then confirm the current compile/graph default against that version's docs
(`docs.vllm.ai/en/v<X.Y.Z>/...` or the matching SGLang release). State the
version in any recommendation so it is reproducible.

## Step 1: Decide whether to compile / capture at all

| Situation | Recommendation |
|-----------|----------------|
| Small batch / interactive / low concurrency | **Enable** compile + CUDA graphs -- this is where launch overhead dominates and the win is largest. |
| High sustained throughput, large batches | Modest win; kernels are already dense. Enable, but do not expect much. |
| Debugging a crash, a new model, or a custom kernel | **`--enforce-eager`** -- disables both compile and graph capture so tracebacks point at the real op instead of `graph.replay()`. |
| Frequent cold starts (autoscaling / scale-to-zero pods) | Enable compile, then **persist and ship the compile cache** (Step 4) so each new pod does not recompile. |

Within "small batch," the **decode** phase is usually where CUDA graphs help
most (many tiny, launch-bound steps); small-batch prefill can be
memory-bandwidth-bound on prompt processing and benefit less. If tuning a
decode-heavy workload, that is the regime to measure.

`--enforce-eager` (vLLM) is the master off-switch and the first diagnostic move
for any compile/graph-suspected bug. The SGLang analog is
`--disable-cuda-graph` (plus `--enable-torch-compile` is opt-in there, not
default -- verify for the installed version).

## Step 2: Set the compilation level (vLLM `-O`)

vLLM exposes compilation levels roughly `-O0` through `-O3`.

- **`-O0`** -- no compilation (closest to eager for the compile path).
- **`-O1`** -- light compilation (exact semantics vary by version; verify).
- **`-O2`** -- the typical default; enables torch.compile with the standard
  Inductor pipeline.
- **`-O3`** -- currently maps to the same behavior as `-O2` in many releases
  (verify for the installed version; do not assume `-O3` buys more).

Higher levels increase **warm-up / first-request latency** (compilation is
paid once, up front). If cold-start latency matters and the extra level buys
nothing measurable, stay at the default. Do not raise the level without
measuring both warm-up cost and steady-state gain.

## Step 3: Choose the CUDA graph capture mode

CUDA graph capture records the kernel launch sequence once and replays it,
eliminating per-launch CPU cost. Two modes:

| Mode | What it captures | When to use |
|------|------------------|-------------|
| **Piecewise** (typical default) | Splits the graph at attention -- captures the compute-dense regions, runs attention outside the graph | Safe default; works when the attention backend cannot be captured whole |
| **Full graph** | Captures the entire forward pass including attention | Lower overhead, but **only works on an attention backend that supports full capture** -- otherwise capture fails at startup |

Piecewise capture exists precisely because many attention backends are not
graph-capturable end-to-end. Before forcing full-graph capture, confirm the
selected attention backend supports it (see
`inference-attention-backend-selector`); if it does not, either accept
piecewise or switch backends deliberately.

CUDA graphs require **static shapes** -- vLLM/SGLang capture a set of batch
sizes and pad to the nearest captured size. The captured batch-size list is a
knob:

- **vLLM:** the compile/capture config controls which batch sizes are captured.
- **SGLang:** `--cuda-graph-max-bs` caps the largest captured batch size;
  capture reserves memory per captured size.

## Step 4: Persist the compile cache for cold starts

torch.compile writes its artifacts to a cache directory
(vLLM: `~/.cache/vllm/torch_compile_cache`, path is version/config specific --
verify). This cache is **portable across identical
model+GPU+engine-version+config** environments.

For autoscaling or scale-to-zero deployments where pods start cold:

1. Warm one instance once (first request triggers compilation).
2. Copy the populated cache directory into the image or a shared/mounted volume.
3. New pods read the cache and **skip recompilation**, cutting cold-start time.

The cache key includes the model, GPU, engine version, and compile config --
**any mismatch invalidates it and forces a silent recompile** (not an error, so
verify the cache actually hit by checking startup logs / first-request
latency). This is a `no-fallback-code`-style trap: a stale cache does not fail,
it just quietly recompiles and the cold-start win disappears.

## Step 5: Verify correctness against eager

Compilation and graph capture can change numerics or, worse, silently fall back
to a slower path. Before shipping:

1. Run the same prompts with `--enforce-eager` and with compile/graphs on;
   confirm outputs match within expected tolerance.
2. Confirm capture actually happened (startup logs report captured batch sizes)
   -- a failed capture that fell back to eager gives you the warm-up cost with
   none of the benefit.
3. Measure the target regime (small-batch latency for the overhead win;
   cold-start time if that was the goal).

## Verification Gate

Before claiming a compile/graph tuning result, confirm ALL:

1. Was the engine version read and the compile/graph default verified against
   it?
2. Was the target named (small-batch overhead vs cold-start latency) before
   tuning?
3. If full-graph capture was forced, was the attention backend confirmed to
   support it?
4. Was output parity checked against `--enforce-eager` (numerics unchanged)?
5. Was capture confirmed to have succeeded (logs), not silently fallen back?
6. If the compile cache was persisted, was a cache hit confirmed on a fresh
   process (not assumed)?

Any "no" = not done.

## Red Flags -- STOP if you think any of these

- "Set `-O3`, it's the highest so it's fastest" -- often identical to `-O2`;
  verify before paying extra warm-up.
- "Enable full CUDA graphs everywhere" -- fails at startup on backends that
  cannot be captured whole; piecewise exists for a reason.
- "Compilation will speed up my high-throughput batch job" -- the win is at
  small batch; dense batches barely benefit.
- "The compile cache is there, cold start is fixed" -- a config/version/GPU
  mismatch silently recompiles; confirm the hit in logs.
- "Weird numerical bug -- must be the model" -- reproduce under
  `--enforce-eager` first to rule out compile/graph before investigating.

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Compile always makes it faster" | It trades warm-up latency for steady-state overhead reduction; at high throughput the steady-state win is small. |
| "Higher `-O` is always better" | `-O3` frequently equals `-O2`; the higher level can cost warm-up with zero steady-state gain. |
| "Full graphs are strictly better than piecewise" | Only on a capturable backend; otherwise capture fails and the server will not start. |
| "The cache directory exists, so it's being used" | The cache key must match exactly; a mismatch recompiles silently -- verify the hit. |
| "Eager vs compiled outputs are obviously identical" | Compilation can shift numerics or fall back; check parity before shipping. |

## Reference

For the detailed `-O` level semantics, piecewise-vs-full capture internals, the
compile-cache key composition and portability rules, and the interaction with
custom ops / Inductor fusion, read `reference.md`.
