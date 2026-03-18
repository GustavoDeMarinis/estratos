# Issue 1 — Project Bootstrap

## Objective

Set up a clean, working development environment for Estratos:

- Phoenix app running (empty, no business logic)
- PostgreSQL + PostGIS running in Docker
- Core dependencies installed
- No schemas, migrations, or domain logic yet

## Tech Stack

| Component | Version |
|---|---|
| Elixir | >= 1.18 |
| Erlang/OTP | >= 27 |
| Phoenix | 1.8+ (with LiveView) |
| PostgreSQL | 17 (Docker) |
| PostGIS | 3.4 (Docker) |
| Node.js | >= 20 |
| geo_postgis | ~> 3.7 |

---

## Section 1 — Generate Phoenix Project

- [x] Install Phoenix generator: `mix archive.install hex phx_new`
- [x] Generate project: `mix phx.new estratos --database postgres --live`
- [x] Accept dependency install when prompted
- [x] `cd estratos`
- [x] Run `mix compile` — no errors

## Section 2 — Database (Docker)

- [x] Create `docker-compose.yml` at project root:

```yaml
services:
  db:
    image: postgis/postgis:17-3.4
    container_name: estratos_db
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: estratos_dev
    ports:
      - "5432:5432"
    volumes:
      - estratos_db_data:/var/lib/postgresql/data

volumes:
  estratos_db_data:
```

- [x] Run `docker compose up -d`
- [x] Verify container is up: `docker ps` shows `estratos_db`

## Section 3 — Connect Phoenix to DB

- [x] Verify `config/dev.exs` Repo config matches Docker credentials:

```elixir
config :estratos, Estratos.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "estratos_dev",
  port: 5432,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

- [ ] Run `mix ecto.create` — database created
- [ ] Run `mix phx.server`
- [ ] Open http://localhost:4000 — default Phoenix page loads
- [ ] No DB connection errors in terminal

## Section 4 — Geo Dependencies

- [x] Add `{:geo_postgis, "~> 3.7"}` to `deps` in `mix.exs`
- [x] Run `mix deps.get` — no conflicts

> [!NOTE]
> Nothing uses `geo_postgis` yet. This is preparation for Issue 2.

## Section 5 — Final Smoke Test

- [ ] `docker ps` → `estratos_db` running
- [ ] `mix phx.server` → boots without errors
- [ ] http://localhost:4000 → Phoenix page loads
- [ ] No schemas, migrations, or domain logic exist in the project

---

## Done When

- All checkpoints above are checked off
- Environment is stable and reproducible