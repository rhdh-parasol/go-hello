# go-hello

Playground copy for [rhdh-parasol](https://github.com/rhdh-parasol), sourced from [fullsend-playground](https://github.com/fullsend-playground).


A simple Go HTTP service with health check and greeting endpoints.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Returns service health status |
| GET | `/greet?name=X` | Returns a greeting (defaults to "World") |

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

## Docker

```bash
docker build -t go-hello .
docker run -p 8080:8080 go-hello
```
