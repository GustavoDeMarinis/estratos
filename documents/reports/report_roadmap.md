    1) Blind Spots (Missing Concepts)
    1.1 — No definition of what a "registro" (record/entity) actually contains beyond name + description
    Requirement 1.2 says "atributos básicos (nombre, descripción)" but the system is meant to represent cities, factions, biomes, planets, etc. These all need wildly different attributes. There is no mention of custom attributes, metadata, or a flexible key-value schema. Without this, every entity is just a name and a text blob — which cripples the "reduce cognitive load" objective.

    1.2 — No concept of entity detail view or editing UX
    The document describes map visualization extensively but never defines what happens when you click an entity. What does the user see? A panel? A modal? A full page? What can they edit? This is a core interaction loop that is completely unspecified.

    1.3 — No mention of search or navigation outside the map
    Objective 4 says "acceso rápido a información contextual" but the only navigation mechanism described is the map. What if the user has 200 entities and needs to find one that isn't pinned on any map? There's no search, no list view, no sidebar — nothing.

    1.4 — No concept of entity deletion and its cascading effects
    Entities can have multiple geographic representations, multiple relationships, and multiple map/layer associations. What happens when an entity is deleted? Cascade delete everything? Orphan the relationships? This is critical for data integrity (NFR 5.2) and completely absent.

    1.5 — No definition of map coordinate system
    Requirement 5.3 says "coordenadas relativas al mapa (x, y)" but doesn't define the coordinate space. Is it pixel-based? Percentage-based? Does it depend on image resolution? What happens if the map image is replaced with one of different dimensions? Every pin and zone could break.

    1.6 — No image management strategy
    Maps use static images (2.2) but there's no mention of: upload mechanism, storage location (filesystem vs DB), size limits, supported formats, or how images are served. For a map-centric tool, this is a foundational gap.

    2) Ambiguities (Unclear Definitions)
    2.1 — "Tipos lógicos" (1.5 + 1.6) — type system is undefined
    The document says types can be "a field" but doesn't say whether types are:

    Free-text strings ("ciudad", "Ciudad", "city")
    A fixed enum
    User-defined from a managed list
    Interpretation A (free text): No consistency, filtering by type becomes unreliable.
    Interpretation B (enum): Requires predefined list — contradicts flexibility.
    Interpretation C (managed list): Adds a CRUD surface not mentioned anywhere.

    This directly impacts layers (3.5) since layers filter by "type of information."

    2.2 — Relationship between layers and entity types
    Requirement 3.5 says a layer defines "the type of information visualized (territories, cities, climate, fauna)." Requirement 4.2 says entities are associated to layers. So: does the layer determine what entities appear on it (automatic, by type), or does the user manually assign entities to layers? These produce fundamentally different data models and UX.

    2.3 — "Relaciones tipadas" (7.2) — same ambiguity as entity types
    Are relationship types free-text? Predefined? User-managed? Can a relationship have attributes (e.g., "controls since year 1200")? The document is silent.

    2.4 — Map types (2.4) — decorative or functional?
    "Political, physical, climatic" map types: is this just a label, or does map type affect behavior (e.g., which layers are available, which entity types can appear)? If it's just a label, why mention it? If it's functional, the rules are undefined.

    2.5 — "Prepared for time" (section 8) vs. "Don't build timeline" (10.3)
    Requirement 8.1 says "the system must be prepared to support time." Prepared how? Adding valid_from/valid_to columns now? Designing the schema to not preclude temporal queries? This is dangerously vague — it could mean anything from "add nullable timestamp fields" to "design a full bitemporal schema."

    3) Hidden Complexity (Underestimated Areas)
    3.1 — Polygon editing on image-based maps
    Requirement 5.4 says zones are defined as polygons. Building a polygon editor on top of a static image in LiveView is non-trivial. This requires: click-to-place vertices, visual feedback, polygon closing, editing existing polygons (moving vertices, adding/removing points), and rendering overlapping zones. This is one of the hardest UI features in the entire MVP and is described in one line.

    3.2 — Multiple geographic representations per entity (5.5)
    An entity can appear as a pin on one map and a zone on another — or multiple pins on the same map. This creates a many-to-many-to-many relationship (entity ↔ map ↔ layer ↔ geometry). The join model here is complex and the UI for managing it will be non-obvious.

    3.3 — Layer toggle performance
    Toggling layers requires filtering and re-rendering potentially hundreds of pins and polygons in real-time. With LiveView's server-driven approach, this could mean significant payload on every toggle. The document assumes this is simple (3.4: "activarse/desactivarse") but doesn't acknowledge the rendering cost.

    3.4 — Graph-like relationship model without graph queries
    The system is described as "graph-like" (flexible entity + relationship model) but PostgreSQL is not a graph database. Queries like "show me all entities related to X within 3 hops" will require recursive CTEs or materialized paths. The document assumes relational flexibility without acknowledging query complexity.

    4) Risky Decisions (Future Pain Points)
    4.1 — "Everything is a registro" could become a god-table
    A single table for cities, factions, biomes, and planets means the entities table will grow in columns (if attributes are added) or require a JSON/EAV pattern. Either approach has well-known downsides: JSON columns complicate queries and validation; EAV is notoriously slow and hard to reason about. This is fine for MVP, but the document doesn't acknowledge the future cost.

    4.2 — PostGIS for image-relative coordinates is a mismatch
    The tech stack includes PostGIS, but requirement 5.3 uses coordinates "relative to the map." PostGIS is designed for real-world geographic coordinates (lat/lng, SRID). Using PostGIS for arbitrary pixel/percentage coordinates means either: (a) misusing PostGIS with a fake SRID, losing most of its value, or (b) mapping image coordinates to a geographic projection, adding complexity. This decision needs explicit justification or reconsideration.

    4.3 — No versioning + single-user = data loss risk
    Record versioning is explicitly out of scope (10.6), and there's no mention of undo/redo. A single misclick deleting an entity with 50 relationships destroys data with no recovery path. For a single-user worldbuilding tool where data represents hours of creative work, this is a significant risk.

    4.4 — Tight coupling between map visualization and entity model
    Requirement 2.5 says "a map does not contain data directly, only visualizes information" — but the geographic representation (5.1-5.6) ties entity geometry to specific maps. If a map image is replaced or a map is deleted, what happens to the associated geometries? The "maps don't own data" principle conflicts with the reality that geometries are meaningless without their map context.

    5) MVP Scope Violations
    5.1 — Multiple map types (2.4)
    For MVP, one map type is sufficient. Supporting "political, physical, climatic" map types adds classification complexity without clear user value in v1. A label field is fine; typed behavior is not MVP.

    5.2 — Multiple geographic representations per entity (5.5)
    Allowing an entity to have multiple representations on the same map significantly increases UI and data model complexity. For MVP, one representation per entity per map would dramatically simplify the system while remaining useful.

    5.3 — Section 8 (Time / Base Support) should be entirely removed from MVP scope
    Even "being prepared" for time has a cost. Every decision made to "prepare" for temporal support adds schema and code complexity. Either define the exact preparation (e.g., "all tables have a valid_at column, nullable, unused in MVP") or remove this section entirely and let the post-MVP design handle it.

    5.4 — Polygon zones in MVP
    Given the hidden complexity of polygon editing (see 3.1), consider starting with pins only. Zones could be a fast-follow feature once the core map interaction is solid.

    6) Domain Modeling Gaps
    6.1 — The join model between entity, map, layer, and geometry is undefined
    This is the most critical modeling gap. There are at least 4 entities interacting:

    Entity (the thing)
    Map (the canvas)
    Layer (the filter)
    GeographicRepresentation (the shape)
    How do these relate? Is it: Entity → MapPlacement(map_id, layer_id, geometry)? Or: Entity → Geometry + Geometry → Layer + Layer → Map? The answer fundamentally shapes the schema and every query in the system.

    6.2 — No cardinality constraints on relationships
    Requirement 7 defines typed relationships but doesn't specify:

    Can an entity have two "belongs_to" relationships to different parents?
    Can a relationship type be used between any two entity types?
    Are relationships directional? (A "controls" B ≠ B "controls" A)
    Without these rules, the graph model is unconstrained and can represent nonsensical states.

    6.3 — No definition of what "layer as semantic filter" means in data terms
    Requirement 3.2 says layers are "semantic filters" but doesn't define the filtering mechanism. Does a layer filter by entity type? By explicit assignment? By geographic region? By relationship? This determines whether layers are simple tags or complex query definitions.

    6.4 — Entity type vs. layer type overlap
    Both entities and layers have "types" (cities, territories, climate, fauna). Is there a 1:1 correspondence? Can a "cities" layer show entities of type "faction"? If not, layers are redundant with entity types. If yes, the assignment rules are undefined.

    7) Critical Questions
    What is the coordinate system for maps? Percentage-based (0-100), pixel-based, or normalized (0-1)? What happens when a map image is resized or replaced?

    How are entities assigned to layers — automatically by type, or manually by the user? This is the single most impactful modeling decision in the system.

    What is the exact join model between Entity, Map, Layer, and Geometry? Draw the ER diagram before writing any migration.

    Are relationship types directional? Does "A controls B" imply anything about B's relationship to A?

    What attributes can an entity have beyond name and description? If custom attributes are needed, what is the storage strategy (JSON column, EAV table, or fixed schema)?

    What is the intended use of PostGIS? If maps use image-relative coordinates, what value does PostGIS add over simple float columns? If PostGIS is kept, what SRID will be used?

    What happens when a map is deleted? Are all associated placements/geometries deleted? What about entities that only exist on that map?

    What happens when an entity is deleted? Cascade delete relationships and geographic representations? Require the user to remove associations first?

    Should layer toggling be purely client-side (show/hide already-loaded data) or server-driven (re-query)? This has major implications for performance architecture.

    Is polygon zone editing truly MVP? Given the implementation cost, can MVP launch with pins only and add zones in a fast-follow iteration?

    What does "prepared for time" mean concretely? List the exact schema decisions this requires, or remove it from the document.

    Can an entity exist without any map association? The document implies yes (1.4: "independent records") but the system is "map-centric" — what is the UX for orphaned entities?