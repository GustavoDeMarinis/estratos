# Issue 1 - Project Bootstrap (Estratos)

## Objective

Initialize the Estratos project with a complete base setup:
- Backend application running (empty, no business logic)
- PostgreSQL database running in Docker (no schema required yet)
- Frontend application running (empty UI)
- All core dependencies installed and ready for future development

This issue focuses only on bootstrapping and environment readiness.

## Tech Stack (defined for this project)

- Backend: Elixir + Phoenix + LiveView
- Database: PostgreSQL with PostGIS (Dockerized)
- Frontend: Phoenix LiveView (no separate SPA)
- Containerization: Docker (for database only)

## Prerequisites

Ensure the following are installed on your system:
- Elixir (>= 1.14)
- Erlang/OTP (>= 25)
- Phoenix installer
- Docker
- Node.js (required by Phoenix for assets)

## Steps

- [ ] Create the Phoenix application

Run the Phoenix generator with PostgreSQL and LiveView enabled:

mix phx.new estratos --database postgres --live

When prompted:
- Install dependencies: Yes
- Fetch and install assets: Yes

Navigate into the project directory:

cd estratos

- [ ] Verify backend runs (empty app)

Start the Phoenix server:

mix phx.server

Open the browser at:
http://localhost:4000

Expected result:
- Default Phoenix page loads
- No custom logic implemented yet

- [ ] Add Docker configuration for PostgreSQL + PostGIS

Create a docker-compose.yml file at the project root with the following configuration:

version: '3.9'
services:
  db:
    image: postgis/postgis:15-3.3
    container_name: estratos_db
    restart: always
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

- [ ] Start the database

Run:

docker compose up -d

Verify the container is running:

docker ps

Expected result:
- PostgreSQL with PostGIS is running on port 5432

- [ ] Configure Phoenix to use Dockerized DB

Edit config/dev.exs and ensure the Repo config matches:

config :estratos, Estratos.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "estratos_dev",
  port: 5432,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

- [ ] Create the database

Run:

mix ecto.create

Expected result:
- Database estratos_dev is created successfully

- [ ] Verify full backend + DB integration

Start Phoenix again:

mix phx.server

Expected result:
- App boots without DB errors
- No migrations or schemas required yet

- [ ] Verify frontend (LiveView) is working

Open:

http://localhost:4000

Expected result:
- Phoenix default UI loads correctly
- LiveView assets are compiled and served
- No additional frontend setup required

- [ ] Install additional core dependencies (optional but recommended)

Add Geo/PostGIS support for future work:

Update mix.exs to include:

{:geo_postgis, "~> 3.4"}

Run:

mix deps.get

Note:
No schema uses this yet, this is just preparation.

- [ ] Validate full environment

Ensure all components run together:

- Docker DB is running
- Phoenix server is running
- Browser loads the app

No business logic, schemas, or features should exist yet.

## Acceptance Criteria

- Phoenix app boots successfully
- PostgreSQL (PostGIS) runs in Docker
- mix ecto.create works
- No runtime errors related to DB connection
- Browser shows default Phoenix page
- Project is ready for feature development

## Notes

- Do not implement any domain logic yet
- Do not create schemas or migrations beyond default setup
- Keep the system minimal and clean
- This issue is complete when the environment is stable and reproducible