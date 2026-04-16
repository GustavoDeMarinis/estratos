# Issue 9 — Hardening: Data Integrity, LiveComponent Extraction, and Test Coverage

## Objective

Address architectural weaknesses identified during the Issue 8 review before the codebase grows further. Wrap cascading deletes in transactions to prevent orphan data, validate polymorphic IDs exist before inserting, clean up unused dependencies, enforce DB-level constraints on parent FKs, extract MapLive into focused LiveComponents, add LiveView integration tests for critical paths, and refactor the frontend coordinate transform logic into a shared module as prep for future grid/lines rendering.

---

## Constraints

- No user-visible behavior changes — this is purely internal hardening
- Existing tests must continue to pass unchanged
- LiveComponent extraction must preserve all 45 existing event handlers — no functionality dropped
- Coordinate transform refactor must not change pin positioning behavior
- `geo_postgis` removal must be confirmed unused before deleting (grep for any geo types in schemas)

---

## Section 1 — Transactional Cascading Deletes [sonnet]

All `Entities.delete_*` functions currently run pin deletion, relationship deletion, and entity deletion as three independent operations. If any step fails, the others still execute, leaving orphan data.

### Tasks

- [ ] Wrap each `delete_*` function in `Ecto.Multi` so pin cleanup, relationship cleanup, and entity deletion are atomic
- [ ] If any step fails, the entire transaction rolls back — no partial deletes
- [ ] Apply the same pattern to `Worlds.delete_world` (which cascades to maps and entities)
- [ ] Apply the same pattern to `Worlds.delete_map` (which cascades to pins)

### Example

```elixir
def delete_continent(%Continent{} = continent) do
  Multi.new()
  |> Multi.run(:delete_pins, fn _repo, _ ->
    {:ok, Pins.delete_pins_for_entity("continent", continent.id)}
  end)
  |> Multi.run(:delete_relationships, fn _repo, _ ->
    {:ok, Relationships.delete_relationships_for_entity("continent", continent.id)}
  end)
  |> Multi.delete(:delete_entity, continent)
  |> Repo.transaction()
end
```

Note: The return type changes from `{:ok, entity}` to `{:ok, %{delete_entity: entity, ...}}`. All callers must be updated.

---

## Section 2 — Polymorphic ID Existence Validation [sonnet]

`Relationships.create_relationship` validates that `source_type` is a valid slug but never checks that `source_id` actually exists in the corresponding table. A relationship can point to a nonexistent entity.

### Tasks

- [ ] Add `validate_entity_exists/3` to `Relationship` changeset — queries the schema module via `EntityTypes.get_type(type).schema_module` and `Repo.get/2`
- [ ] Apply to both source and target on create
- [ ] Add tests: creating a relationship with a nonexistent source_id fails; creating with nonexistent target_id fails
- [ ] Consider performance: this adds 2 queries per relationship create — acceptable at current scale

---

## Section 3 — Migration: Parent FK Constraints [sonnet]

Current migrations use `on_delete: :nothing` (worlds → maps) and `on_delete: :nilify_all` (countries → continents, cities → countries). The app handles cascades manually, but raw SQL or a bug can leave invalid references.

### Tasks

- [ ] Create migration to alter `maps.world_id` to `on_delete: :cascade` — deleting a world cascades to its maps at DB level
- [ ] Create migration to alter `countries.continent_id` to `on_delete: :nilify` (keep current behavior but make it explicit)
- [ ] Create migration to alter `cities.country_id` to `on_delete: :nilify` (keep current behavior but make it explicit)
- [ ] Verify: continent/ocean/country/city `world_id` should use `on_delete: :cascade` so deleting a world cleans up all entities
- [ ] Add index on `pins.map_id` if missing

---

## Section 4 — Remove Unused Dependencies [sonnet]

### Tasks

- [ ] Grep for `geo_postgis`, `Geo.PostGIS`, `Geo.Point`, or any geo types across the codebase
- [ ] If unused: remove `geo_postgis` from `mix.exs` deps, run `mix deps.get`
- [ ] Check if PostGIS extension is created in any migration — if so, add a migration to drop it (or leave it since it doesn't hurt)
- [ ] Grep for `Swoosh` usage — if no mailer logic exists, consider removing (lower priority, keep if Phoenix generator added it)

---

## Section 5 — LiveComponent Extraction [sonnet]

MapLive is 983 lines with 45 event handlers managing worlds, maps, pins, entities, relationships, layers, modals, uploads, and sidebar state. Extract into focused LiveComponents that handle their own events.

### Proposed Component Boundaries

| Component | Responsibility | Events Owned |
|-----------|---------------|--------------|
| `MapLive` (parent) | World/map selection, image upload, pin mode, layer toggles | ~15 handlers |
| `SidebarLive` | Entity display, field editing, parent navigation | sync_field_value, toggle_field_edit, navigate_to_parent, start_move_pin, delete_entity |
| `RelationshipsLive` | Relationship list, add form, delete, navigate | toggle_add_relationship, cancel_add_relationship, relationship_form_changed, add_relationship, delete_relationship, navigate_to_relationship_target |
| `ModalsLive` | World modal, name map modal, pin create modal | world CRUD events, new_map flow, save_pin, cancel_pin |

### Tasks

- [ ] Extract `SidebarLive` as a `Phoenix.LiveComponent` with its own `handle_event` callbacks
- [ ] Extract `RelationshipsLive` as a nested LiveComponent inside SidebarLive
- [ ] Extract `ModalsLive` as a LiveComponent for modal state and events
- [ ] Parent `MapLive` communicates via `send(self(), ...)` or `send_update/3` for cross-component actions (e.g., relationship target navigation needs to update the parent's selected pin)
- [ ] Keep stateless function components (`map_area.ex`, `map_tabs`, `map_actions`, `zoom_controls`) as-is — they don't own events
- [ ] Verify all 45 event handlers are preserved — no functionality dropped

### Notes

- LiveComponents run in the same process as the parent LiveView — no message-passing overhead
- Components can access the parent's assigns via `@myself` and `send_update`
- The pin movement flow (start_move_pin → move_pin_to → confirm_move) crosses sidebar and map — keep in parent MapLive

---

## Section 6 — LiveView Integration Tests [sonnet]

Zero test coverage for the 45 event handlers in MapLive. Add integration tests using `Phoenix.LiveViewTest` for the critical user flows.

### Tasks

- [ ] Add `test/estratos_web/live/map_live_test.exs`
- [ ] Test: mount with no worlds → shows empty state
- [ ] Test: create world → world appears in navbar
- [ ] Test: create map with image upload → map tab appears
- [ ] Test: toggle pin mode → place pin → fill form → save → pin appears
- [ ] Test: select pin → sidebar opens with entity fields
- [ ] Test: edit entity name → save → name updated
- [ ] Test: create relationship via sidebar form → relationship appears in list
- [ ] Test: delete relationship → removed from list
- [ ] Test: delete entity → pin removed, sidebar closes
- [ ] Test: toggle layer → pins of that layer hidden
- [ ] Test: navigate to parent → selects parent pin

---

## Section 7 — Frontend Coordinate Transform Refactor [sonnet]

The pan/zoom/letterbox coordinate math in `map_container.js` is currently embedded in the hook. Before implementing grid overlay (Canvas) or relationship lines (SVG), extract this into a shared module.

### Tasks

- [ ] Create `assets/js/lib/map_transform.js` — pure functions for:
  - `computeLetterbox(containerRect, imageNaturalWidth, imageNaturalHeight)` → `{offsetX, offsetY, displayWidth, displayHeight}`
  - `normalizedToPixel(normX, normY, letterbox, scale, translateX, translateY)` → `{px, py}`
  - `pixelToNormalized(px, py, letterbox, scale, translateX, translateY)` → `{normX, normY}`
  - `clampTranslate(tx, ty, scale, containerRect)` → `{tx, ty}`
- [ ] Refactor `map_container.js` to import and use these functions
- [ ] Verify: all pin positioning, pin click coordinates, and zoom behavior unchanged
- [ ] Add JSDoc to each function documenting input/output types

---

## Section 8 — Layers Module Tests [sonnet]

`Estratos.Layers` has no test file.

### Tasks

- [ ] Add `test/estratos/layers_test.exs`
- [ ] Test: `list_layers/0` returns all defined layers
- [ ] Test: `all_slugs/0` returns a MapSet of layer slugs
- [ ] Test: `layer_for_entity_type/1` returns correct layer for each entity type
- [ ] Test: `entity_types_for_layers/1` returns correct entity types for a set of active layers

---

## Done When

- All `delete_*` functions are wrapped in `Ecto.Multi` transactions — partial deletes are impossible
- Creating a relationship with a nonexistent entity ID fails with a changeset error
- Parent FK constraints are enforced at the DB level via migration
- `geo_postgis` is removed from `mix.exs` (if confirmed unused)
- MapLive is split into focused LiveComponents — no single file exceeds ~400 lines
- LiveView integration tests cover the critical user flows (pin lifecycle, entity editing, relationships, layers)
- Coordinate transform logic is extracted into a shared JS module
- Layers module has full test coverage
- All existing tests pass unchanged
- No user-visible behavior changes
