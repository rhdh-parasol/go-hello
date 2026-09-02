## Canonical Touchpoints

None. No canonical document updates — this repo has no `specifications/` or `openspec/specs/` documents.

## Context

`go-hello` is a minimal Go HTTP service (Go 1.22, stdlib-only) with two handlers (`/health`, `/greet`) registered on `http.NewServeMux`. The service uses `log.Printf` for startup output and `http.ListenAndServe` with no shutdown handling. All changes will stay stdlib-only, leveraging `log/slog` (Go 1.22), `crypto/rand`, `context`, `os/signal`, and `net/http` server shutdown capabilities.

## Goals / Non-Goals

**Goals:**
- Add a versioned JSON greet endpoint with input validation
- Separate liveness from readiness probes
- Enable graceful shutdown with configurable drain timeout
- Replace unstructured logging with JSON structured logs
- Document new endpoints via OpenAPI 3 and README updates

**Non-Goals:**
- External dependencies (no zap, chi, gorilla, etc.)
- Authentication, TLS, rate limiting
- Metrics exporters
- Removing existing endpoints

## Decisions

### 1. Stdlib-only: use `log/slog` for structured logging
**Rationale**: Go 1.22 includes `log/slog` with JSON handler. Avoids adding dependencies to go.mod. The refine plan's open question about `zap` vs `slog` is resolved in favor of `slog` for zero external deps.
**Alternative**: `go.uber.org/zap` — more features but unnecessary for this scope.

### 2. Request ID via `crypto/rand` (16-byte hex)
**Rationale**: 32-character hex string is sufficiently unique for request correlation without importing a UUID library. Uses the secure `crypto/rand` reader.
**Alternative**: `google/uuid` — adds a dependency for no material benefit here.

### 3. Middleware pattern: wrap `http.Handler`
**Rationale**: A single `loggingMiddleware(next http.Handler) http.Handler` function wraps the entire mux. Uses a `responseWriter` wrapper to capture status code. This is idiomatic Go middleware without a framework.

### 4. Graceful shutdown via `http.Server.Shutdown`
**Rationale**: The stdlib `Shutdown` method stops new connections and drains in-flight requests. We use `signal.NotifyContext` for clean signal handling. An `atomic.Bool` tracks readiness state for the `/ready` endpoint.

### 5. File organization: keep single `main.go`
**Rationale**: The service is small enough that splitting into packages adds complexity without benefit. All handlers, middleware, and types stay in `main.go`. Tests stay in `main_test.go`.

### 6. OpenAPI at repo root as `openapi.yaml`
**Rationale**: Repo root is discoverable. The refine plan asked about root vs `docs/` — root is simpler and conventional for small services.

## Risks / Trade-offs

- [Single-file growth] → Acceptable for this service size; refactor if it exceeds ~400 lines.
- [`atomic.Bool` for readiness] → Simple but only supports binary state. Acceptable for liveness/readiness; a more complex health-check system would need a different pattern.
- [No `Content-Type` check on other endpoints] → Only `/v1/greet` validates `Content-Type`; existing endpoints are unaffected.
