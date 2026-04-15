# Issue 8 — Entity Type Registry, Relationships, and Selected Pin Style

## Objective

Refactor the hardcoded entity-type branching into a single registry module (clearing tech debt before it grows), then introduce the dynamic relationships table so entities can be linked with typed, narrative-style connections (Continent "contains" Country, Country "allied with" Country, City "trades with" City). Finish with a small UI polish that visually highlights the currently selected pin on the map.

---

## Constraints

- The registry refactor must be behavior-preserving — no new user-visible behavior in Section 1, only internal restructuring
- Relationships are **generic** — any entity type can relate to any other entity type (Roadmap 2.1: polymorphic)
- Relationships have no DB-level foreign keys (mirrors the `pins` polymorphic pattern): `source_type` + `source_id`, `target_type` + `target_id`
- Relationships are **directional** — `source -> target` with a `type` label; reverse queries handled in the context
- `type` is a free-form string (MVP) — predefined suggestions via a small dropdown, but users can type custom labels
- `attributes` is a `:map` (jsonb) for future per-type data (e.g. "established: 1823"); stored empty for MVP
- Deleting an entity must cascade-delete all relationships where it is source OR target (no orphan relationships)
- Selected-pin visual indicator must not interfere with hover state, pin colors, or the click target
- Layer toggle still hides pins regardless of selection — toggling off a selected pin's layer deselects it (existing behavior preserved)

---

## Section 1 — Entity Type Registry Refactor [sonnet]

Clear the tech debt item tracked in `TECH_DEBT.md`. Replace the four hardcoded callsites with a single source of truth.

### Registry module (`Estratos.EntityTypes`)

- [ ] Create `lib/estratos/entity_types.ex` with a `@types` module attribute:
  ```elixir
  @types [
    %{slug: "continent", name: "Continent", color: "text-green-500", parent_type: nil, layer: "geographic"},
    %{slug: "ocean",     name: "Ocean",     color: "text-blue-500",  parent_type: nil, layer: "geographic"},
    %{slug: "country",   name: "Country",   color: "text-amber-500", parent_type: "continent", layer: "political"},
    %{slug: "city",      name: "City",      color: "text-rose-400",  parent_type: "country",   layer: "political"}
  ]
  ```
- [x] Add `list_types/0` — all registered types
- [x] Add `get_type/1` — lookup by slug, returns map or nil
- [x] Add `color/1` — returns the Tailwind color class for a slug
- [x] Add `name/1` — returns the human-readable name for a slug
- [x] Add `parent_type/1` — returns the parent entity type slug (or nil) for a slug
- [x] Add `parent_fk/1` — returns the FK field atom (or nil) for a slug
- [x] Add `types_in_layer/1` — returns all type slugs belonging to a given layer slug
- [x] Add `schema_module/1` — returns the Ecto schema module for a slug

### Replace hardcoded callsites

- [x] `map_area.ex` — `pin_color_class/1` removed; `EntityTypes.color/1` used inline; pin layer filter uses registry
- [x] `modals.ex` — type dropdown driven by `EntityTypes.list_types/0`; parent dropdown generic via `EntityTypes.parent_type/1` and `entity_lists` map
- [x] `sidebar.ex` — parent fieldset driven by `EntityTypes.parent_type/1`; `parent_options/3` removed
- [x] `map_live.ex save_pin` — single `apply(Entities, type_info.create_fn, ...)` dispatch
- [x] `map_live.ex delete_entity` — single `apply(Entities, type_info.delete_fn, ...)` dispatch
- [x] `map_live.ex toggle_field_edit` — parent and text field both dispatch via registry
- [x] `map_live.ex load_entity_lists` — registry-driven, builds `entity_lists` map keyed by parent type slug
- [x] `map_live.ex load_parent / apply_select_pin / navigate_to_parent` — registry-driven
- [x] `pins.ex get_entity_for_pin/1` — single clause using `type_info.schema_module` + `Repo.get!/2`

### Tests

- [x] Add `test/estratos/entity_types_test.exs` covering each public function
- [ ] Run the existing test suite — all Issue 6 and 7 tests must still pass unchanged
- [x] Update `TECH_DEBT.md` — moved "Entity Type Registry" to Done/Closed with resolution note

---

## Section 2 — Relationship Schema and Migration [sonnet]

### Relationship schema (`Estratos.Relationships.Relationship`)

| Field | Type | Notes |
|---|---|---|
| `id` | `:id` | Primary key |
| `source_type` | `:string` | Required — e.g. `"continent"` |
| `source_id` | `:integer` | Required — polymorphic FK |
| `target_type` | `:string` | Required |
| `target_id` | `:integer` | Required |
| `type` | `:string` | Required — e.g. `"contains"`, `"allied_with"`, `"trades_with"` |
| `attributes` | `:map` | Optional — jsonb, defaults to `%{}` |
| `timestamps` | | |

### Tasks

- [x] Create migration for `relationships` table with all fields above; `attributes` as `:map` with default `%{}`; all four polymorphic columns non-null
- [x] Add composite indexes: `(source_type, source_id)` and `(target_type, target_id)` — relationships are queried by either end
- [x] Create `Estratos.Relationships.Relationship` Ecto schema with changeset
- [x] Changeset validates: all required fields present; `source_type` and `target_type` must be valid slugs in `EntityTypes.list_types/0`; `source` ≠ `target` (no self-relationships — validate that `{source_type, source_id}` ≠ `{target_type, target_id}`)

---

## Section 3 — Relationships Context and Tests [sonnet]

### `Estratos.Relationships` context

- [x] `create_relationship(attrs)` — inserts a new relationship
- [x] `get_relationship!(id)` — standard fetch
- [x] `update_relationship(relationship, attrs)` — only `type` and `attributes` are updatable via `update_changeset/2`
- [x] `delete_relationship(relationship)` — standard delete
- [x] `list_relationships_for_entity(entity_type, entity_id)` — returns all relationships where the entity is either source OR target, ordered by inserted_at
- [x] `delete_relationships_for_entity(entity_type, entity_id)` — bulk-delete all relationships where the entity is source OR target
- [x] Updated `Entities.delete_continent/1`, `delete_ocean/1`, `delete_country/1`, `delete_city/1` — call `Relationships.delete_relationships_for_entity/2` before deleting

### Tests (`test/estratos/relationships_test.exs`)

- [x] `create_relationship/1` creates a relationship with valid fields
- [x] `create_relationship/1` rejects missing fields
- [x] `create_relationship/1` rejects invalid entity types
- [x] `create_relationship/1` rejects self-relationships
- [x] `list_relationships_for_entity/2` returns relationships where entity is source
- [x] `list_relationships_for_entity/2` returns relationships where entity is target
- [x] `list_relationships_for_entity/2` does not return relationships where entity is uninvolved
- [x] `update_relationship/2` updates type and attributes
- [x] `delete_relationship/1` deletes the relationship only
- [x] `delete_relationships_for_entity/2` deletes all relationships involving the entity
- [x] Deleting an entity (via `Entities.delete_*`) also deletes its relationships

---

## Section 4 — Sidebar Relationships Section [sonnet]

Display and manage relationships on the selected entity from the sidebar.

### Data loading

- [x] Extend `apply_select_pin/2` — loads relationships, enriches each with `other_entity`, `other_type`, `direction`; stores as `selected_pin.relationships`; resets `:adding_relationship` to false
- [x] `enrich_relationships/3` private helper uses `apply(Entities, get_fn, [id])` via registry

### Sidebar display (`sidebar.ex`)

- [x] `relationships_section` component below `entity_form`, separated by divider
- [x] Each relationship row: direction arrow (→/←), italic type label, clickable other-entity name, × delete button with confirm
- [x] "+ Add Relationship" button (+ icon) opens inline form; hidden when form is open
- [x] Inline form: type text input with datalist suggestions, target type select (registry-driven), target entity select (from entity_lists), Add/Cancel buttons; `phx-change="relationship_form_changed"` drives target entity dropdown

### `map_live.ex` event handlers

- [x] `toggle_add_relationship` — opens form, resets `new_relationship_target_type` to first type
- [x] `cancel_add_relationship` — closes form
- [x] `relationship_form_changed` — updates `new_relationship_target_type` when target_type select changes
- [x] `add_relationship` — validates type/target not empty, creates relationship, reloads via `apply_select_pin`
- [x] `delete_relationship` — fetches, deletes, reloads via `apply_select_pin`
- [x] `navigate_to_relationship_target` — resolves other side, finds pin on current map, selects or flashes
- [x] `load_entity_lists` updated to include all listable types (continent, country, city) not just parent types
- [x] `move_pin_to` updated to preserve relationships in interim selected_pin

---

## Section 5 — Selected Pin Visual Indicator [sonnet]

Small polish — give the selected pin a visible highlight on the map.

### Tasks

- [x] Pass `selected_pin` attr to `map_pins` component
- [x] Each pin container wrapped in `relative w-7 h-7` div to fix the layout box size
- [x] Ghost icon (`absolute inset-0 w-7 h-7 scale-[1.5] opacity-30`) rendered behind the real icon when pin is selected — doesn't affect layout or anchor point
- [x] Hover tooltip still works (sits outside the fixed wrapper, positioned absolutely from the outer container)
- [x] Deselecting (layer toggle, clicking elsewhere, deleting) removes the indicator since `selected_pin` becomes nil

---

## Section 6 — Smoke Test

- [ ] `make up` -> app boots, existing Country/City/Continent/Ocean pins still work unchanged
- [ ] Pin creation modal still lists all 4 types and filters correctly by active layers
- [ ] Pin colors are unchanged (registry-driven but identical output)
- [ ] Sidebar parent dropdown still works for Country and City
- [ ] Create relationship: select a Continent pin -> sidebar shows empty Relationships section -> click "+ Add Relationship" -> choose type "contains", target type "Country", target "Valdoria" -> Save -> relationship appears in list
- [ ] Relationship appears from the other side: select the Country -> sidebar shows the reverse-direction entry
- [ ] Click a relationship target name -> navigates to that entity's pin on the current map
- [ ] Delete a relationship -> removed from both sides
- [ ] Delete the Country -> its relationships are gone from the Continent's sidebar too
- [ ] Select a pin -> visible ring/highlight appears around it
- [ ] Click a different pin -> highlight moves
- [ ] Click empty map -> highlight disappears
- [ ] Toggle off the selected pin's layer -> pin hides, selection cleared (existing behavior preserved)
- [ ] `make test` -> all tests pass

---

## Out of Scope

- Typed relationship schemas per `type` (e.g. "allied_with" having a start_date field) — `attributes` jsonb is the escape hatch; strongly-typed relationship types are a future issue
- Relationship visualization on the map itself (lines between pins) — future issue
- Bidirectional auto-creation (creating "A contains B" does NOT auto-create "B contained_by A") — relationships are explicit, single-direction
- Relationship type taxonomy / management UI — suggestions are hardcoded in the form's datalist for MVP
- Bulk relationship operations
- Filtering pins by relationships
- History / audit trail for relationship changes

---

## Done When

- A single `Estratos.EntityTypes` module is the source of truth for entity slug, color, parent, layer, and schema module; no more per-type branching in view/live modules
- `TECH_DEBT.md` "Entity Type Registry" entry is moved to Done/Closed
- A `relationships` table stores polymorphic directed links between any two entities
- Sidebar shows, creates, and deletes relationships on the selected entity; reverse-direction entries appear on the other side
- Deleting an entity cascade-deletes its relationships (source or target side)
- Clicking a relationship target navigates to its pin on the current map (or flashes when absent)
- The currently selected pin has a clear visual indicator on the map that does not disturb layout or hover behavior
- All existing Issue 6 and Issue 7 functionality continues to work unchanged
