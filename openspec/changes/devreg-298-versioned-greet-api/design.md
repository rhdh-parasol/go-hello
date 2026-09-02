## Canonical Touchpoints

No canonical document updates. No existing PRD, ADR, or long-lived capability specs exist in this repository.

## Context

`go-hello` is a minimal Go HTTP service with two routes (`GET /health`, `GET /greet`), no input validation, no API versioning, no structured logging, and a bare `http.ListenAndServe` that does not drain in-flight requests on shutdown. The service uses only the Go standard library (Go 1.22, `go.mod` module `github.com/rhdh-parasol/go-hello`). The change adds production-shaped features across four concerns: versioned API, Kubernetes probes, structured logging, and documentation.

## Goals / Non-Goals

**Goals:**

- Add a versioned `POST /v1/greet` with JSON body validation alongside the existing `GET /greet`
- Separate liveness (`/live`) from readiness (`/ready`) with graceful shutdown integration
- Emit structured JSON logs per request with request-ID correlation
- Provide OpenAPI 3.0 spec and updated README for the new surface
- Stay stdlib-only (no external dependencies)

**Non-Goals:**

- Authn/authz, TLS, rate limiting
- Persistence or greeting history
- Prometheus metrics
- Removing or modifying existing `GET /greet` or `GET /health` endpoints

## Decisions

### 1. Use `log/slog` for structured logging (stdlib, Go 1.22+)

**Rationale:** `log/slog` ships with Go 1.21+ and provides structured JSON output with `slog.NewJSONHandler`. This avoids adding `go.uber.org/zap` or `rs/zerolog` as external dependencies while meeting all logging requirements.

**Alternatives considered:**
- `go.uber.org/zap` — battle-tested but adds a dependency for a feature stdlib now covers
- `log.Printf` with manual JSON marshaling — fragile and error-prone

### 2. Generate request IDs with `crypto/rand` (16-byte hex)

**Rationale:** A 32-character hex string from `crypto/rand` provides sufficient uniqueness for request correlation without importing a UUID library. Standard library only.

**Alternatives considered:**
- `github.com/google/uuid` — adds an external dependency
- Sequential counter — not unique across restarts or replicas

### 3. Route layout: add `/v1/greet`, `/live`, `/ready` alongside existing routes

**Rationale:** The existing `GET /health` and `GET /greet` remain untouched for backward compatibility. New routes are additive. The `/v1` prefix establishes a versioning convention for future API evolution without disrupting current consumers.

**Alternatives considered:**
- Replace `GET /greet` with `POST /v1/greet` — breaks existing callers
- Alias `/health` to `/live` — conflates different probe semantics (health reports version/timestamp; liveness is a simple 200)

### 4. Graceful shutdown via `http.Server.Shutdown` with `os/signal.NotifyContext`

**Rationale:** `http.Server.Shutdown` is the stdlib mechanism for graceful drain. Combined with `os/signal.NotifyContext`, it provides clean signal handling and context-based timeout. A readiness flag (`atomic.Bool`) flips to false on signal, making `/ready` return 503 while `/live` stays 200.

**Alternatives considered:**
- Manual `net.Listener.Close` — loses in-flight request draining
- Third-party graceful libraries — unnecessary given stdlib support

### 5. Middleware as a handler wrapper function

**Rationale:** A single `func loggingMiddleware(next http.Handler) http.Handler` wraps the mux. This is the idiomatic Go pattern for cross-cutting concerns. It generates the request ID, injects it into the response header, records timing, and logs after the response completes using a `responseWriter` wrapper that captures the status code.

### 6. OpenAPI file at repo root as `openapi.yaml`

**Rationale:** Repo root is the conventional location for small single-service projects. Keeps the spec discoverable without a `docs/` directory hierarchy.

## Risks / Trade-offs

- **[`log/slog` output format]** `slog.NewJSONHandler` field names differ from some log aggregators' defaults (e.g., `time` vs `ts`). → Mitigation: Use `slog.HandlerOptions` with `ReplaceAttr` to rename `time` → `ts` and `msg` → `msg`, ensuring the spec-required field names.

- **[Shutdown race on readiness flip]** A request arriving between the signal and the readiness flag flip could see a 200 from `/ready` then immediately get connection-refused. → Mitigation: Flip the atomic flag before calling `Server.Shutdown`; the window is negligible in practice.

- **[No external linting of OpenAPI in CI]** `npx @redocly/cli lint` requires Node.js in CI. → Mitigation: Add a Makefile target `make lint-openapi` that the CI workflow can call; document the prerequisite.

- **[`responseWriter` wrapper completeness]** The status-capturing wrapper must implement `http.Flusher` and `http.Hijacker` if needed by downstream handlers. → Mitigation: For this simple service, only `WriteHeader` and `Write` delegation is needed; add interface assertions if extended.
