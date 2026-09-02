# go-hello

Playground copy for [rhdh-parasol](https://github.com/rhdh-parasol), sourced from [fullsend-playground](https://github.com/fullsend-playground).


A simple Go HTTP service with health check, greeting, versioned greet API, Kubernetes probes, and structured JSON logging.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Returns service health status |
| GET | `/greet?name=X` | Returns a greeting (defaults to "World") |
| POST | `/v1/greet` | Versioned greet API with JSON body validation |
| GET | `/live` | Liveness probe (always 200 while process is up) |
| GET | `/ready` | Readiness probe (200 when accepting traffic, 503 during shutdown) |

### POST /v1/greet

Accepts a JSON body with a `name` field (1-64 characters, trimmed). Returns a greeting or a 400 validation error.

```bash
curl -X POST http://localhost:8080/v1/greet \
  -H "Content-Type: application/json" \
  -d '{"name":"Ada"}'
# {"message":"Hello, Ada!","name":"Ada"}
```

See [`openapi.yaml`](openapi.yaml) for the full API specification.

## Development

```bash
# Run locally
make run

# Run tests
make test

# Build binary
make build

# Lint
make lint
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | HTTP listen port |
| `APP_VERSION` | `0.1.0` | Reported in health endpoint |
| `SHUTDOWN_TIMEOUT` | `15s` | Graceful shutdown drain timeout (Go duration, e.g. `5s`, `30s`) |

## Structured Logging

All request logs are emitted as structured JSON to stdout. Each log line contains:

```json
{"time":"2024-01-15T10:30:00Z","level":"INFO","msg":"request","method":"GET","path":"/health","status":200,"duration_ms":0.42,"request_id":"a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6"}
```

Fields: `time`, `level`, `msg`, `method`, `path`, `status`, `duration_ms`, `request_id`.

Every response includes an `X-Request-ID` header matching the `request_id` in the log line, enabling end-to-end correlation.

## Production Readiness

- **Liveness probe** (`/live`): Returns 200 whenever the process is running. Configure as the Kubernetes `livenessProbe`.
- **Readiness probe** (`/ready`): Returns 200 while accepting traffic, 503 after a shutdown signal. Configure as the Kubernetes `readinessProbe`.
- **Graceful shutdown**: On SIGTERM/SIGINT the server stops accepting new connections, drains in-flight requests within `SHUTDOWN_TIMEOUT`, then exits 0. Kubernetes should set `terminationGracePeriodSeconds` >= `SHUTDOWN_TIMEOUT`.

## Docker

```bash
docker build -t go-hello .
docker run -p 8080:8080 go-hello
```
