# Issue 1 — Project Bootstrap (Revised)

## Objective

Set up a fully dockerized, portable development environment for Estratos:

- Everything runs via `docker compose up` — no local Elixir/Erlang/Node install required
- PostgreSQL + PostGIS in Docker
- Phoenix app in Docker
- Makefile for all common operations
- Tool versions pinned in a `.tool-versions` file
- Environment variables managed via `.env` (gitignored)

---

## Tech Stack

| Component | Version |
|---|---|
| Elixir | 1.18 |
| Erlang/OTP | 27 |
| Phoenix | 1.8+ (with LiveView) |
| PostgreSQL | 17 (Docker) |
| PostGIS | 3.4 (Docker) |
| Node.js | 20 |
| geo_postgis | ~> 3.7 |

---

## Section 1 — Tool Versions File [haiku]

- [ ] Create `.tool-versions` at project root:

```
elixir 1.18
erlang 27
nodejs 20
```

> Pins versions for asdf/mise. Docker images should match these versions.

---

## Section 2 — Environment Variables [haiku]

- [ ] Create `.env` at project root:

```env
# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=estratos_dev
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Phoenix
SECRET_KEY_BASE=generate-a-real-secret-for-prod
PHX_HOST=localhost
PHX_PORT=4000
MIX_ENV=dev
```

- [ ] Ensure `.env` is listed in `.gitignore`
- [ ] Create `.env.example` with the same keys but placeholder values, committed to repo

---

## Section 3 — Dockerize the Phoenix App [sonnet]

- [ ] Create `Dockerfile` at project root:
  - Use official Elixir image matching `.tool-versions`
  - Install Node.js, hex, rebar
  - Copy mix files first, run `mix deps.get` (layer caching)
  - Copy the rest of the app
  - Expose port 4000
  - Default CMD: `mix phx.server`
- [ ] Ensure hot-reload works by mounting the source code as a volume in dev

---

## Section 4 — Docker Compose (Full Stack) [sonnet]

- [ ] Rewrite `docker-compose.yml` to include both services:

```yaml
services:
  db:
    image: postgis/postgis:17-3.4
    container_name: estratos_db
    restart: unless-stopped
    env_file: .env
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - estratos_db_data:/var/lib/postgresql/data

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: estratos_app
    restart: unless-stopped
    env_file: .env
    depends_on:
      - db
    ports:
      - "${PHX_PORT:-4000}:4000"
    volumes:
      - .:/app
      - deps:/app/deps
      - build:/app/_build
    stdin_open: true
    tty: true

volumes:
  estratos_db_data:
  deps:
  build:
```

- [ ] `docker compose up` boots both services without errors
- [ ] Phoenix connects to the DB container via hostname `db`

---

## Section 5 — Makefile [haiku]

- [ ] Create `Makefile` at project root with these targets:

| Target | Description |
|---|---|
| `make setup` | Build images, install deps, create DB, run migrations |
| `make up` | Start all services (`docker compose up -d`) |
| `make down` | Stop all services (`docker compose down`) |
| `make logs` | Tail logs (`docker compose logs -f`) |
| `make shell` | Open a shell inside the app container |
| `make iex` | Open IEx console inside the app container |
| `make test` | Run tests inside the app container |
| `make drop` | Stop services and remove volumes (`docker compose down -v`) |
| `make check-env` | Verify `.env` exists and is in `.gitignore` |

- [ ] `make check-env` should fail with a clear message if `.env` is missing or not gitignored

---

## Section 6 — Connect Phoenix to DB (via Docker network) [sonnet]

- [ ] Update `config/dev.exs` to read from environment variables:

```elixir
config :estratos, Estratos.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "db"),
  database: System.get_env("POSTGRES_DB", "estratos_dev"),
  port: String.to_integer(System.get_env("POSTGRES_PORT", "5432")),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

- [ ] `make setup` → DB created, no errors
- [ ] `make up` → app boots, connects to DB

---

## Section 7 — Geo Dependencies [haiku]

- [x] `{:geo_postgis, "~> 3.7"}` already in `mix.exs`
- [ ] Verify `mix deps.get` works inside Docker container

> Nothing uses `geo_postgis` yet. Preparation for Issue 2.

---

## Section 8 — Final Smoke Test [sonnet]

- [ ] `make up` → both containers running
- [ ] `docker ps` → `estratos_db` and `estratos_app` up
- [ ] http://localhost:4000 → Phoenix default page loads
- [ ] `make test` → tests pass
- [ ] `make down` → clean shutdown
- [ ] `make drop` → volumes removed
- [ ] No schemas, migrations, or domain logic exist in the project

---

## Done When

- All checkpoints above are checked off
- `docker compose up` is the only command needed to run the full app
- Environment is portable — works on Linux, macOS, and Windows
- `.env` is gitignored, `.env.example` is committed
- Makefile covers all common operations
