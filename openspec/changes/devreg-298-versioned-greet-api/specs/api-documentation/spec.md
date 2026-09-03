## ADDED Requirements

### Requirement: OpenAPI 3.0 specification documents new endpoints

The repository SHALL contain an `openapi.yaml` file at the repo root that is a valid OpenAPI 3.0 document describing `POST /v1/greet`, `GET /live`, and `GET /ready` with request/response schemas, examples, and status codes including the 400 error shape.

#### Scenario: OpenAPI file is valid

- **WHEN** `openapi.yaml` is validated with an OpenAPI linter
- **THEN** validation passes with no errors

#### Scenario: OpenAPI schemas match actual response shapes

- **WHEN** comparing the schemas in `openapi.yaml` to the actual JSON returned by each endpoint
- **THEN** the schema definitions match the implemented response structures

### Requirement: README documents all routes and configuration

The `README.md` SHALL list all endpoints (`/health`, `/greet`, `/v1/greet`, `/live`, `/ready`) with method, path, and description. It SHALL document the `SHUTDOWN_TIMEOUT` environment variable, include a structured log format example with valid JSON, and reference the `openapi.yaml` file.

#### Scenario: Endpoints table is complete

- **WHEN** reading the README endpoints section
- **THEN** all five routes are listed with method, path, and description

#### Scenario: Environment variables documented

- **WHEN** reading the README env vars section
- **THEN** `PORT`, `APP_VERSION`, and `SHUTDOWN_TIMEOUT` are documented with defaults

#### Scenario: Log format example present

- **WHEN** reading the README logging section
- **THEN** an example JSON log line is shown and is valid JSON

#### Scenario: OpenAPI reference present

- **WHEN** reading the README
- **THEN** the `openapi.yaml` file is referenced for API contract details
