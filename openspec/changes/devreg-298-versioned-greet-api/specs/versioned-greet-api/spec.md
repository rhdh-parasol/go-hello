## ADDED Requirements

### Requirement: POST /v1/greet accepts valid JSON name

The system SHALL expose a `POST /v1/greet` endpoint that accepts a JSON request body with a `name` field. The name MUST be trimmed of leading/trailing whitespace and validated to be between 1 and 64 characters (inclusive, after trimming). On success the endpoint SHALL return HTTP 200 with `Content-Type: application/json` and a body of `{"message":"Hello, <name>!", "name":"<name>"}`.

#### Scenario: Valid name

- **WHEN** a client sends `POST /v1/greet` with body `{"name":"Ada"}`
- **THEN** the server responds with 200 and `{"message":"Hello, Ada!","name":"Ada"}`

#### Scenario: Name with surrounding whitespace

- **WHEN** a client sends `POST /v1/greet` with body `{"name":"  Ada  "}`
- **THEN** the server responds with 200 and `{"message":"Hello, Ada!","name":"Ada"}`

### Requirement: POST /v1/greet rejects invalid input

The system SHALL return HTTP 400 with a stable JSON error shape `{"error":"validation_error","message":"<detail>"}` when the request is invalid. Invalid cases include: missing or empty name (after trimming), name exceeding 64 characters, malformed JSON body, missing request body, and wrong or missing `Content-Type` (MUST be `application/json`).

#### Scenario: Empty name

- **WHEN** a client sends `POST /v1/greet` with body `{"name":""}`
- **THEN** the server responds with 400 and `{"error":"validation_error","message":"name is required"}`

#### Scenario: Name too long

- **WHEN** a client sends `POST /v1/greet` with body `{"name":"<65-char string>"}`
- **THEN** the server responds with 400 and `{"error":"validation_error","message":"name must be between 1 and 64 characters"}`

#### Scenario: Malformed JSON

- **WHEN** a client sends `POST /v1/greet` with body `not-json`
- **THEN** the server responds with 400 and `{"error":"validation_error","message":"invalid JSON body"}`

#### Scenario: Missing body

- **WHEN** a client sends `POST /v1/greet` with no request body
- **THEN** the server responds with 400 and `{"error":"validation_error","message":"invalid JSON body"}`

#### Scenario: Wrong Content-Type

- **WHEN** a client sends `POST /v1/greet` with `Content-Type: text/plain`
- **THEN** the server responds with 400 and `{"error":"validation_error","message":"Content-Type must be application/json"}`

### Requirement: Existing GET /greet remains unchanged

The system SHALL continue to serve `GET /greet?name=X` with the same behavior as before this change. The existing endpoint MUST NOT be removed or modified.

#### Scenario: GET /greet still works

- **WHEN** a client sends `GET /greet?name=Test`
- **THEN** the server responds with 200 and `{"message":"Hello, Test!","name":"Test"}`
