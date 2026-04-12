# Issue 7 — Countries, Cities, Layers, and Parent Links

## Objective

Add the first political entity types (Country and City) with structural parent relationships, introduce a layer system that lets users toggle pin visibility by category, and display parent links in the sidebar for navigating entity hierarchies. This establishes the pattern for layered map visualization and entity containment.

---

## Constraints

- Country and City follow the same entity-pin pattern established in Issue 6
- Country has an **optional** `continent_id` FK — a country can exist without a continent (Roadmap 1.3: no mandatory root entity)
- City has an **optional** `country_id` FK — a city can exist without a country
- Both belong to a **world** via `world_id` (same as Continent/Ocean)
- Deleting a parent does NOT cascade-delete children (Roadmap 10.1) — deleting a Continent leaves its Countries intact (they become parentless)
- Deleting an entity still cascade-deletes its own pins (same as Issue 6)
- Layers are predefined in code (not user-creatable — Roadmap 4.1, 4.2), no DB table for MVP
- Layer toggle state is session-only (LiveView assign), not persisted per-map — persistence is a future enhancement
- All entity tables include: `name` (required), `description` (optional), `display_name` (optional)
- Pin schema entity_type validation must be updated to accept `"country"` and `"city"`
- Every place that pattern-matches on entity_type must be updated: `get_entity_for_pin`, `save_pin`, `delete_entity`, `pin_color_class`, pin creation modal dropdown

---

## Section 1 — Schemas and Migrations [sonnet]

### Country schema (`Estratos.Entities.Country`)

| Field | Type | Notes |
|---|---|---|
| `id` | `:id` | Primary key |
| `name` | `:string` | Required |
| `description` | `:string` | Optional |
| `display_name` | `:string` | Optional |
| `world_id` | `references(:worlds)` | Required FK |
| `continent_id` | `references(:continents)` | Optional FK — `on_delete: :nilify_all` |
| `timestamps` | | `inserted_at`, `updated_at` |

### City schema (`Estratos.Entities.City`)

| Field | Type | Notes |
|---|---|---|
| `id` | `:id` | Primary key |
| `name` | `:string` | Required |
| `description` | `:string` | Optional |
| `display_name` | `:string` | Optional |
| `world_id` | `references(:worlds)` | Required FK |
| `country_id` | `references(:countries)` | Optional FK — `on_delete: :nilify_all` |
| `timestamps` | | `inserted_at`, `updated_at` |

### Tasks

- [x] Create migration for `countries` table with fields: name, description, display_name, world_id (FK to worlds), continent_id (optional FK to continents, `on_delete: :nilify_all`) — add indexes on `world_id` and `continent_id`
- [x] Create migration for `cities` table with fields: name, description, display_name, world_id (FK to worlds), country_id (optional FK to countries, `on_delete: :nilify_all`) — add indexes on `world_id` and `country_id`
- [x] Create `Estratos.Entities.Country` Ecto schema — `belongs_to :world`, `belongs_to :continent` (optional); changeset casts all fields, validates `name` and `world_id` required
- [x] Create `Estratos.Entities.City` Ecto schema — `belongs_to :world`, `belongs_to :country` (optional); changeset casts all fields, validates `name` and `world_id` required
- [x] Update `Estratos.Pins.Pin` changeset — add `"country"` and `"city"` to the `entity_type` inclusion validation

---

## Section 2 — Context Functions and Tests [sonnet]

### `Estratos.Entities` context additions

- [ ] Add `create_country(world, attrs)` — builds a country with `world_id` set, optionally sets `continent_id` from attrs, inserts
- [ ] Add `get_country!(id)` — `Repo.get!(Country, id)`
- [ ] Add `update_country(country, attrs)` — applies changeset and updates
- [ ] Add `delete_country(country)` — calls `Pins.delete_pins_for_entity("country", country.id)`, then `Repo.delete(country)`
- [ ] Add `list_countries_for_world(world)` — returns all countries where `world_id == world.id`, ordered by name
- [ ] Add `create_city(world, attrs)`, `get_city!(id)`, `update_city(city, attrs)`, `delete_city(city)` — same pattern as Country, using `"city"` as entity_type for pin cleanup
- [ ] Add `list_cities_for_world(world)` — returns all cities where `world_id == world.id`, ordered by name
- [ ] Add `list_continents_for_world(world)` — returns all continents where `world_id == world.id`, ordered by name (needed for Country parent dropdown)

### `Estratos.Pins` context updates

- [ ] Update `get_entity_for_pin/1` — add clauses for `"country"` and `"city"` that call `Entities.get_country!/1` and `Entities.get_city!/1`

### Tests

- [ ] Test `create_country/2` creates a country with correct world_id
- [ ] Test `create_country/2` with continent_id sets the parent association
- [ ] Test `create_country/2` without continent_id succeeds (parent is optional)
- [ ] Test `create_country/2` returns error changeset when name is missing
- [ ] Test `update_country/2` updates name, description, and continent_id
- [ ] Test `delete_country/1` deletes the country and its pins
- [ ] Test `delete_country/1` does NOT delete cities that reference it (they become parentless)
- [ ] Test `list_countries_for_world/1` returns only countries for the given world
- [ ] Test same CRUD operations for City (with country_id as optional parent)
- [ ] Test `list_cities_for_world/1` returns only cities for the given world
- [ ] Test `list_continents_for_world/1` returns only continents for the given world
- [ ] Test `get_entity_for_pin/1` returns correct Country or City
- [ ] Test deleting a Continent nilifies `continent_id` on its Countries (via `on_delete: :nilify_all`)
- [ ] Test deleting a Country nilifies `country_id` on its Cities (via `on_delete: :nilify_all`)

---

## Section 3 — Wire New Types into Existing UI [sonnet]

This section updates all existing callsites that pattern-match on entity_type. No new UI components — just extending the current flow to handle `"country"` and `"city"`.

### Pin creation modal (`modals.ex`)

- [ ] Add `<option value="country">Country</option>` and `<option value="city">City</option>` to the `pin_type` dropdown in `pin_create_modal`

### Pin colors (`map_area.ex`)

- [ ] Add `pin_color_class("country")` returning `"text-amber-500"` (warm tone for political entities)
- [ ] Add `pin_color_class("city")` returning `"text-rose-400"` (distinct from country)

### `map_live.ex` event handlers

- [ ] Update `handle_event("save_pin", ...)` — add `"country"` and `"city"` clauses that call `Entities.create_country/2` and `Entities.create_city/2`
- [ ] Update `handle_event("delete_entity", ...)` — add clauses that call `Entities.delete_country/1` and `Entities.delete_city/1`

### Tasks

- [ ] Verify that creating a Country or City pin follows the same flow as Continent/Ocean: toggle pin mode, click map, fill modal, save
- [ ] Verify pin colors are visually distinct on the map

---

## Section 4 — Parent Selection in Pin Creation [sonnet]

When creating a Country or City, the user can optionally assign a parent entity. The parent dropdown only appears for entity types that have a parent FK.

### Assigns

- [ ] Add `:continents_list` assign to socket — loaded via `Entities.list_continents_for_world(world)`, refreshed on world change and after entity creation/deletion
- [ ] Add `:countries_list` assign to socket — loaded via `Entities.list_countries_for_world(world)`, refreshed similarly

### Pin creation modal updates (`modals.ex`)

- [ ] Add `attr :continents_list, :list, required: true` and `attr :countries_list, :list, required: true` to `pin_create_modal`
- [ ] When selected type is `"country"`: render an optional `<select name="continent_id">` dropdown populated with `@continents_list`, with a blank "None" option
- [ ] When selected type is `"city"`: render an optional `<select name="country_id">` dropdown populated with `@countries_list`, with a blank "None" option
- [ ] When selected type is `"continent"` or `"ocean"`: no parent dropdown

### `map_live.ex` updates

- [ ] Pass `continents_list={@continents_list}` and `countries_list={@countries_list}` to `pin_create_modal` in render
- [ ] Update `handle_event("save_pin", ...)` for `"country"` to pass `continent_id` from params (if present)
- [ ] Update `handle_event("save_pin", ...)` for `"city"` to pass `country_id` from params (if present)
- [ ] Refresh `continents_list` and `countries_list` after saving a pin (the new entity might be a continent or country that should appear in future dropdowns)

---

## Section 5 — Sidebar Parent Field [sonnet]

When viewing a Country or City in the sidebar, display the parent entity as a readable field with navigation and editing capabilities.

### Data loading

- [ ] When selecting a pin for a Country: load its continent (if `continent_id` is set) and include in `selected_pin` as `%{pin: pin, entity: entity, parent: continent_or_nil}`
- [ ] When selecting a pin for a City: load its country (if `country_id` is set) and include in `selected_pin` as `%{pin: pin, entity: entity, parent: country_or_nil}`
- [ ] For Continent and Ocean: `parent` is always `nil`

### Sidebar display (`sidebar.ex`)

- [ ] Add a "Parent" fieldset in `entity_form`, shown only for entity types that support a parent (`"country"`, `"city"`)
- [ ] The parent field shows the parent entity's `display_name || name` as clickable text
- [ ] Clicking the parent name pushes a `"navigate_to_parent"` event that selects the parent entity's pin on the current map (if it has one)
- [ ] If no parent is set, show "None"
- [ ] Add a pencil edit button that swaps the text for a `<select>` dropdown (same editing pattern as other fields)
- [ ] The dropdown lists available parents for the entity type: continents for Country, countries for City
- [ ] Clicking pencil again saves the new parent via `"update_parent"` event

### `map_live.ex` event handlers

- [ ] Add `handle_event("update_parent", %{"parent_id" => id}, ...)` — updates the entity's parent FK, refreshes `selected_pin` and entity lists
- [ ] Add `handle_event("navigate_to_parent", ...)` — finds the parent entity's pin on the current map, if exists, and selects it (same as `select_pin`); if no pin on current map, flash a brief info message

### Sidebar attrs update

- [ ] Pass `continents_list` and `countries_list` to sidebar for the parent edit dropdown
- [ ] Pass through from `map_viewport` (already receives assigns from `map_live.ex`)

---

## Section 6 — Layer Definitions and Toggle UI [sonnet]

Layers are predefined groupings of entity types. For MVP, layer definitions live in code (no DB table). Toggle state is session-only (LiveView assign).

### Layer definitions module (`Estratos.Layers`)

- [ ] Create `lib/estratos/layers.ex` module with a `@layers` module attribute:
  ```elixir
  @layers [
    %{slug: "geographic", name: "Geographic", icon: "hero-globe-americas-micro", entity_types: ["continent", "ocean"]},
    %{slug: "political", name: "Political", icon: "hero-building-library-micro", entity_types: ["country", "city"]}
  ]
  ```
- [ ] Add `list_layers/0` — returns all layer definitions
- [ ] Add `layer_for_entity_type/1` — given an entity_type string, returns the layer slug it belongs to
- [ ] Add `entity_types_for_layers/1` — given a list of active layer slugs, returns the flat list of entity_types that should be visible

### LiveView assigns

- [ ] Add `:active_layers` assign to socket — initialized as a `MapSet` of all layer slugs (all layers active by default)
- [ ] Reset `:active_layers` to all-active on world switch (different worlds might have different entity distributions)

### Layer toggle UI (navbar)

- [ ] Add a layers dropdown button in the navbar (between the pin toggle and upload form) — icon: `hero-funnel-micro` or `hero-adjustments-horizontal-micro`
- [ ] The dropdown lists each layer with a checkbox/toggle, layer name, and icon
- [ ] Each toggle fires `"toggle_layer"` with `phx-value-slug={layer.slug}`
- [ ] Active layers show a checkmark or filled toggle; inactive layers appear dimmed
- [ ] Use the same colocated hook dropdown pattern as `.WorldDropdown` for close-on-outside-click

### Pin filtering

- [ ] Update `map_pins` component in `map_area.ex` to accept `active_layers` assign
- [ ] Filter rendered pins: only show pins whose `entity_type` belongs to an active layer (use `Layers.layer_for_entity_type/1` to check)
- [ ] When a layer is toggled off, its pins disappear from the map immediately (LiveView re-render)
- [ ] If the currently selected pin's layer is toggled off: deselect the pin and close the sidebar
- [ ] Pin mode respects layers: the entity type dropdown in the creation modal only shows types from active layers

### `map_live.ex` event handler

- [ ] Add `handle_event("toggle_layer", %{"slug" => slug}, ...)` — flip the slug in/out of `:active_layers` MapSet; if selected pin's type is now hidden, deselect it

---

## Section 7 — Smoke Test

- [ ] `make up` -> app boots, map loads, existing continent/ocean pins still work
- [ ] Pin button -> click map -> modal shows 4 entity types: Continent, Ocean, Country, City
- [ ] Create a Country pin -> amber-colored pin appears on map
- [ ] Create a City pin -> rose-colored pin appears on map
- [ ] Create a Country with a Continent parent selected -> sidebar shows parent link
- [ ] Click parent link in sidebar -> navigates to continent's pin (selects it, sidebar shows continent)
- [ ] Create a City with a Country parent selected -> sidebar shows country parent link
- [ ] Edit parent from sidebar (pencil -> dropdown -> save) -> parent updates
- [ ] Delete a Continent that has Countries -> Countries still exist, their continent_id becomes nil, sidebar shows "None" for parent
- [ ] Layer dropdown in navbar shows Geographic and Political toggles, both active by default
- [ ] Toggle Political layer off -> Country and City pins disappear, Continent and Ocean pins remain
- [ ] Toggle Geographic layer off -> only Political pins visible
- [ ] Toggle Political layer off while a City is selected -> sidebar closes, pin deselected
- [ ] Toggle both layers off -> no pins visible, pin mode dropdown still shows all types (or only active layer types if implemented)
- [ ] Switch maps -> layer toggles reset to all-active
- [ ] Pan/zoom -> all pin types track correctly (same coordinate system)
- [ ] `make test` -> all tests pass

---

## Out of Scope

- Persisted per-map layer configuration (future — add `layer_states` DB table)
- User-created layers (Roadmap: not in MVP)
- Entity search / filtering by name
- Multiple pins per entity
- Grid overlay for territorial representation
- Relationships table (dynamic/narrative relationships — future issue)
- Non-pinnable entity types (Weather, GovernmentType — need relationships first)
- Entity type registry module (optimization for when we have 6+ types)

---

## Done When

- Country and City entities can be created with name, description, display_name, and optional parent
- Country pins render in amber, City pins in rose — visually distinct from geographic types
- Parent entity can be selected during creation and edited from the sidebar
- Clicking a parent name in the sidebar navigates to that entity's pin
- Deleting a parent entity nilifies the FK on children (no cascade delete)
- Layer definitions exist in code for Geographic and Political categories
- Layer toggle dropdown in navbar shows/hides pins by category
- Toggling off a layer hides its pins and deselects any selected pin of that type
- All existing Issue 6 functionality (Continent, Ocean) continues to work unchanged
