# Prompt: Update ROADMAP.md with architectural decisions

You are a senior software architect working on a worldbuilding tool called Estratos. The project uses Elixir, Phoenix LiveView, PostgreSQL (with PostGIS installed but unused in MVP).

## Context

An analysis of the original ROADMAP.md identified blind spots, ambiguities, and risks. The project owner has now answered all critical questions. Your task is to **rewrite ROADMAP.md** incorporating the decisions below.

## Rules

- Keep the same document structure (Objectives, Qualities, Non-Functional Requirements, Requirements, Out of Scope)
- Add a new section: **Architectural Decisions** — placed between Qualities and Non-Functional Requirements
- Update existing requirements to reflect the decisions (remove contradictions, add precision)
- Do NOT add implementation details (no schema SQL, no code, no file paths)
- Do NOT invent new requirements — only clarify and refine existing ones based on the decisions
- Keep language concise and declarative (same style as the original)
- Write in English

## Decisions to incorporate

### 1. Entity model: one table per entity type

- Each entity type (City, Country, Continent, Faction, River, etc.) gets its own database table with typed properties.
- There is also a generic "Entity" table as a catch-all for structures the user needs but that don't have a dedicated type.
- All entity tables include a `displayName` field so the user can label things however they want (e.g., use the City structure but call it "Protectorate").
- Entity types are fixed — users cannot define new entity types. They use the generic Entity for anything not covered.
- Entity types are designed incrementally, hierarchically (macro-to-micro or micro-to-macro), with the rule: "it's fine to forget things and add them later, but if we add something we must be sure we want it there."
- This replaces the original concept of "everything is a generic record." The system uses concrete, typed entity tables.

### 2. Hybrid relationship model

- **Structural relationships** use foreign keys (e.g., City has a `country_id` FK to Country). These represent stable, hierarchical containment.
- **Dynamic/narrative relationships** use a generic `relationships` table with columns: `source_type, source_id, target_type, target_id, type, attributes`.
- All relationships are **directional** (source → target).
- Multiple relationships between the same two entities are allowed (e.g., Faction A "controls" City B AND Faction A "founded" City B).
- The generic relationships table supports temporal and narrative changes (e.g., a city changing hands between factions).

### 3. Relationship attributes

- The generic relationships table includes a JSON column for flexible attributes.
- This avoids schema changes when different relationship types need different metadata.
- If a specific attribute is frequently queried, it can be promoted to a proper column later.

### 4. Layers are predefined and seeded

- Layers are not user-creatable in MVP. They are predefined groupings of entity types.
- A seed strategy populates the initial layer definitions (e.g., PoliticalLayer groups Countries, Cities, Provinces; GeographicLayer groups Rivers, Mountains, Forests; ClimateLayer groups Weather, Seasons).
- Each layer defines which entity types it displays. Toggling a layer shows/hides all pins of those entity types.
- Layers are associated with specific maps — different maps in the same world can have different layer configurations.

### 5. Map groups

- Multiple maps can represent the same geographic area with different visual focuses (political, physical, climate, etc.).
- The map "type" (political, physical, etc.) is a label, not a behavioral flag.
- Each map within a group has its own image and its own layer configuration.
- The user can toggle between maps in a group to switch views.

### 6. Normalized coordinates (0.0 to 1.0)

- Pin positions are stored as normalized float coordinates: `x` (0.0 to 1.0) and `y` (0.0 to 1.0), relative to the map image dimensions.
- On capture: `stored_x = mouse_x / container_width`, `stored_y = mouse_y / container_height`.
- On render: `pixel_x = stored_x * container_width`, `pixel_y = stored_y * container_height`.
- This ensures pins appear in the correct relative position regardless of screen size or container dimensions.
- PostGIS remains installed but is not used in MVP. It will be activated when spatial queries or polygon zones are needed.

### 7. Pins only for MVP — no polygon zones

- MVP supports only pin (point) representations on maps.
- Polygon zones are deferred to a post-MVP iteration.
- Users must rely on well-drawn map images for visual boundaries (rivers, borders, etc.) and use pins for point locations.

### 8. Map image handling

- Map images are stored locally (filesystem, not cloud).
- The map image fits the map container — the container does not resize to the image.
- Low-resolution images stretch and may appear pixelated (this is acceptable).
- High-resolution images may be downscaled on upload (exact strategy TBD).
- If a new image has different dimensions than the previous one, pins retain their normalized coordinates. Pins that were within bounds may appear shifted; pins are never deleted automatically. A white background fills any empty space, and the user can reposition pins manually.

### 9. Deletion behavior

- **Entity deletion**: orphaned relationships are acceptable. Deleting a Country does NOT cascade-delete its Cities or their pins. Related records simply lose that reference.
- **Map deletion**: pins keep their coordinates and float unplaced. They are not deleted. Bulk deletion of pins is always an explicit user action, never a side effect.
- No soft deletes in MVP. No undo/redo.

### 10. Search

- The user can search entities by name.
- Matching pins are highlighted on the map (or non-matching pins are dimmed/hidden).
- This is the primary way to navigate large worlds and find entities that may not be visible on the current map/layer configuration.

### 11. Entity detail display

- When a user clicks a pin, a detail view opens (likely a sidebar, final UX TBD — backend-first approach).
- The detail view must handle potentially large amounts of related data (government, languages, weather, fauna, flora, points of interest, etc.).
- Information must be organized to avoid overwhelming the user — grouped by category, with expandable/collapsible sections.
- Active layers may influence which sections are expanded by default.

### 12. Data export / offline-first

- The application is a web app running locally (offline mode).
- Users download and run the app on their machine via Docker.
- No cloud storage in MVP.
- Users can export world data (full or partial) as a database dump file for sharing with others.
- Import functionality should be able to restore from such dumps.

### 13. Time events (post-MVP design direction)

- A `TimeEvent` model will represent temporal occurrences with `valid_from` and `valid_to` dates.
- Time events reference affected entities via a join table (not an embedded array of IDs).
- The timeline acts as an additional filter — a `currentDate` field (stored location TBD) lets the user see the world at a specific point in time.
- Time events can affect entity properties conditionally (e.g., frozen rivers in winter, blocked mountain passes).
- This is NOT part of MVP but the schema should not block its future implementation.

### 14. Entities without map placement

- Some entity types will never have pins (e.g., Weather, GovernmentType, Language).
- These entities exist as data associated with pinned entities (a City has a GovernmentType, speaks certain Languages, etc.).
- They are accessible through the detail view of pinned entities, and through search.
- There is no standalone "list all entities" view in MVP — search and pin interaction are the navigation methods.

## What to produce

Rewrite the full ROADMAP.md document incorporating all the above. The document should be self-contained — a developer reading only the roadmap should understand all architectural decisions and constraints without needing this prompt.
