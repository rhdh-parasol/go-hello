## Why

`go-hello` currently exposes only `GET /health` and `GET /greet?name=` with no input validation, no API versioning, no readiness probe distinct from liveness, no structured logging, and no graceful shutdown. This makes it unsuitable as a production-shaped HTTP API reference. Adding these layers now provides a realistic Go service surface for dogfooding the fullsend Jira-poller workflow.

## What Changes

- Add `POST /v1/greet` endpoint accepting JSON `{"name":"..."}` with input validation (1–64 chars, trimmed); returns `{"message":"Hello, <name>!", "name":"<name>"}` on 200, or a stable `{"error":"...", "message":"..."}` shape on 400. The existing `GET /greet` remains unchanged.
- Add `GET /live` (always 200 while process is up) and `GET /ready` (200 while accepting traffic, 503 after shutdown signal). Keep `GET /health` as-is.
- Implement graceful shutdown: on SIGTERM/SIGINT, flip readiness to false, drain in-flight requests within a configurable timeout (`SHUTDOWN_TIMEOUT`, default 15 s), then exit 0.
- Add structured JSON request logging middleware using `log/slog` (stdlib Go 1.22+): each request emits one JSON line with `ts`, `level`, `method`, `path`, `status`, `duration_ms`, `request_id`. Return `X-Request-ID` response header.
- Add `openapi.yaml` (OpenAPI 3.0) documenting `/v1/greet`, `/live`, `/ready`.
- Update `README.md` with new routes, env vars, log format example, and OpenAPI reference.

## Non-goals

- Authn/authz, TLS, rate limiting
- Persistence or greeting history
- Prometheus metrics exporters
- Removing or modifying the existing `GET /greet` or `GET /health` endpoints
- External dependencies beyond the Go standard library

## Capabilities

### New Capabilities

- `versioned-greet-api`: POST /v1/greet endpoint with JSON body validation and versioned response contract
- `kubernetes-probes`: Separate liveness and readiness probe endpoints with graceful shutdown integration
- `structured-logging`: JSON request logging middleware with request-ID correlation
- `api-documentation`: OpenAPI 3.0 spec and README documentation for new endpoints

### Modified Capabilities

_(none — no existing specs in `openspec/specs/`)_

## Canonical Touchpoints

None. No existing PRD, ADR, or long-lived capability specs exist in this repository.

Change type: **feature-spec**

## Impact

- **Code**: `main.go` gains new handlers, middleware, and shutdown logic; `main_test.go` expands significantly
- **APIs**: New routes `/v1/greet` (POST), `/live` (GET), `/ready` (GET) added alongside existing routes
- **Dependencies**: None added — uses only Go 1.22+ stdlib (`log/slog`, `crypto/rand`, `context`, `os/signal`)
- **Ops**: Kubernetes manifests (if any) should point probes at `/live` and `/ready`; log parsers should expect JSON on stdout
