## ADDED Requirements

### Requirement: Every request produces one structured JSON log line

The server SHALL emit exactly one JSON log line to stdout per HTTP request, parseable by `jq`. Each log line MUST contain at minimum: `ts` (RFC 3339 timestamp), `level` (info or error), `method`, `path`, `status` (integer HTTP status code), `duration_ms` (float, milliseconds), and `request_id`.

#### Scenario: Successful request log line

- **WHEN** a client sends `GET /health` and receives a 200 response
- **THEN** stdout contains one JSON line with all seven required fields, where `status` is 200 and `level` is "info"

#### Scenario: Failed request log line

- **WHEN** a client sends `POST /v1/greet` with invalid input and receives a 400 response
- **THEN** stdout contains one JSON line with all seven required fields, where `status` is 400

#### Scenario: Log line is valid JSON

- **WHEN** any HTTP request completes
- **THEN** the emitted log line is parseable by `echo '<line>' | jq .` without error

### Requirement: Request ID is generated per request and returned in header

The server SHALL generate a unique `request_id` (16-byte hex string via `crypto/rand`) for each request. The same value MUST appear both in the structured log line and in the `X-Request-ID` response header.

#### Scenario: X-Request-ID header present

- **WHEN** a client sends any HTTP request
- **THEN** the response includes an `X-Request-ID` header with a 32-character hex string

#### Scenario: Request ID matches between log and header

- **WHEN** a client sends a request and reads the `X-Request-ID` response header
- **THEN** the `request_id` field in the corresponding log line matches the header value exactly

### Requirement: Startup log is structured JSON

The server's startup message MUST be emitted as structured JSON to stdout, replacing any `log.Printf` startup output.

#### Scenario: Startup message is JSON

- **WHEN** the server starts
- **THEN** stdout contains a JSON line with at least `ts`, `level` set to "info", and a `msg` field indicating the server is listening
