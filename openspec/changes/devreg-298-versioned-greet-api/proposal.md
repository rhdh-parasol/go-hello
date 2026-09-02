## Why

The `go-hello` service currently exposes only `GET /health` and `GET /greet?name=` with no input validation, no API versioning, no readiness probe distinct from liveness, no structured logging, and no graceful shutdown. This limits its usefulness as a production-shaped sample and prevents Kubernetes operators from distinguishing pod health from traffic readiness.

## What Changes

- Add `POST /v1/greet` endpoint accepting JSON `{"name":"..."}` with input validation (1-64 chars, trimmed); returns `{"message":"Hello, <name>!", "name":"<name>"}` on success, 400 with stable error shape on invalid input
- Add `GET /live` (liveness) and `GET /ready` (readiness) probe endpoints; readiness returns 503 after shutdown signal
- Implement graceful shutdown on SIGTERM/SIGINT: flip readiness, drain in-flight requests within configurable timeout (`SHUTDOWN_TIMEOUT`), exit 0
- Add structured JSON request logging middleware with `ts`, `level`, `method`, `path`, `status`, `duration_ms`, `request_id` fields; return `X-Request-ID` response header
- Create OpenAPI 3 spec (`openapi.yaml`) for new endpoints
- Update README with new routes, env vars, log format, and production readiness notes
- Existing `GET /health` and `GET /greet` remain unchanged

## Non-goals

- Authentication, authorization, TLS, or rate limiting
- Persistence or greeting history
- Prometheus metrics exporters
- Removing or modifying the existing `GET /greet` endpoint

## Capabilities

### New Capabilities

- `versioned-greet-api`: POST /v1/greet endpoint with JSON body validation and versioned response contract
- `kubernetes-probes`: Liveness and readiness probe endpoints with graceful shutdown integration
- `structured-logging`: JSON request logging middleware with request ID correlation

### Modified Capabilities

None

## Canonical Touchpoints

None. This repo has no `specifications/` or `openspec/specs/` documents. Change type: feature-spec.

## Impact

- `main.go`: Major changes — new handlers, middleware, graceful shutdown, signal handling
- `main_test.go`: New tests for all new endpoints and validation cases
- `go.mod`: No new dependencies (uses `log/slog` and `crypto/rand` from Go 1.22 stdlib)
- `openapi.yaml`: New file
- `README.md`: Updated documentation
- `Makefile`: Possible addition of `lint-openapi` target
