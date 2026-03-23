# Issue 2 — Upload, Persist and Render a Map Image

## Objective

Implement the most basic functional loop of the app: the user can upload a map image, see it rendered on screen, and save it to the filesystem. This establishes the base layout (dark mode), the first LiveView, and the image storage pipeline.

---

## Constraints

- Supported formats: JPG, PNG, WebP (browser-native — no server-side parsing needed)
- Images are stored as-is on the filesystem (no base64, no processing)
- No entity model yet — just the Map record with its image
- No layers, pins, or sidebar yet

---

## Section 1 — Map Schema and Migration [sonnet]

- [x] Create the `Estratos.Worlds.Map` schema:

| Field | Type | Notes |
|---|---|---|
| `id` | `:id` | Primary key (default) |
| `name` | `:string` | Required. User-given name for the map |
| `image_path` | `:string` | Relative path to the stored image file (from `priv/static`) |
| `image_width` | `:integer` | Native width in pixels (captured at upload time) |
| `image_height` | `:integer` | Native height in pixels (captured at upload time) |
| `timestamps` | | `inserted_at`, `updated_at` |

- [x] Create the migration for `maps` table
- [x] Create the `Estratos.Worlds` context with basic CRUD for Map (`create_map/1`, `get_map/1`, `list_maps/0`)
- [x] Changeset validates: `name` required, `image_path` required

> `image_width` and `image_height` are stored at upload time. They cost nothing to capture and will be needed later for scale/distance calculations (Roadmap 7.3).

---

## Section 2 — Image Storage [sonnet]

- [x] Define an upload directory: `priv/static/uploads/maps/`
- [x] Create a storage module (`Estratos.MapStorage` or similar) that:
  - Receives the uploaded file (temp path from LiveView upload)
  - Generates a unique filename: `{uuid}.{original_extension}`
  - Copies the file to `priv/static/uploads/maps/`
  - Returns the relative path (e.g., `/uploads/maps/abc123.png`)
- [x] Add `"uploads"` to the static paths list in `EstratosWeb.static_paths/0` so Phoenix serves the files
- [x] Add `priv/static/uploads/` to `.gitignore`
- [x] Ensure the uploads directory persists in Docker (it lives inside the mounted `.:/app` volume, so it should work — verify)

---

## Section 3 — Dark Mode Base Layout [sonnet]

- [x] Replace the current app layout in `EstratosWeb.Layouts` with a minimal dark layout:
  - Full viewport height (`h-screen`), dark background
  - A top navbar (fixed or sticky)
  - A main content area that fills the remaining space
  - Remove all Phoenix default branding (logo, links, hero)
- [x] Remove the default home page template and `PageController` (replaced by LiveView)
- [x] Keep the existing daisyUI dark theme — it's already configured in `app.css`
- [x] Set dark theme as the default (remove theme toggle for now — the app is dark mode only in MVP)

---

## Section 4 — Map LiveView: Upload, Preview, Save and Render [sonnet]

- [x] Create `EstratosWeb.MapLive` as the root route (`/`)
- [x] Update the router: replace `PageController` route with `live "/", MapLive`
- [x] Implement the LiveView with two states:

**State A — No map loaded:**
- Dark empty canvas
- Navbar shows:
  - "Upload" button (enabled) — opens file picker
  - "Save" button (disabled, visually muted)

**State B — Image uploaded (not yet saved):**
- The uploaded image renders in the main content area, filling the available space while maintaining aspect ratio
- Navbar shows:
  - "Upload" button (enabled) — allows replacing the image
  - "Save" button (enabled) — triggers persist

**On Save:**
- Image file is stored via the storage module (Section 2)
- Image dimensions are captured (via client hook or server-side)
- Map record is created in the database
- "Save" button goes back to disabled
- Map name: for now use a default name (e.g., "Untitled Map") — name editing is not in scope

**On app reload:**
- If a map exists in the DB, load and render it immediately

---

## Section 5 — Capture Image Dimensions [haiku]

- [x] Use a client-side JS hook to read the image's natural width/height after it loads
- [x] Push the dimensions to the server via `pushEvent`
- [x] Store them in the Map record on save

> This is lightweight — the browser already knows the dimensions once the image loads. No server-side image library needed.

---

## Section 6 — Smoke Test [sonnet]

- [ ] `make up` → app boots, dark layout loads at `localhost:4000`
- [ ] Click "Upload" → file picker opens, accepts JPG/PNG/WebP
- [ ] Select an image → image renders in the main area
- [ ] "Save" button becomes active → click it → image persists
- [ ] Refresh the page → the saved map image loads automatically
- [ ] Verify the image file exists in `priv/static/uploads/maps/`
- [ ] Verify the map record exists in the database with correct dimensions
- [ ] `make test` → tests pass (at minimum: context tests for Map CRUD)

---

## Out of Scope

- Map name editing (default name is fine)
- Multiple maps / map list / map selection
- Layers, pins, sidebar, entities
- Image resizing or processing
- PDF support
- Zoom or pan

---

## Done When

- The app loads with a dark-mode layout and no default Phoenix branding
- A user can upload a JPG/PNG/WebP image and see it rendered
- Clicking "Save" persists the image to the filesystem and creates a DB record
- Reloading the page renders the last saved map
- Image dimensions are captured and stored
- The upload directory is gitignored and served by Phoenix
