# Contributing to go-hello

Thank you for your interest in contributing to go-hello! This guide
explains how to report issues, set up a local development environment,
and submit pull requests.

## Reporting Issues

If you find a bug or have a feature request, please
[open an issue](https://github.com/rhdh-parasol/go-hello/issues/new)
on GitHub. Include:

- A clear description of the problem or suggestion
- Steps to reproduce the issue (if applicable)
- Expected vs. actual behavior

## Local Development Setup

### Prerequisites

- [Go 1.22](https://go.dev/dl/) or later

### Getting Started

1. Fork and clone the repository:

   ```bash
   git clone https://github.com/<your-username>/go-hello.git
   cd go-hello
   ```

2. Run the service locally:

   ```bash
   make run
   ```

   The server starts on port `8080` by default (configurable via the
   `PORT` environment variable).

3. Run the tests:

   ```bash
   make test
   ```

4. Lint the code:

   ```bash
   make lint
   ```

5. Build the binary:

   ```bash
   make build
   ```

## Submitting a Pull Request

1. Create a feature branch from `main`:

   ```bash
   git checkout -b my-feature
   ```

2. Make your changes and ensure tests pass:

   ```bash
   make test
   make lint
   ```

3. Commit your changes with a clear message.

4. Push your branch and open a pull request against `main`.

5. Describe what your change does and link any related issues.

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make build` | Compile the binary to `bin/go-hello` |
| `make test` | Run tests with race detection |
| `make run` | Run the service locally |
| `make lint` | Vet the code with `go vet` |
| `make clean` | Remove build artifacts |
