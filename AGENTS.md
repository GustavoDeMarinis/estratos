# AGENTS.md — Estratos

## Execution Model

- Work strictly task-by-task
- Do not implement multiple tasks at once
- Always follow the issue checklist order
- Confirm completion before moving to the next task

## Context Rules

- Use only the context provided in the current prompt
- Do not assume missing requirements
- Do not load or infer full project structure unless explicitly asked
- Keep responses focused and minimal

## Model Routing

- Haiku → boilerplate, setup commands, file creation, small config changes, simple tests
- Sonnet → features, DB, Docker/infra, business logic
- Opus → architecture, planning, complex debugging, writing/revising issues and AGENTS.md

- Issue sections are tagged `[haiku]`, `[sonnet]`, or `[opus]` — **always follow the tag**
- If no tag, use the heuristics above
- If a task becomes more complex than the tag implies, suggest upgrading before proceeding

## Planning Behavior

- For new issues:
  - Break work into small, sequential tasks
  - Each task must be independently executable
  - Avoid large or ambiguous steps

## Code Guidelines (Elixir / Phoenix)

- Prefer built-in Elixir/Phoenix features over external dependencies
- Keep code simple, explicit, and idiomatic
- Avoid unnecessary abstractions
- Do not introduce new dependencies unless explicitly required

## Docker-First Development

- Full stack runs in Docker — no local Elixir/Erlang/Node required
- All commands go through the Makefile
- Environment variables live in `.env` (gitignored); `.env.example` is committed

## Database & Geo (PostgreSQL + PostGIS)

- Postgres runs in Docker alongside the app
- Use Ecto properly for all DB interactions
- Do not bypass Ecto unless explicitly required
- Geo features (PostGIS) should be introduced incrementally

## Safety Rules

- Do not perform destructive operations without confirmation
- Do not modify unrelated files
- Do not refactor beyond the scope of the current task
- Never commit `.env` — always verify it is in `.gitignore`

## Interaction Style

- Be concise
- Do not over-explain
- Show a short plan only when necessary
- Prioritize execution over theory