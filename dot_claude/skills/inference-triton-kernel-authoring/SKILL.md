---
name: inference-triton-kernel-authoring
description: "Author, integrate, and tune custom Triton kernels for vLLM/SGLang-style inference so they dispatch correctly per hardware, survive torch.compile, and are validated against a reference before shipping; use when writing or debugging a Triton kernel, wiring a custom op into an engine with a native fallback, fixing a kernel that gets fused away under compile, or profiling and autotuning a kernel"
when_to_use: "Triggers on: 'write a Triton kernel for X', 'my custom op is ignored under torch.compile', 'CustomOp / forward_native fallback', 'tl.atomic_add on bf16 fails', 'online softmax / exp2 trick', 'autotune this kernel', 'kernel is correct in eager but wrong/fused under compile', or profiling a kernel with Nsight Compute. Applies to authoring/integrating/tuning kernels, not to picking a prebuilt attention backend (see inference-attention-backend-selector)."
metadata:
  author: mattniedelman
  version: "1.0.0"
---

# Inference Triton Kernel Authoring

## Overview

A custom Triton kernel that is numerically correct in isolation still fails in
an inference engine for three recurring reasons: it does not dispatch on the
hardware it was meant for (no fallback for other GPUs), torch.compile fuses past
it or disables it, or it was never validated against a reference implementation
so a subtle indexing/precision bug ships silently. This skill is about
**integration and validation discipline**, not just kernel math -- the math is
the easy part to get locally right and the hard part to get right in the
engine.

**Core principle:** A kernel is not done when it produces plausible output. It
is done when it (1) dispatches correctly per platform with a working fallback,
(2) behaves identically under `torch.compile` and eager, and (3) matches a
reference implementation within tolerance on real shapes. Skipping any of these
is a `no-fallback-code` / `do-it-right` violation: it looks like it works.

**Announce at start:** "I'm using the Inference Triton Kernel Authoring skill."

## Step 0: Establish the toolchain versions (do not skip)

Triton, PyTorch, and the engine all gate kernel behavior, and the
custom-op/compile integration API changes across versions. Read them before
writing integration code:

```bash
python -c "import triton, torch; print('triton', triton.__version__, '/ torch', torch.__version__)"
python -c "import vllm; print(vllm.__version__)"     # or sglang
nvidia-smi --query-gpu=name,compute_cap --format=csv   # target arch(s)
```

Kernel features (e.g. supported dtypes for atomics, TMA, wgmma paths) depend on
both Triton version and GPU compute capability -- verify, do not assume.

## Step 1: Write the kernel against a reference, not from scratch faith

Before optimizing, have a **reference implementation** (plain PyTorch) that
defines correct output. The Triton kernel is validated against it -- this is
the guardrail that catches the silent-wrong-output failure mode.

Common correctness patterns to get right:

- **Online softmax / numerically stable reductions:** use the running-max
  rescaling formulation. Triton computes exponentials with `exp2` (base-2) for
  hardware efficiency -- scale logits by `log2(e)` so `exp2(x * log2e) == exp(x)`.
  Getting this scale factor wrong yields wrong attention weights -- omitting it
  entirely (`exp2(x)` == `2^x` not `e^x`) usually collapses the softmax toward
  all-zero or all-one, while a subtler misapplication gives a systematic bias
  that passes casual inspection. Either way, only the reference comparison
  catches it.
- **Atomics dtype limits:** `tl.atomic_add` does **not** support BF16 on common
  targets. Accumulate in FP32 (or use a supported dtype) and cast on store, or
  restructure to avoid the atomic. Never assume a BF16 atomic works because it
  compiled -- behavior varies by version; validate against the reference.
- **Masking at boundaries:** guard every load/store with a `mask=` against the
  real dimension so tail blocks do not read/write out of bounds. Off-by-one
  masking is the classic Triton bug and it often only shows on non-power-of-two
  shapes.

## Step 2: Integrate with a per-platform dispatch and a native fallback

An inference engine runs on many GPUs; a kernel tuned for one arch must not be
the only path. Follow the CustomOp pattern the engines use:

- Implement the optimized path (the Triton kernel) AND a **`forward_native`**
  PyTorch fallback.
- Dispatch per platform: select the Triton path only on the arch(es) it
  supports; fall back to `forward_native` elsewhere. Never leave a kernel that
  silently produces garbage on an unsupported arch.
- The fallback must be a **real, correct implementation**, not a stub that
  returns zeros or a hardcoded shape (that is exactly the `no-fallback-code`
  trap this skill exists to prevent).

## Step 3: Make the kernel survive torch.compile

This is the step most often missed. In compile mode, Inductor may **disable
framework CustomOps and fuse the equivalent computation into its own generated
Triton kernels** -- meaning your hand-written kernel silently does not run.

- To force compile to trace *into* and preserve your kernel, register it as a
  custom op that the compiler treats as opaque:
  **`torch.library.triton_op`** (with `torch.library.wrap_triton` for the
  kernel launch), so Inductor calls your kernel instead of fusing past it. This
  API stabilized in a recent PyTorch (roughly 2.4+) -- **verify the installed
  torch version**; older installs use the `torch.library.custom_op` /
  `Library`-based registration pattern instead.
- Symptom of getting this wrong: the kernel is correct under `--enforce-eager`
  but the numbers change (or your kernel's profiler markers vanish) once compile
  is on. See `inference-cuda-graph-compile-tuning` for the eager-vs-compile
  parity check.

Always run the eager-vs-compiled parity test (Step 5) -- it is the only reliable
detector of a fused-away kernel.

## Step 4: Profile, then autotune (in that order)

Do not autotune blind. Profile first to find the actual bottleneck:

- **Nsight Compute (`ncu`)** for kernel-level analysis: occupancy, memory
  throughput, whether the kernel is memory- or compute-bound. The profile tells
  you which knobs matter.
- Then use Triton's **`@triton.autotune`** over a `configs` list
  (`BLOCK_SIZE`, `num_warps`, `num_stages`) keyed on the shape dimensions that
  change the optimal config. Autotune caches per key -- so the first call per
  new shape pays the search cost (relevant to cold start).
- Re-profile after autotuning to confirm the chosen config actually moved the
  bottleneck you identified, rather than trusting the autotuner's timing alone.

## Step 5: Validate before shipping (the gate that catches silent bugs)

1. **Reference parity:** compare kernel output to the PyTorch reference across a
   range of real shapes (including non-power-of-two and tail cases) within a
   documented tolerance. Not "it ran" -- numerically equal.
2. **Eager vs compiled parity:** run the same inputs under `--enforce-eager` and
   under `torch.compile`; outputs must match, proving the kernel is not fused
   away.
3. **Fallback parity:** confirm `forward_native` produces the same result as the
   Triton path (within tolerance) on a shared shape, so the dispatch is
   transparent.
4. **Arch dispatch:** confirm the Triton path is selected on target arch and the
   fallback is selected elsewhere -- not the reverse.

## Verification Gate

Before claiming a kernel is done, confirm ALL:

1. Were Triton/torch/engine versions and target compute capability read, not
   assumed?
2. Does a PyTorch reference exist, and does the kernel match it within tolerance
   on real + tail shapes?
3. Is there a correct `forward_native` fallback and correct per-arch dispatch
   (not a stub, not garbage on unsupported arches)?
4. Does the kernel run (not get fused away) under torch.compile, verified by
   eager-vs-compiled parity?
5. Was profiling done before autotuning, and re-checked after?

Any "no" = not done.

## Red Flags -- STOP if you think any of these

- "It produces reasonable-looking numbers, ship it" -- reasonable-looking is not
  reference-equal; softmax/index bugs look reasonable.
- "It works in eager, so it works" -- compile may fuse it away; the numbers can
  change with no error.
- "One GPU is fine, everyone uses H100" -- an engine kernel needs a fallback for
  other arches or it silently breaks them.
- "`tl.atomic_add` in bf16 is fine" -- unsupported on common targets; accumulate
  in fp32.
- "Autotune will find the best config" -- autotune optimizes timing over a
  config list; it will not tell you the kernel is memory-bound. Profile first.

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The kernel math is right, integration is trivial" | Dispatch + compile-survival + fallback are where inference kernels actually break. |
| "No reference needed, I can eyeball correctness" | Online-softmax scale and tail masking bugs pass the eyeball test and fail the eval. |
| "torch.compile only makes things faster" | It can disable/fuse your CustomOp so your kernel never runs -- verify eager-vs-compiled parity. |
| "The fallback can just return zeros for now" | That is a silent-wrong-output fallback -- the exact `no-fallback-code` violation. Write the real path. |
| "Autotuning is optimization" | Autotuning without profiling optimizes the wrong thing; profile to find the bottleneck first. |

## Reference

For the online-softmax `exp2`/`log2(e)` derivation, the CustomOp +
`forward_native` dispatch skeleton, the `torch.library.triton_op` /
`wrap_triton` registration pattern, atomic-dtype support notes, and an
autotune-config template, read `reference.md`.
