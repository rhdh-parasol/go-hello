## ADDED Requirements

### Requirement: Liveness probe endpoint

The system SHALL expose a `GET /live` endpoint that returns HTTP 200 with `{"status":"ok"}` whenever the process is running. This endpoint MUST always return 200 regardless of shutdown state.

#### Scenario: Liveness check while running

- **WHEN** a client sends `GET /live` while the server process is running
- **THEN** the server responds with 200 and `{"status":"ok"}`

#### Scenario: Liveness check during shutdown

- **WHEN** a client sends `GET /live` after a shutdown signal has been received (but before the listener closes)
- **THEN** the server responds with 200 and `{"status":"ok"}`

### Requirement: Readiness probe endpoint

The system SHALL expose a `GET /ready` endpoint that returns HTTP 200 with `{"status":"ok"}` while the server is accepting traffic. After a shutdown signal (SIGTERM or SIGINT) is received, the endpoint SHALL return HTTP 503 with `{"status":"shutting_down"}`.

#### Scenario: Readiness check while accepting traffic

- **WHEN** a client sends `GET /ready` before any shutdown signal
- **THEN** the server responds with 200 and `{"status":"ok"}`

#### Scenario: Readiness check after shutdown signal

- **WHEN** the server receives SIGTERM and a client sends `GET /ready`
- **THEN** the server responds with 503 and `{"status":"shutting_down"}`

### Requirement: Graceful shutdown

The system SHALL handle SIGTERM and SIGINT by: (1) flipping readiness to false, (2) stopping acceptance of new connections via `http.Server.Shutdown`, (3) draining in-flight requests within a configurable timeout, and (4) exiting with code 0. The timeout SHALL be configurable via the `SHUTDOWN_TIMEOUT` environment variable (default: 15 seconds).

#### Scenario: Graceful shutdown on SIGTERM

- **WHEN** the server receives SIGTERM with in-flight requests
- **THEN** readiness flips to 503, in-flight requests complete, and the process exits with code 0

#### Scenario: Configurable shutdown timeout

- **WHEN** `SHUTDOWN_TIMEOUT` is set to `5s` and the server receives SIGTERM
- **THEN** the server uses a 5-second drain timeout

#### Scenario: Default shutdown timeout

- **WHEN** `SHUTDOWN_TIMEOUT` is not set and the server receives SIGTERM
- **THEN** the server uses a 15-second drain timeout

### Requirement: Existing health endpoint preserved

The system SHALL continue to serve `GET /health` with its current behavior unchanged. It MUST NOT be removed or aliased.

#### Scenario: Health endpoint still works

- **WHEN** a client sends `GET /health`
- **THEN** the server responds with 200 and the existing health JSON shape
