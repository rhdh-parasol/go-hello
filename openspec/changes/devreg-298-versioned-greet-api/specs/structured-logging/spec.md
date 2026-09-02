## ADDED Requirements

### Requirement: Structured JSON request logging

The system SHALL emit exactly one structured JSON log line per HTTP request to stdout. Each log line MUST contain at minimum: `ts` (RFC 3339 timestamp), `level` (info or error), `method` (HTTP method), `path` (request path), `status` (HTTP status code), `duration_ms` (request duration in milliseconds), and `request_id` (unique identifier for the request).

#### Scenario: Successful request log line

- **WHEN** a client sends `GET /health` and receives a 200 response
- **THEN** the server emits one JSON log line to stdout containing `ts`, `level`, `method`, `path`, `status`, `duration_ms`, and `request_id` fields, parseable by `jq`

#### Scenario: Log line for error response

- **WHEN** a client sends `POST /v1/greet` with an invalid body and receives a 400 response
- **THEN** the server emits one JSON log line to stdout with `status` set to 400

### Requirement: Request ID in response header

The system SHALL generate a unique `request_id` (16-byte hex string via `crypto/rand`) for each request and return it in the `X-Request-ID` response header. The `request_id` in the log line MUST match the value in the response header.

#### Scenario: X-Request-ID header present

- **WHEN** a client sends any HTTP request
- **THEN** the response includes an `X-Request-ID` header with a 32-character hex string

#### Scenario: Request ID correlation

- **WHEN** a client sends a request and reads the `X-Request-ID` response header
- **THEN** the same value appears in the `request_id` field of the corresponding log line

### Requirement: Structured startup log

The system SHALL emit its startup message as a structured JSON log line (not `log.Printf`). The startup log MUST include at least `ts`, `level`, and `msg` fields.

#### Scenario: Startup log is JSON

- **WHEN** the server starts
- **THEN** the startup message is a valid JSON line on stdout parseable by `jq`
