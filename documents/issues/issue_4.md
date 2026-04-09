# Issue 4 — World Entity and Multi-Map Support

## Objective

Introduce the World as the root entity of the app and allow multiple maps per world. The user can create a world, manage multiple maps within it, and switch between maps. This establishes the data hierarchy that all future entities (cities, factions, etc.) will belong to.

---

## Constraints

- Single world for now — multi-world support is out of scope
- World is lightweight: name + description only
- Maps gain a `world_id` foreign key
- No entities, pins, or layers yet
- The existing single-map upload/view flow must continue to work within the new structure

---

## Section 1 — World Schema and Migration [sonnet]

- [x] Create the `Estratos.Worlds.World` schema:

| Field | Type | Notes |
|---|---|---|
| `id` | `:id` | Primary key (default) |
| `name` | `:string` | Required. Name of the world |
| `description` | `:string` | Optional. Brief description |
| `timestamps` | | `inserted_at`, `updated_at` |

- [x] Create the migration for `worlds` table
- [x] Add `world_id` foreign key to `maps` table (new migration)
- [x] Update `Map` schema: `belongs_to :world, World`
- [x] Update `World` schema: `has_many :maps, Map`
- [x] Changeset validates: `name` required
- [x] Seed a default world on first boot if none exists (or auto-create on first visit)

---

## Section 2 — World Context Functions [sonnet]

- [x] Add to `Estratos.Worlds` context:
  - `get_or_create_default_world/0` — returns the single world, creating it ("My World") if none exists
  - `get_world!/1` — fetch world by ID (raises on not found)
  - `update_world/2` — update world attributes
  - `list_maps_for_world/1` — list maps belonging to a world (ordered by newest first)
  - `create_map/2` — updated to accept world association
- [x] Update existing `create_map/1` to require `world_id`
- [x] Add context tests for all new functions

---

## Section 3 — Map Selector UI [sonnet]

- [x] Add a map selector to the navbar (dropdown or horizontal tab bar):
  - Shows all maps for the current world
  - Highlights the currently active map
  - Clicking a map name switches the view to that map
- [x] Add a "New Map" action in the selector:
  - Clicking it enters the empty/upload state for a new map
  - Upload + Save creates a new map associated with the world
- [x] The current "Upload" button behavior changes:
  - If no map is selected (new map flow): works as before
  - If a map is already selected: replaces that map's image
- [x] Show the map name in the navbar (editable inline or via a simple input)

---

## Section 4 — Map Management [sonnet]

- [x] Allow renaming a map (inline edit or modal)
- [x] Allow deleting a map:
  - Confirmation prompt before delete
  - Deletes the DB record and the image file from disk
  - After deletion, switch to the next available map (or empty state if none)
- [x] After saving a new map, it becomes the active map in the selector

---

## Section 5 — World Header [sonnet]

- [x] Display the world name in the navbar or a header area
- [x] Allow editing the world name (inline edit)
- [x] Allow editing the world description (optional — could be a small expandable section or tooltip)

---

## Section 6 — Smoke Test [sonnet]

- [ ] `make up` → app boots, default world is created automatically
- [ ] World name shows in the navbar and is editable
- [ ] Upload and save a map → map appears in the map selector
- [ ] Upload and save a second map → both maps appear in the selector
- [ ] Click between maps in the selector → the map viewer switches images
- [ ] Rename a map → name updates in the selector
- [ ] Delete a map → map is removed, view switches to the next map
- [ ] Delete all maps → empty state shows
- [ ] Refresh the page → last viewed map loads
- [ ] `make test` → all tests pass

---

## Out of Scope

- Multiple worlds / world selection
- Entities, pins, or layers
- Map reordering or sorting options
- Map thumbnails in the selector
- Drag-and-drop map ordering

---

## Done When

- A default world is auto-created on first visit
- The user can name and describe their world
- Multiple maps can be uploaded and saved within the world
- A map selector in the navbar allows switching between maps
- Maps can be renamed and deleted
- The existing pan/zoom and broken-image handling work on all maps
- All maps are associated with the world via foreign key
