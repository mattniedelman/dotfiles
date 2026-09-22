---
name: dockerfile-authoring
description: Use when writing, reviewing, or fixing a Dockerfile or container image build, including quick prototypes and "just make it build" requests, before declaring the Dockerfile done
when_to_use: Triggers on any request to write a Dockerfile, containerize an app, optimize image build speed or size, fix a slow or broken build, add private-registry or secret auth to a build, or review an existing Dockerfile. Applies even under time pressure ("quick", "demo", "harden later") and to minimal one-line fixes.
metadata:
  author: mattniedelman
  version: "1.0.0"
---

# Dockerfile Authoring

## Overview

A Dockerfile is shipped infrastructure, not scratch code. The image you build
runs in production, gets scanned for CVEs, and sits in a registry for months.
The cost of doing it wrong -- root containers, leaked secrets in layers,
non-reproducible builds, 2 GB images -- is paid by everyone who pulls it, not
by the author.

**Core principle:** Every Dockerfile ships with the non-negotiables. Speed and
simplicity are achieved by knowing the patterns, not by dropping the baseline.

**Announce at start:** "I'm using the Dockerfile Authoring skill."

This is a **rigid** skill for the Non-Negotiables below and **flexible** for
optimization choices. Violating the letter of the Non-Negotiables is violating
the spirit of the skill.

## The Non-Negotiables

These ship in EVERY Dockerfile, including prototypes, demos, and one-line fixes.
There is no "harden it later" -- later never comes, and the prototype becomes
production.

1. **Pin the base image to a specific version tag.** Never `latest`, never a
   bare `python` / `node`. Use `python:3.12-slim`, `node:20-bookworm-slim`. For
   reproducible builds, pin a digest (`@sha256:...`). A moving tag means a build
   that passed yesterday can break or change behavior today with no diff.

2. **Run as a non-root user.** Create or use an unprivileged user and `USER` it
   before `CMD`. A process compromise should not start as root inside the
   container. Official images often ship a user (`node`); otherwise create one.

3. **Use exec-form CMD/ENTRYPOINT.** `CMD ["python", "app.py"]`, never
   `CMD python app.py`. Shell form wraps the process in `/bin/sh -c`, which does
   NOT forward `SIGTERM` -- `docker stop` and Kubernetes hang for the full grace
   period then hard-kill, skipping graceful shutdown. (When you need a shell for
   env expansion, use `exec` inside it -- see reference.)

4. **Ship a `.dockerignore`.** At minimum exclude `.git`, `.env`, secrets,
   `node_modules`, `__pycache__`, `.venv`, build output, and test artifacts.
   Without it the entire working tree -- including secrets -- enters the build
   context and may land in layers.

5. **Never bake secrets into the image.** No tokens, passwords, or keys in `ENV`,
   `ARG`, `RUN echo > .npmrc`, or `COPY`ed credential files. Secrets are injected
   at runtime (env / orchestrator / secrets manager) or, at build time, via
   `RUN --mount=type=secret`. A secret in any layer is in the image forever, even
   if a later layer deletes it. If a user pastes a real secret, tell them to
   rotate it.

If you are about to skip one of these, STOP and read the Red Flags section.

## Build Order: cache-friendly by default

Layers are cached top-down and invalidated by the first changed instruction.
Copy what changes least, first; what changes most (source code), last.

```dockerfile
# dependency manifests first -- only re-installs when deps change
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# source last -- a code edit invalidates only the cheap copy below
COPY . .
```

The wrong order (`COPY . .` before install) re-runs the full dependency install
on every source edit. This is the single most common cause of slow rebuilds.

## Multi-stage builds for compiled / build-step languages

When a build needs a toolchain (compilers, dev dependencies, TypeScript) that
the runtime does not, use multi-stage: build in a fat stage, copy only the
artifacts into a slim runtime stage. This removes the toolchain from the final
image -- smaller image AND smaller attack surface. See `reference.md` for full
per-language recipes.

## The Decision: when "minimal" or "quick" tempts a shortcut

This is the `do-it-right` decision point for Dockerfiles. When asked for a quick
fix or a minimal change:

- The Non-Negotiables are NOT optional scope. A "minimal fix" for slow rebuilds
  still pins the base image -- an unpinned `latest` you noticed is a finding you
  fix, not a "separate concern" you defer.
- Optimization depth (multi-stage, cache mounts, digest pinning) CAN scope to
  the request. A prototype need not be multi-stage; it must still be pinned,
  non-root, exec-form, with a `.dockerignore`.
- If you genuinely must defer something, say so explicitly and name it -- do not
  silently ship a worse Dockerfile.

## Verification Gate

Before claiming a Dockerfile is done, confirm ALL:

1. Base image pinned to a specific version (not `latest`, not bare)?
2. Runs as a non-root `USER`?
3. `CMD`/`ENTRYPOINT` in exec form (JSON array)?
4. `.dockerignore` present and excludes secrets + VCS + deps?
5. No secret in any `ENV`/`ARG`/`RUN`/`COPY`?
6. Dependency install ordered before source copy for cache?
7. If a build toolchain is involved, is it kept out of the runtime stage?

Any "no" without an explicit, stated deferral = not done. Run `hadolint
Dockerfile` if available -- it catches most of these mechanically.

## Red Flags -- STOP if you think any of these

- "We can harden it later" / "just make it build for now"
- "It's only a prototype / demo"
- "Keep it minimal, that's a separate concern" (about a Non-Negotiable)
- "The base image version doesn't matter for this"
- "Running as root is fine inside a container"
- "Shell-form CMD is simpler"
- Putting a token in `ENV`/`ARG` "just to get the build working"

Each of these is the exact rationalization that ships a broken image. The
Non-Negotiables take seconds when you know the patterns.

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "We're in a hurry, harden later" | The non-negotiables are 5 lines. "Later" is the next incident. The prototype IS what ships. |
| "It's just a demo" | Demos get committed, forked, and copied into the real service. Set the pattern correctly now. |
| "Keep the fix minimal" | Minimal scope applies to optimization depth, not to pinning, non-root, or exec form. Those are baseline, not scope. |
| "`latest` is fine, it works now" | `latest` moves. The build that works now silently breaks later with no diff to blame. |
| "Root is fine, it's isolated" | Container escape + root = host root. Non-root is one `USER` line. |
| "Shell form is simpler" | Shell form breaks SIGTERM forwarding -- graceful shutdown silently stops working. Exec form is the same length. |
| "I'll just ARG the token to test" | ARG and ENV values persist in image history forever. Use `--mount=type=secret`. |
| "No time for a .dockerignore" | Without it your `.env` and `.git` enter the build context. One file prevents a leak. |

## Reference

For per-language recipes (Python, Node, Go, Java), BuildKit secret mounts, cache
mounts, `HEALTHCHECK` guidance, image-size tactics, and the full annotated
checklist, read `reference.md` in this skill directory.
