# CLAUDE.md

This file provides context for AI agents working in this repository.

## Project overview

A simple Go HTTP service with health-check and greeting endpoints.
Playground copy for [rhdh-parasol](https://github.com/rhdh-parasol),
sourced from [fullsend-playground](https://github.com/fullsend-playground).

## Build and test commands

All commands are available as Makefile targets:

```bash
make build   # compile binary to bin/go-hello
make test    # run tests with race detection (go test -v -race ./...)
make run     # run the service locally (go run .)
make lint    # vet the code (go vet ./...)
make clean   # remove build artifacts (rm -rf bin/)
```

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | HTTP listen port |
| `APP_VERSION` | `0.1.0` | Reported in `/health` endpoint |

## Repository structure

```
.
├── main.go          # HTTP server: /health and /greet endpoints
├── main_test.go     # Unit tests for handlers
├── Makefile         # Build, test, run, lint, clean targets
├── Dockerfile       # Multi-stage build (golang:1.22-alpine → alpine:3.19)
├── go.mod           # Go 1.22 module (no external dependencies)
├── .github/
│   └── workflows/   # CI workflows (fullsend, Jira polling, prioritize)
└── .fullsend/       # Custom agent infrastructure (see below)
```

## `.fullsend/` directory

This directory contains custom agent configuration for the fullsend
platform. Key contents:

- **`config.yaml`** — per-repo fullsend configuration. Runtime: `claude`.
  Roles: triage, coder, review, fix, retro, prioritize. Defines a
  custom `refine` agent sourced from `harness/refine.yaml`.
- **`agents/refine.md`** — refine agent definition. Decomposes a work
  item into implementable children with testable acceptance criteria.
  Triggered by `/fs-refine` on a Jira or GitHub issue.
- **`harness/refine.yaml`** — harness config for the refine agent.
  The refine agent borrows the `review` role and `fullsend-ai-review`
  slug for GitHub App identity (there is no dedicated refine mint slug).
- **`scripts/pre-refine.sh`** — pre-script that loads the triggering
  work item (Jira or GitHub) and writes `issue-context.json` for the
  sandbox. Handles Jira key extraction from browse URLs.
- **`scripts/post-refine.sh`** — post-script that posts the refine
  agent's markdown output as a comment on the triggering issue.
- **`skills/refining/SKILL.md`** — skill definition for the refining
  task (planning, not implementing).
- **`policies/base.yaml`** — base sandbox policy (filesystem, landlock,
  process identity). Network access is provided by provider profiles.
- **`providers/`** — inference provider configs (GitHub, Vertex AI).
- **`profiles/`** — openshell profiles for provider access.
- **`env/`** — environment variable files for GCP Vertex AI and refine.
