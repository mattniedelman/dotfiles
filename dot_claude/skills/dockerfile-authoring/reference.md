# Dockerfile Authoring -- Reference

Per-language recipes and detailed guidance. The SKILL.md body holds the
Non-Negotiables and decision logic; this file is the on-demand lookup.

## Per-language recipes

### Python (FastAPI / Flask / Django)

Multi-stage when you have native deps (psycopg, pillow, grpc) that need a
compiler. Single-stage slim is acceptable for pure-Python deps.

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential gcc libpq-dev \
 && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

FROM python:3.12-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PORT=8000
RUN apt-get update \
 && apt-get install -y --no-install-recommends libpq5 \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --system app \
 && useradd --system --gid app --no-create-home --home-dir /app app
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app/ ./app/
USER app
EXPOSE 8000
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
```

Notes:
- `PYTHONUNBUFFERED=1` so logs flush to container stdout immediately (log
  collectors need this).
- `asyncpg` (pure Python) needs neither `build-essential` nor `libpq` -- drop
  them. `psycopg`/`psycopg2` link against libpq, so keep `libpq5` at runtime.
- The `sh -c "exec ..."` wrapper is the correct way to combine env-var expansion
  (`${PORT}`) with exec-form signal handling: `exec` replaces the shell so the
  app becomes PID 1 and receives SIGTERM. A bare `CMD uvicorn ...` (shell form)
  would NOT forward signals.
- With `uv`: replace pip steps with `uv sync --frozen` against `uv.lock`.

### Node.js / TypeScript

```dockerfile
# syntax=docker/dockerfile:1

FROM node:20-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY . .
RUN npm run build

FROM node:20-bookworm-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

FROM node:20-bookworm-slim AS runtime
ENV NODE_ENV=production
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends tini \
 && rm -rf /var/lib/apt/lists/*
COPY --from=deps  --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --chown=node:node package.json ./
USER node
EXPOSE 3000
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "dist/server.js"]
```

Notes:
- `npm ci` (not `npm install`) -- installs exactly the lockfile and fails if out
  of sync. Reproducible.
- The official `node` image ships an unprivileged `node` user -- just `USER
  node`, no need to create one. `--chown=node:node` so it can read the files.
- `tini` as PID 1 reaps zombies and forwards signals; Node is a poor init.
- Set `NODE_ENV=production` so Express and friends enable production behavior.

### Go (static binary -> scratch/distroless)

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.22-bookworm AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /app /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
```

Notes:
- `CGO_ENABLED=0` produces a static binary that runs on `scratch` or
  `distroless/static`. Tiny image, minimal attack surface.
- `distroless/...:nonroot` runs as an unprivileged user by default and contains
  no shell or package manager -- nothing for an attacker to pivot through.
- Use `distroless/base` (not `static`) if you need glibc/libssl (CGO on).

### Java (JVM)

```dockerfile
# syntax=docker/dockerfile:1

FROM eclipse-temurin:21-jdk AS build
WORKDIR /src
COPY . .
RUN ./gradlew --no-daemon bootJar

FROM eclipse-temurin:21-jre AS runtime
WORKDIR /app
RUN useradd --system --no-create-home app
COPY --from=build /src/build/libs/*.jar app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

Notes:
- Build with the JDK, run with the smaller JRE.
- Modern JVMs are container-aware (respect cgroup memory/CPU limits) by default
  on JDK 11+ -- you usually do not need `-XX:MaxRAMPercentage` tuning, but set it
  if you want a non-default heap fraction.

## BuildKit secret mounts (build-time auth without leaking)

When a build needs a credential (private npm/PyPI registry, SSH key for private
git deps), use `RUN --mount=type=secret` -- the secret is mounted only for that
RUN and never enters any layer.

```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=secret,id=npm_token \
    npm config set //registry.npmjs.org/:_authToken="$(cat /run/secrets/npm_token)" \
 && npm ci \
 && npm config delete //registry.npmjs.org/:_authToken
COPY . .
RUN npm run build
```

Build invocation:

```bash
export NPM_TOKEN='...'                      # from your shell / secrets manager
docker build --secret id=npm_token,env=NPM_TOKEN -t app .
# or from a file:
docker build --secret id=npm_token,src=./npm_token.txt -t app .
```

NEVER do any of these -- the secret ends up in image history permanently:
- `ARG NPM_TOKEN` / `ENV NPM_TOKEN=...`
- `RUN echo "//registry:_authToken=$TOKEN" > .npmrc` then `COPY`/leave it
- `COPY .npmrc .` with a real token in it

If a user pastes a real secret in chat, tell them to rotate it -- it is now
compromised.

## Cache mounts (faster rebuilds, no layer bloat)

`RUN --mount=type=cache` persists a directory (package caches, build caches)
across builds without baking it into a layer.

```dockerfile
RUN --mount=type=cache,target=/root/.npm npm ci
RUN --mount=type=cache,target=/root/.cache/pip pip install -r requirements.txt
RUN --mount=type=cache,target=/go/pkg/mod go mod download
```

## HEALTHCHECK

- Under **Kubernetes**, prefer liveness/readiness probes in the pod spec; a
  Docker `HEALTHCHECK` is redundant and ignored by k8s.
- Under **plain Docker / Compose**, add a `HEALTHCHECK` so the orchestrator
  knows when the container is actually serving.

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:8000/healthz || exit 1
```

Point it at a real health endpoint, not `/`, to avoid coupling health to app
routing. If `curl` is not in the image, use a language-native check (e.g.
`python -c "import urllib.request,sys; ..."`).

## Image-size tactics

- Prefer `-slim` Debian variants; use `distroless` or `scratch` for compiled
  static binaries.
- Alpine is small but uses musl libc -- prebuilt Python/Node wheels target glibc
  (`manylinux`), so Alpine can trigger slow source builds and subtle runtime
  differences. Prefer `-slim` (glibc) unless you have measured a real benefit.
- Combine `apt-get update && install && rm -rf /var/lib/apt/lists/*` in ONE
  `RUN` -- otherwise the apt cache persists in an earlier layer.
- `--no-install-recommends` on apt; `--no-cache-dir` on pip.
- Multi-stage: never let compilers/dev-deps into the runtime stage.
- Order layers least-changing -> most-changing for cache reuse.

## Linting

Run `hadolint Dockerfile` if available -- it mechanically catches unpinned base
images, missing `--no-install-recommends`, shell-form pitfalls, and more. CI
should fail on hadolint errors.

## Full annotated checklist

Correctness / reproducibility:
- [ ] `# syntax=docker/dockerfile:1` first line (enables BuildKit features)
- [ ] Base image pinned to a version tag (digest for full reproducibility)
- [ ] Lockfile-based, deterministic dependency install (`npm ci`, `pip` against
      pinned requirements / `uv sync --frozen`, `go mod download`)
- [ ] Dependency manifests copied + installed BEFORE source copy (cache)

Security:
- [ ] Runs as non-root `USER` before `CMD`
- [ ] No secrets in `ENV`/`ARG`/`RUN`/`COPY`; build-time auth via
      `--mount=type=secret`
- [ ] `.dockerignore` excludes `.git`, `.env`, secrets, deps, build output
- [ ] Minimal base (slim/distroless/scratch); no unnecessary packages
- [ ] apt cache removed in the same `RUN`

Runtime behavior:
- [ ] Exec-form `CMD`/`ENTRYPOINT` (JSON array) for signal handling
- [ ] PID 1 handled (exec form, or `tini`/init for multi-process)
- [ ] `EXPOSE` documents the listen port
- [ ] App binds `0.0.0.0`, not `127.0.0.1` (else unreachable from host)
- [ ] `HEALTHCHECK` for plain Docker/Compose (k8s uses pod probes instead)
- [ ] Logs go to stdout/stderr (e.g. `PYTHONUNBUFFERED=1`)

Build hygiene:
- [ ] Multi-stage to keep toolchain out of runtime image
- [ ] Cache mounts for package managers where helpful
- [ ] `hadolint` clean
