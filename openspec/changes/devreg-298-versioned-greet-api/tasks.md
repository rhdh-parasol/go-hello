<!-- After each completed task, commit the changes. -->

## 1. Structured Logging Middleware

- [x] 1.1 Replace `log` import with `log/slog` and add a JSON handler; convert startup log to structured JSON via slog
- [x] 1.2 Implement `loggingMiddleware(next http.Handler) http.Handler` that generates a request ID (16-byte hex via `crypto/rand`), sets `X-Request-ID` response header, captures status code via a responseWriter wrapper, and emits one JSON log line per request with `ts`, `level`, `method`, `path`, `status`, `duration_ms`, `request_id`
- [x] 1.3 Wrap the mux with the logging middleware in `main()`

## 2. POST /v1/greet Endpoint

- [x] 2.1 Add `GreetRequest` struct and `ErrorResponse` struct types
- [x] 2.2 Implement `v1GreetHandler` that validates Content-Type is `application/json`, parses JSON body, trims and validates name (1-64 chars), returns 200 with `GreetResponse` or 400 with `ErrorResponse`
- [x] 2.3 Register `POST /v1/greet` on the mux (using Go 1.22 method+path pattern `POST /v1/greet`)

## 3. Liveness and Readiness Probes with Graceful Shutdown

- [x] 3.1 Add an `atomic.Bool` for readiness state (initially true); implement `liveHandler` (always 200) and `readyHandler` (200 when ready, 503 when shutting down)
- [x] 3.2 Register `/live` and `/ready` on the mux
- [x] 3.3 Replace `http.ListenAndServe` with `http.Server` + `signal.NotifyContext` for SIGTERM/SIGINT; on signal, flip readiness to false, call `server.Shutdown` with configurable timeout from `SHUTDOWN_TIMEOUT` env var (default 15s), then exit 0

## 4. OpenAPI 3 Specification

- [x] 4.1 Create `openapi.yaml` at repo root documenting `POST /v1/greet`, `GET /live`, `GET /ready` with request/response schemas, examples, and error shapes

## 5. Documentation

- [x] 5.1 Update `README.md` endpoints table with `/v1/greet`, `/live`, `/ready`; add `SHUTDOWN_TIMEOUT` to env vars table; add structured log format example; add production readiness section; reference `openapi.yaml`

## 6. Tests and Verification

- [x] 6.1 Add unit tests for `v1GreetHandler`: valid name, trimmed name, empty name, too-long name, malformed JSON, missing body, wrong Content-Type
- [x] 6.2 Add unit tests for `liveHandler` (always 200) and `readyHandler` (200 when ready, 503 when not ready)
- [x] 6.3 Add unit tests for logging middleware: verify log output shape (JSON with required fields), verify `X-Request-ID` header present and matches log `request_id`
- [x] 6.4 Verify existing `TestHealthHandler` and `TestGreetHandler_*` tests still pass
- [x] 6.5 Run `make test` and `make lint` to confirm all tests pass and no lint issues
