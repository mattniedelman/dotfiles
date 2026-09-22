# CUDA Graph / torch.compile Reference (2026 primary-source snapshot)

> Reflects vLLM (`docs.vllm.ai/en/latest/design/torch_compile/` and the
> compilation-config docs) and SGLang (`docs.sglang.io` hyperparameter /
> server-args pages) as of mid-2026. Compilation levels, capture modes, and
> cache paths change between minor releases -- **re-verify against the installed
> engine version.**

## Why launch overhead matters (the whole premise)

At small batch sizes the GPU finishes each kernel faster than the CPU can
enqueue the next one, so the GPU idles between launches. torch.compile reduces
the number of ops (fusion) and CUDA graphs eliminate the per-launch CPU cost by
replaying a recorded launch sequence. Both wins **shrink as batch size grows**
because dense batches already keep the GPU busy. Tune for the batch-size regime
you actually serve.

## vLLM compilation levels (`-O` / `compilation_config`)

| Level | Behavior |
|-------|----------|
| `-O0` | No torch.compile; closest to eager on the compile path. |
| `-O1` | Light compilation (verify semantics for the installed version). |
| `-O2` | Typical default: torch.compile with the standard Inductor pipeline. |
| `-O3` | In many releases maps to the same behavior as `-O2` -- do NOT assume it buys more. Verify. |

Compilation cost is paid **once at warm-up / first request**. Higher levels
raise first-request latency in exchange for steady-state gains that may or may
not materialize. Measure both sides before raising the level.

`--enforce-eager` disables torch.compile AND CUDA graph capture together. It is
the master off-switch and the first diagnostic step for any suspected
compile/graph bug (tracebacks then point at the real op, not `graph.replay()`).

## CUDA graph capture modes

### Piecewise (typical default)

The compiled graph is split at attention. Compute-dense regions are captured
and replayed; attention runs outside the captured region. This exists because
many attention backends are not capturable end-to-end. Piecewise is the safe
default and works with the widest set of backends.

### Full graph

Captures the entire forward pass including attention. Lower per-step overhead
than piecewise, but requires an attention backend that supports full capture.
On an unsupported backend, capture **typically fails loudly -- at startup or on
the first capture attempt** (a hard error, not a silent fallback), though
whether it surfaces at startup vs first forward is version/backend specific.
Confirm backend support (see `inference-attention-backend-selector`) before
forcing full capture.

### Static shapes and captured batch sizes

CUDA graphs record fixed tensor shapes, so the engine captures a discrete set
of batch sizes and pads runtime batches up to the nearest captured size.

- **vLLM:** the compilation/capture config controls which batch sizes are
  captured (a list). More captured sizes = less padding waste but more capture
  time and more reserved memory.
- **SGLang:** `--cuda-graph-max-bs` bounds the largest captured batch size.
  `--disable-cuda-graph` turns capture off entirely.

Each captured size reserves memory at load time -- graph capture is a
contributor to **load-time OOM** (see `inference-oom-triage`); reducing the
captured-size set or using `--enforce-eager` frees that reservation.

## The compile cache (cold-start optimization)

torch.compile persists compiled artifacts to a cache directory. For vLLM this
is typically `~/.cache/vllm/torch_compile_cache` (path is version/config
specific -- verify against the installed version).

### Portability and the cache key

The cache is reusable across processes ONLY when the full key matches:

- model (architecture + weights identity)
- GPU (compute capability / device)
- engine version
- compile configuration (level, captured sizes, dtype, etc.)

Any mismatch produces a **silent recompile** -- not an error. The server starts
fine and simply pays the compilation cost again, so the cold-start win
disappears without any signal. Confirm a cache hit by watching startup logs and
first-request latency on a fresh process; do not assume the directory's mere
existence means it was used (`no-fallback-code` trap).

### Cold-start workflow (autoscaling / scale-to-zero)

1. Warm one instance -- the first request triggers full compilation.
2. Copy the populated cache directory into the container image or a
   shared/mounted volume.
3. New pods read the cache and skip recompilation.

Because the key includes the engine version and compile config, **rebuild the
warmed cache whenever any of those change** or new pods will silently recompile.

## Interaction with custom ops and Inductor fusion

In compile mode, Inductor may bypass framework CustomOps that lack a
compile-aware registration (no abstract / FakeTensor impl) and fuse the
equivalent computation into generated Triton kernels -- the exact behavior
(skip, decompose, or invoke fallback) is version specific. A custom op that must
run as-authored (e.g. a hand-tuned Triton kernel) has to be registered so
compile traces into it rather than fusing past it: `torch.library.triton_op`
(with `wrap_triton`) works because it supplies the schema + abstract impl that
makes the compiler treat the kernel as an opaque op it calls, instead of an
unregistered op it can fuse away (see `inference-triton-kernel-authoring`). If a
custom kernel "does nothing" under compile but works under `--enforce-eager`,
suspect that Inductor fused it out.

## Decision quick-path

1. Small-batch / interactive latency is the goal -> enable compile + CUDA
   graphs (default piecewise).
2. Debugging a crash or a new model/kernel -> `--enforce-eager` first.
3. Forcing full-graph capture -> confirm attention backend supports it, else
   stay piecewise.
4. Frequent cold starts -> warm once, ship the compile cache, verify the hit.
5. Load-time OOM at capture -> reduce captured batch sizes / `--cuda-graph-max-bs`
   or `--enforce-eager` (see `inference-oom-triage`).
6. High-throughput batch job -> enable, but expect a small win; do not over-tune.
