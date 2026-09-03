## ADDED Requirements

### Requirement: POST /v1/greet accepts JSON name and returns greeting

The server SHALL expose a `POST /v1/greet` endpoint that accepts a JSON request body with a `name` field and returns a JSON response containing `message` and `name` fields. The `Content-Type` of the response MUST be `application/json`.

#### Scenario: Successful greeting with valid name

- **WHEN** a client sends `POST /v1/greet` with body `{"name":"Ada"}`
- **THEN** the server responds with status 200 and body `{"message":"Hello, Ada!","name":"Ada"}`

#### Scenario: Successful greeting with name requiring trimming

- **WHEN** a client sends `POST /v1/greet` with body `{"name":"  Ada  "}`
- **THEN** the server responds with status 200 and body `{"message":"Hello, Ada!","name":"Ada"}`

### Requirement: POST /v1/greet validates name length between 1 and 64 characters

The server SHALL reject requests where the trimmed `name` is empty or exceeds 64 characters. Validation MUST occur after whitespace trimming.

#### Scenario: Empty name rejected

- **WHEN** a client sends `POST /v1/greet` with body `{"name":""}`
- **THEN** the server responds with status 400 and a JSON body containing `"error":"validation_error"` and a human-readable `"message"` field

#### Scenario: Whitespace-only name rejected

- **WHEN** a client sends `POST /v1/greet` with body `{"name":"   "}`
- **THEN** the server responds with status 400 and a JSON body containing `"error":"validation_error"`

#### Scenario: Name exceeding 64 characters rejected

- **WHEN** a client sends `POST /v1/greet` with a `name` longer than 64 characters after trimming
- **THEN** the server responds with status 400 and a JSON body containing `"error":"validation_error"`

### Requirement: POST /v1/greet rejects missing or malformed bodies

The server SHALL return 400 for requests with missing JSON body, unparseable JSON, missing `name` field, or wrong `Content-Type`.

#### Scenario: Missing request body

- **WHEN** a client sends `POST /v1/greet` with no body
- **THEN** the server responds with status 400 and a JSON body containing `"error":"validation_error"`

#### Scenario: Malformed JSON

- **WHEN** a client sends `POST /v1/greet` with body `{invalid`
- **THEN** the server responds with status 400 and a JSON body containing `"error":"validation_error"`

#### Scenario: Missing name field

- **WHEN** a client sends `POST /v1/greet` with body `{}`
- **THEN** the server responds with status 400 and a JSON body containing `"error":"validation_error"`

#### Scenario: Wrong Content-Type rejected

- **WHEN** a client sends `POST /v1/greet` with `Content-Type: text/plain` and body `{"name":"Ada"}`
- **THEN** the server responds with status 400 and a JSON body containing `"error":"validation_error"`

### Requirement: Existing GET /greet endpoint unchanged

The existing `GET /greet` endpoint MUST continue to function identically. It SHALL NOT be modified or removed by this change.

#### Scenario: GET /greet still works with query parameter

- **WHEN** a client sends `GET /greet?name=Fullsend`
- **THEN** the server responds with status 200 and body `{"message":"Hello, Fullsend!","name":"Fullsend"}`

#### Scenario: GET /greet still works without query parameter

- **WHEN** a client sends `GET /greet` with no `name` parameter
- **THEN** the server responds with status 200 and body `{"message":"Hello, World!","name":"World"}`
