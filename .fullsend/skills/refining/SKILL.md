---
name: refining
description: >-
  Decompose a work item into implementable children with testable
  acceptance criteria, explicit assumptions, and a small set of open questions.
---

# Refining

You are planning, not implementing.

## Children

- Each child is independently shippable or is a necessary precursor called out as a dependency.
- Title is an outcome ("Serve health and greet over HTTP"), not a chore ("Look at main.go").
- Acceptance criteria are observable (status code, JSON shape, test name), not "done well".

## Evidence

- Quote or paraphrase the issue. If the issue is thin, say so under Open questions instead of filling gaps with fiction.
- Use repo files to ground technical splits (existing endpoints, tests, Dockerfile). If the repo is unrelated to the issue, ignore it and say so.

## Questions

- At most 5 open questions, highest-leverage first.
- Do not ask for facts already in the issue or repo.
- If readiness is `needs-info`, the questions must be what a human has to answer before the plan is worth creating as tickets.
