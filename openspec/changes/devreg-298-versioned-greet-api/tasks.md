<!-- After each completed task, commit the changes. -->

## 1. Structured Logging Foundation

- [ ] 1.1 Add logging middleware with `log/slog` JSON handler: create `loggingMiddleware` function that wraps `http.Handler`, generates a 16-byte hex request ID via `crypto/rand`, sets `X-Request-ID` response header, captures status code with a `responseWriter` wrapper, and emits one JSON log line per request with fields `ts`, `level`, `method`, `path`, `status`, `duration_ms`, `request_id`. Use `slog.HandlerOptions` with `ReplaceAttr` to rename `time` to `ts` and to lowercase the `level` value via `strings.ToLower` (slog defaults to uppercase `"INFO"`/`"ERROR"` but the spec requires lowercase).
- [ ] 1.2 Replace `log.Printf` startup message with structured JSON via `slog`, including `ts`, `level` ("info"), and `msg` indicating the listening address.
- [ ] 1.3 Write unit tests verifying: log output is valid JSON with all seven required fields; `request_id` in log matches `X-Request-ID` response header; startup log is structured JSON.

## 2. POST /v1/greet Endpoint

- [ ] 2.1 Add `v1GreetHandler` for `POST /v1/greet`: parse JSON body `{"name":"..."}`, trim whitespace, validate name is 1–64 chars after trimming, return `{"message":"Hello, <name>!", "name":"<name>"}` on 200, or `{"error":"validation_error", "message":"<reason>"}` on 400 for empty/too-long name, missing body, malformed JSON, missing `name` field, or wrong `Content-Type`.
- [ ] 2.2 Register `POST /v1/greet` on the mux alongside existing routes. Ensure `GET /greet` remains unchanged.
- [ ] 2.3 Write unit tests covering: valid name, trimmed name, empty name, whitespace-only name, name exceeding 64 chars, missing body, malformed JSON, missing `name` field, wrong Content-Type, existing `GET /greet` with and without query param still works.

## 3. Kubernetes Probes and Graceful Shutdown

- [ ] 3.1 Add `liveHandler` (always returns 200 `{"status":"ok"}`) and `readyHandler` (returns 200 `{"status":"ok"}` when accepting traffic, 503 `{"status":"shutting_down"}` after shutdown signal). Use `atomic.Bool` for the readiness flag.
- [ ] 3.2 Implement graceful shutdown: replace `http.ListenAndServe` with `http.Server`, use `os/signal.NotifyContext` for SIGTERM/SIGINT, flip readiness flag to false on signal, call `Server.Shutdown` with configurable timeout from `SHUTDOWN_TIMEOUT` env var (parsed as Go `time.Duration`, default 15s; fall back to default on parse error). Ensure exit code 0 after clean drain.
- [ ] 3.3 Register `/live` and `/ready` routes. Ensure `GET /health` remains unchanged.
- [ ] 3.4 Write unit tests verifying: `/live` returns 200, `/ready` returns 200 before shutdown, `/ready` returns 503 after readiness flag is flipped, `/health` still works, `SHUTDOWN_TIMEOUT` is parsed correctly, invalid `SHUTDOWN_TIMEOUT` falls back to 15s default.

## 4. OpenAPI Specification

- [ ] 4.1 Create `openapi.yaml` at repo root: OpenAPI 3.0 spec documenting `POST /v1/greet` (request/response schemas, 400 error schema), `GET /live`, and `GET /ready` with examples and appropriate status codes.
- [ ] 4.2 Add `make lint-openapi` Makefile target that validates `openapi.yaml` (e.g., via `npx @redocly/cli lint openapi.yaml`).

## 5. README and Documentation

- [ ] 5.1 Update `README.md`: add endpoints table listing all five routes (`/health`, `/greet`, `/v1/greet`, `/live`, `/ready`) with method, path, and description; add env vars table including `PORT`, `APP_VERSION`, and `SHUTDOWN_TIMEOUT` with defaults; add structured log format section with example JSON line; reference `openapi.yaml`; add "Production readiness" section noting probe and shutdown behavior.

## 6. Verification

- [ ] 6.1 Run `make test` and confirm all new and existing tests pass.
- [ ] 6.2 Run `make lint` (if available) or `go vet ./...` and confirm no issues.
