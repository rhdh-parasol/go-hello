## ADDED Requirements

### Requirement: GET /live returns 200 while process is running

The server SHALL expose a `GET /live` endpoint that returns HTTP 200 with `Content-Type: application/json` at all times while the process is up, regardless of shutdown state.

#### Scenario: Liveness probe succeeds during normal operation

- **WHEN** a client sends `GET /live` while the server is running
- **THEN** the server responds with status 200 and a JSON body containing `"status":"ok"`

#### Scenario: Liveness probe succeeds for in-flight request during shutdown

- **WHEN** a `GET /live` request is already in-flight when the server receives SIGTERM
- **THEN** the server responds with status 200 on that existing connection (new TCP connections are refused once the listener closes)

### Requirement: GET /ready returns 200 only while accepting traffic

The server SHALL expose a `GET /ready` endpoint that returns HTTP 200 while the server is accepting new traffic. After a shutdown signal is received, it MUST return HTTP 503.

#### Scenario: Readiness probe succeeds during normal operation

- **WHEN** a client sends `GET /ready` while the server is accepting traffic
- **THEN** the server responds with status 200 and a JSON body containing `"status":"ok"`

#### Scenario: Readiness probe fails after shutdown signal

- **WHEN** a client sends `GET /ready` after the server has received SIGTERM or SIGINT
- **THEN** the server responds with status 503 and a JSON body containing `"status":"shutting_down"`

### Requirement: Graceful shutdown drains in-flight requests

On receiving SIGTERM or SIGINT, the server SHALL stop accepting new connections, drain all in-flight requests within a configurable timeout, and exit with code 0. The `SHUTDOWN_TIMEOUT` value SHALL be parsed as a Go `time.Duration` string (e.g., `5s`, `30s`). If the value cannot be parsed, the server SHALL fall back to the 15-second default.

#### Scenario: In-flight requests complete during shutdown

- **WHEN** the server receives SIGTERM while requests are in-flight
- **THEN** the server waits for in-flight requests to complete (up to the shutdown timeout) before exiting

#### Scenario: Shutdown timeout is configurable

- **WHEN** the `SHUTDOWN_TIMEOUT` environment variable is set to `5s`
- **THEN** the server uses 5 seconds as the maximum drain duration instead of the 15-second default

#### Scenario: Server exits 0 after clean drain

- **WHEN** the server receives SIGTERM and all in-flight requests complete within the timeout
- **THEN** the process exits with code 0

#### Scenario: Invalid SHUTDOWN_TIMEOUT falls back to default

- **WHEN** the `SHUTDOWN_TIMEOUT` environment variable is set to `invalid`
- **THEN** the server uses the 15-second default as the maximum drain duration

### Requirement: GET /health remains unchanged

The existing `GET /health` endpoint MUST continue to function identically and independently from `/live` and `/ready`.

#### Scenario: Health endpoint still works

- **WHEN** a client sends `GET /health`
- **THEN** the server responds with status 200 and a JSON body containing `"status":"ok"`, `"timestamp"`, and `"version"`
