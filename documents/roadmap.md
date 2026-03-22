# ROADMAP.md

Objectives:

1) Provide a map-centric worldbuilding tool.
2) Enable spatial construction and visualization of information.
3) Reduce cognitive load for a Dungeon Master managing multiple world dimensions.
4) Enable fast access to contextual information during a session.
5) Allow incremental worldbuilding (from micro to macro and vice versa).
6) Represent relationships between world elements clearly.
7) Support storytelling and narrative consistency.
8) Unify information that is typically scattered (maps, notes, relationships, context).
9) Enable future evolution toward more complex systems (timeline, simulation).

Qualities:

1) Typed Flexibility
1.1) The system uses concrete, typed entity tables — not a single generic record model.
1.2) A generic Entity table serves as a catch-all for structures without a dedicated type.
1.3) All entity tables include a `displayName` field so users can label things freely (e.g., use the City structure but call it "Protectorate").
1.4) Entity types are fixed — users cannot define new types.

2) Spatial Focus
2.1) The map is the primary visualization medium.
2.2) All relevant information should be associable with a location.
2.3) Some entity types exist only as data associated with pinned entities (e.g., Weather, GovernmentType, Language) and have no map placement.

3) MVP Simplicity
3.1) Features must be implemented in their minimal functional form.
3.2) Avoid overengineering in early stages.
3.3) Entity types are designed incrementally, with the rule: "it's fine to forget things and add them later, but if we add something we must be sure we want it there."

4) Conceptual Scalability
4.1) The model must allow adding complexity without major refactors.
4.2) The system must be able to evolve toward complex relationships and time.
4.3) The schema must not block future implementation of time events and temporal queries.

5) Hybrid Consistency
5.1) Structural containment is modeled with foreign keys on entity tables.
5.2) Dynamic/narrative connections use a generic relationships table.
5.3) Avoid ad-hoc solutions outside these two relationship mechanisms.

6) Frontend Independence
6.1) The data model must not depend on UI decisions.
6.2) Visualization is a projection of the model, not its definition.
6.3) Backend-first approach — UI details (sidebar vs. modal, layout) are decided later.

7) Fast Iteration
7.1) Decisions must allow adding new features without blocking development.
7.2) The system must be easily extensible via new entity types, relationships, or attributes.

Architectural Decisions:

1) Entity Model — One Table per Entity Type
1.1) Each entity type (City, Country, Continent, Faction, River, etc.) gets its own database table with typed properties.
1.2) A generic Entity table exists as a catch-all for structures the user needs but that don't have a dedicated type.
1.3) All entity tables include a `displayName` field for user-defined labeling.
1.4) Entity types are fixed and cannot be created by users. The generic Entity covers anything not built-in.
1.5) Entity types are designed incrementally, following a hierarchical approach (macro-to-micro or micro-to-macro).

2) Hybrid Relationship Model
2.1) Structural relationships use foreign keys on entity tables (e.g., City has a `country_id` FK to Country). These represent stable, hierarchical containment.
2.2) Dynamic/narrative relationships use a generic `relationships` table with columns: `source_type`, `source_id`, `target_type`, `target_id`, `type`, `attributes`.
2.3) All relationships are directional (source → target).
2.4) Multiple relationships between the same two entities are allowed (e.g., Faction A "controls" City B AND Faction A "founded" City B).
2.5) The generic relationships table supports temporal and narrative changes (e.g., a city changing hands between factions).

3) Relationship Attributes
3.1) The generic relationships table includes a JSON column for flexible attributes.
3.2) This avoids schema changes when different relationship types need different metadata.
3.3) If a specific attribute is frequently queried, it can be promoted to a proper column later.

4) Layers — Predefined and Seeded
4.1) Layers are not user-creatable in MVP. They are predefined groupings of entity types.
4.2) A seed strategy populates the initial layer definitions (e.g., PoliticalLayer groups Countries, Cities, Provinces; GeographicLayer groups Rivers, Mountains, Forests; ClimateLayer groups Weather, Seasons).
4.3) Each layer defines which entity types it displays. Toggling a layer shows/hides all pins of those entity types.
4.4) Layers are associated with specific maps — different maps in the same world can have different layer configurations.

5) Map Groups
5.1) Multiple maps can represent the same geographic area with different visual focuses (political, physical, climate, etc.).
5.2) The map "type" (political, physical, etc.) is a label, not a behavioral flag.
5.3) Each map within a group has its own image and its own layer configuration.
5.4) The user can toggle between maps in a group to switch views.

6) Normalized Coordinates
6.1) Pin positions are stored as normalized float coordinates: `x` (0.0 to 1.0) and `y` (0.0 to 1.0), relative to the map image dimensions.
6.2) On capture: `stored_x = mouse_x / container_width`, `stored_y = mouse_y / container_height`.
6.3) On render: `pixel_x = stored_x * container_width`, `pixel_y = stored_y * container_height`.
6.4) Pins appear in the correct relative position regardless of screen size or container dimensions.
6.5) PostGIS remains installed but is not used in MVP. It will be activated when spatial queries or polygon zones are needed.

7) Map Image Handling
7.1) Map images are stored locally on the filesystem, not in the cloud.
7.2) The map image fits the map container — the container does not resize to the image.
7.3) Low-resolution images stretch and may appear pixelated (acceptable).
7.4) High-resolution images may be downscaled on upload (exact strategy TBD).
7.5) If a new image has different dimensions than the previous one, pins retain their normalized coordinates. Pins that were within bounds may appear shifted; pins are never deleted automatically. A white background fills any empty space, and the user can reposition pins manually.

8) Deletion Behavior
8.1) Entity deletion: orphaned relationships are acceptable. Deleting a Country does NOT cascade-delete its Cities or their pins. Related records simply lose that reference.
8.2) Map deletion: pins keep their coordinates and float unplaced. They are not deleted. Bulk deletion of pins is always an explicit user action, never a side effect.
8.3) No soft deletes in MVP. No undo/redo.

9) Time Events — Post-MVP Design Direction
9.1) A `TimeEvent` model will represent temporal occurrences with `valid_from` and `valid_to` dates.
9.2) Time events reference affected entities via a join table (not an embedded array of IDs).
9.3) The timeline acts as an additional filter — a `currentDate` field lets the user see the world at a specific point in time.
9.4) Time events can affect entity properties conditionally (e.g., frozen rivers in winter, blocked mountain passes).
9.5) This is NOT part of MVP but the schema must not block its future implementation.

Non-Functional Requirements:

1) Performance
1.1) The system must respond interactively to common operations (create, edit, view).
1.2) Map rendering must be smooth when interacting with layers and pins.
1.3) The system must minimize full UI reloads.
1.4) Database queries must scale with the growth of entities and relationships.

2) Real-time UX
2.1) The interface must reflect changes without manual refresh.
2.2) User actions (create pin, edit entity, toggle layer, etc.) must be reflected immediately.
2.3) The system must leverage server-driven UI capabilities (LiveView).

3) Developer Experience
3.1) The system must be easy to extend with new entity types and features.
3.2) The data model must be clear and consistent.
3.3) Code must be organized in a modular way (Phoenix contexts).
3.4) Iteration must be fast with minimal setup friction.

4) Portability
4.1) The application is a web app running locally (offline mode).
4.2) Users download and run the app on their machine via Docker.
4.3) The system must run entirely via docker compose.
4.4) No additional local installations should be required.
4.5) The environment must be consistent across machines.
4.6) No cloud storage in MVP.

5) Data Integrity
5.1) Structural relationships (foreign keys) must remain consistent within their scope.
5.2) Orphaned dynamic relationships are acceptable after entity deletion.
5.3) Critical operations must be atomic.
5.4) No soft deletes in MVP. No undo/redo.

6) Scalability (Conceptual)
6.1) The model must support growth in number of entities across all typed tables.
6.2) The model must support growth in number of relationships (both structural and dynamic).
6.3) The system must be able to evolve toward more complex queries (graph, time).

7) Maintainability
7.1) The system must avoid duplicated logic.
7.2) Domain rules must be centralized.
7.3) Code must be readable and consistent.

Requirements:

1) Entities (Core Data Model)
1.1) Each entity type has its own database table with typed properties.
1.2) All entity tables must include at minimum: name, description, and displayName.
1.3) There must be no mandatory root entity.
1.4) Entities can exist independently, without relationships or map placement.
1.5) The system supports different logical types (City, Country, Faction, River, etc.) as separate tables.
1.6) A generic Entity table serves as a catch-all for types without a dedicated table.
1.7) Some entity types have no map representation (e.g., Weather, GovernmentType, Language). They exist as data associated with pinned entities and are accessible through detail views and search.

2) Maps
2.1) The system must allow creating multiple maps.
2.2) A map must support uploading a static image, stored locally on the filesystem.
2.3) The map image fits the map container; the container does not resize to the image.
2.4) Maps can be grouped to represent the same geographic area with different visual focuses.
2.5) The map "type" (political, physical, climate, etc.) is a descriptive label.
2.6) The user can toggle between maps in a group to switch views.
2.7) A map does not contain data directly — it only visualizes information.

3) Layers
3.1) A map must contain multiple layers.
3.2) Each layer is a predefined grouping of entity types, populated via seed data.
3.3) Layers are not user-creatable in MVP.
3.4) Layers must be toggleable in the frontend. Toggling a layer shows/hides all pins of its entity types.
3.5) Layers are associated with specific maps — different maps can have different layer configurations.
3.6) Active layers may influence which sections are expanded by default in entity detail views.

4) Entity – Map Association
4.1) The system must allow associating entities with one or multiple maps via pins.
4.2) An entity can have multiple pin representations across different maps.
4.3) Pins are placed on a map and belong to the layer that corresponds to their entity type.

5) Geographic Representation
5.1) An entity may have a geographic representation as a pin (point).
5.2) Pin coordinates are stored as normalized floats: `x` (0.0 to 1.0) and `y` (0.0 to 1.0), relative to the map image dimensions.
5.3) Pins render at the correct relative position regardless of screen size or container dimensions.
5.4) Pins are creatable, editable, and deletable.
5.5) Pins must render in real time on the map.
5.6) Polygon zones are deferred to post-MVP. Users rely on well-drawn map images for visual boundaries.

6) Visualization
6.1) The frontend must render maps with active layers.
6.2) The frontend must display pins based on active layers.
6.3) The system must update visualization when data changes.
6.4) The user must be able to interact with pins (click to view details).
6.5) The system must allow filtering via layers.
6.6) When a user clicks a pin, a detail view opens showing entity information.
6.7) The detail view must organize related data by category with expandable/collapsible sections to avoid overwhelming the user.

7) Search
7.1) The user can search entities by name.
7.2) Matching pins are highlighted on the map (or non-matching pins are dimmed/hidden).
7.3) Search is the primary way to navigate large worlds and find entities not visible on the current map/layer configuration.
7.4) Entities without map placement are accessible through search.

8) Relationships
8.1) Structural relationships use foreign keys on entity tables (e.g., City.country_id → Country).
8.2) Dynamic/narrative relationships use a generic relationships table.
8.3) Dynamic relationships are directional (source → target), typed, and support a JSON attributes column.
8.4) Multiple dynamic relationships between the same two entities are allowed.
8.5) Relationships are creatable, editable, and deletable.
8.6) Relationships do not depend on maps.

9) Data Export and Import
9.1) Users can export world data (full or partial) as a database dump file for sharing.
9.2) Import functionality must be able to restore from such dumps.

10) Time (Base Support)
10.1) The system must be designed so the schema does not block future time event implementation.
10.2) The planned `TimeEvent` model will use `valid_from` and `valid_to` dates and reference entities via a join table.
10.3) The MVP does not require timeline implementation.

11) Constraints
11.1) The system must be single-user.
11.2) No authentication is required in the MVP.
11.3) No permission system is required.
11.4) The system must run entirely via docker compose.

Out of Scope (MVP):

1) Multi-user support.
2) Permission system.
3) Full timeline implementation (time events, temporal filters, currentDate).
4) World simulation.
5) Automated rules.
6) Entity versioning.
7) Polygon zones.
8) User-defined entity types (use the generic Entity table instead).
9) User-created layers.
10) Cloud storage.
11) Soft deletes, undo/redo.
