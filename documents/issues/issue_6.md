# Issue 6 — Pins, Continents and Oceans

## Objective

Introduce the pin system and the first two pinnable entity types (Continent and Ocean). Users can toggle pin placement mode, click the map to drop a pin, fill out the entity form, and interact with saved pins via a collapsible sidebar. This establishes the entity-pin pattern that all future entity types will follow.

---

## Constraints

- Pins use normalized coordinates (`x`, `y` as floats 0.0–1.0) relative to the map image — see Roadmap 7
- Pins belong to a **map** (not a world) via `map_id`
- Entities (Continent, Ocean) belong to a **world** via `world_id`
- The pin table is polymorphic: `entity_type` (string) + `entity_id` (integer) — no DB-level FK, enforced in code
- One pin per entity per map for now (multi-pin per entity is a future feature — design so it's easy to add)
- Deleting an entity cascade-deletes its pins; deleting a parent entity does NOT cascade-delete child entities or their pins (Roadmap 10.1)
- All entity tables include: `name` (required), `description` (optional), `display_name` (optional) — per Roadmap 1.2

---

## Section 1 — Schemas and Migrations [sonnet]

### Continent schema (`Estratos.Entities.Continent`)

| Field | Type | Notes |
|---|---|---|
| `id` | `:id` | Primary key |
| `name` | `:string` | Required |
| `description` | `:string` | Optional |
| `display_name` | `:string` | Optional — user-defined label |
| `world_id` | `references(:worlds)` | Required FK |
| `timestamps` | | `inserted_at`, `updated_at` |

### Ocean schema (`Estratos.Entities.Ocean`)

Same fields as Continent.

### Pin schema (`Estratos.Pins.Pin`)

| Field | Type | Notes |
|---|---|---|
| `id` | `:id` | Primary key |
| `entity_type` | `:string` | e.g. `"continent"`, `"ocean"` |
| `entity_id` | `:integer` | ID of the referenced entity |
| `map_id` | `references(:maps)` | Required FK |
| `x` | `:float` | Normalized 0.0–1.0 |
| `y` | `:float` | Normalized 0.0–1.0 |
| `timestamps` | | `inserted_at`, `updated_at` |

### Tasks

- [x] Create migration for `continents` table with fields: name, description, display_name, world_id (FK to worlds)
- [x] Create migration for `oceans` table with same fields as continents
- [x] Create migration for `pins` table with fields: entity_type, entity_id, map_id (FK to maps), x, y — add composite index on `[entity_type, entity_id]` and index on `map_id`
- [x] Create `Estratos.Entities.Continent` Ecto schema — `belongs_to :world`; changeset casts all fields, validates `name` and `world_id` required
- [x] Create `Estratos.Entities.Ocean` Ecto schema — same structure as Continent
- [x] Create `Estratos.Pins.Pin` Ecto schema — `belongs_to :map`; changeset casts all fields, validates required `entity_type`, `entity_id`, `map_id`, `x`, `y`; validates `x` and `y` are >= 0.0 and <= 1.0

---

## Section 2 — Context Functions [sonnet]

### `Estratos.Entities` context

- [x] Add `create_continent(world, attrs)` — builds a continent with `world_id` set, inserts it
- [x] Add `get_continent!(id)` — `Repo.get!(Continent, id)`
- [x] Add `update_continent(continent, attrs)` — applies changeset and updates
- [x] Add `delete_continent(continent)` — calls `Pins.delete_pins_for_entity("continent", continent.id)`, then `Repo.delete(continent)`
- [x] Add `create_ocean(world, attrs)`, `get_ocean!(id)`, `update_ocean(ocean, attrs)`, `delete_ocean(ocean)` — same pattern as Continent, using `"ocean"` as entity_type

### `Estratos.Pins` context

- [x] Add `create_pin(attrs)` — inserts a pin with entity_type, entity_id, map_id, x, y
- [x] Add `get_pin!(id)` — `Repo.get!(Pin, id)`
- [x] Add `list_pins_for_map(map)` — query all pins where `map_id == map.id`, ordered by `inserted_at asc`
- [x] Add `update_pin(pin, attrs)` — update pin position (x, y)
- [x] Add `delete_pin(pin)` — `Repo.delete(pin)`
- [x] Add `delete_pins_for_entity(entity_type, entity_id)` — `Repo.delete_all` matching entity_type + entity_id
- [x] Add `get_entity_for_pin(pin)` — pattern match on `pin.entity_type` to call `Entities.get_continent!/1` or `Entities.get_ocean!/1`

### Tests

- [x] Test `create_continent/2` creates a continent with correct world_id
- [x] Test `create_continent/2` returns error changeset when name is missing
- [x] Test `update_continent/2` updates name and description
- [x] Test `delete_continent/1` deletes the continent from DB
- [x] Test `delete_continent/1` also deletes all pins referencing that continent
- [x] Test same CRUD operations for Ocean
- [x] Test `create_pin/1` creates a pin with valid normalized coordinates
- [x] Test `create_pin/1` rejects x or y outside 0.0–1.0 range
- [x] Test `list_pins_for_map/1` returns only pins for the given map
- [x] Test `list_pins_for_map/1` does not return pins from other maps
- [x] Test `update_pin/2` updates x and y coordinates
- [x] Test `delete_pin/1` deletes the pin but not the entity
- [x] Test `delete_pins_for_entity/2` deletes all pins matching entity_type + entity_id
- [x] Test `get_entity_for_pin/1` returns the correct continent or ocean

---

## Section 3 — Pin Placement UI [sonnet]

- [x] Add a `:pin_mode` boolean assign to socket, initialized to `false`
- [x] Add a pin toggle button in the navbar between the world dropdown and upload buttons — icon: `hero-map-pin-solid`, style: `btn-ghost` when off, `btn-active` when on
- [x] Add `handle_event("toggle_pin_mode")` — flips `:pin_mode`, clears any pending pin placement when toggling off
- [x] When `:pin_mode` is true, add CSS class `cursor-crosshair` to the map container
- [x] Add a JS hook (`.PinPlacement`) on the map container that listens for clicks when pin mode is on
- [x] On map click in pin mode: calculate normalized coordinates accounting for pan/zoom transform — `x = (click_x - container_x - translateX) / (container_width * scale)`, same for y
- [x] Push a `"pin_clicked"` event to the server with `%{x: normalized_x, y: normalized_y}`
- [x] Add `handle_event("pin_clicked", %{"x" => x, "y" => y})` — store pending pin position in socket assign `:pending_pin` as `%{x: x, y: y}`, open the pin creation modal
- [x] Add a `:pending_pin` assign (nil or `%{x, y}`), initialized to nil
- [x] Create a `pin_create_modal` component, shown when `:pending_pin` is not nil
- [x] Modal contains: a `<select>` dropdown with options "Continent" and "Ocean", an input for `name` (required), an input for `display_name` (optional), a textarea for `description` (optional), Save and Cancel buttons
- [x] Add `handle_event("save_pin", params)` — create the entity via `Entities.create_continent/2` or `create_ocean/2`, then create the pin via `Pins.create_pin/1` with the pending coordinates, clear `:pending_pin`, toggle pin mode off, reload pins list
- [x] Add `handle_event("cancel_pin")` — clear `:pending_pin`, keep pin mode on so user can try again
- [x] Render a temporary pin marker on the map at the pending position (same style as saved pins but slightly transparent) while the modal is open

---

## Section 4 — Pin Rendering on Map [sonnet]

- [x] Add `:pins` assign to socket, loaded via `Pins.list_pins_for_map(map)` on mount and after any map/world switch
- [x] For each pin, also load and cache the entity (name, type) — either preload in list query or load via `get_entity_for_pin/1`; store as a list of `%{pin: pin, entity: entity}` maps in the assign
- [x] Create a `map_pins` component that renders inside the map container, after the image
- [x] Each pin renders as an absolutely-positioned `<div>` with `style="left: #{pin.x * 100}%; top: #{pin.y * 100}%"` and `transform: translate(-50%, -100%)` to anchor at the pin tip
- [x] Pin icon: an SVG map pin (or `hero-map-pin-solid`) — continent pins get a green/earth color class, ocean pins get a blue color class
- [x] Pins must be children of a wrapper div that has the same CSS transform as the map image (translate + scale) so they pan/zoom together with the image
- [x] Pin size stays constant: apply `transform: scale(#{1/current_scale})` on each pin to counteract the zoom via JS hook `applyTransform`
- [x] Add `phx-click="select_pin"` with `phx-value-id={pin.id}` on each pin element
- [x] Add CSS-only tooltip on hover (`group-hover`) for tooltip
- [x] Create a tooltip div per pin: hidden by default, shown on hover via CSS `group-hover`, positioned above the pin — contains entity name (bold, first line) and entity type (second line, smaller text)
- [x] Ensure pin clicks do NOT trigger the map click for pin placement (stop propagation in the JS hook via `data-pin` check)
- [x] Reload pins when switching maps (`select_map` event) or switching worlds (`select_world` event)

---

## Section 5 — Sidebar Panel [sonnet]

- [x] Add `:selected_pin` assign to socket (nil or `%{pin: pin, entity: entity}`), initialized to nil
- [x] Add `:sidebar_open` boolean assign, initialized to `false`
- [x] Create a `sidebar` component rendered inside the map area, on the left side, as an absolutely-positioned div
- [x] Sidebar width: `255px` when open, `0px` when closed (content hidden with `overflow-hidden`)
- [x] Add CSS transition: `transition-all duration-300` for smooth expand/collapse
- [x] Sidebar background: `bg-base-200` with a right border (`border-r border-base-content/10`)
- [x] Create the sidebar toggle button: a `<button>` element, 25px wide x 80px tall, attached to the right edge of the sidebar as a flex sibling
- [x] Toggle button styling: `bg-base-200 rounded-r-lg shadow-md border border-l-0 border-base-content/10`
- [x] Toggle button arrow: `hero-chevron-left-micro` when sidebar is open, `hero-chevron-right-micro` when closed
- [x] Toggle button disabled state: when `:selected_pin` is nil, button gets `disabled:opacity-30 disabled:cursor-not-allowed`, click does nothing
- [x] Toggle button hover preview: when a pin is selected and sidebar is collapsed, on hover `max-w-0 group-hover:max-w-[150px]` reveals the pin name and type text next to the arrow
- [x] Add `handle_event("toggle_sidebar")` — flips `:sidebar_open` if a pin is selected
- [x] Add `handle_event("select_pin", %{"id" => id})` — load the pin and its entity, set `:selected_pin`, set `:sidebar_open` to true
- [x] Add `handle_event("deselect_pin")` — set `:selected_pin` to nil, set `:sidebar_open` to false
- [x] On map background click (not on a pin): JS hook `onPinClick` checks `e.target.closest("[data-pin]")` — pushes `"deselect_pin"` on background click outside pin mode

---

## Section 6 — Entity Detail View in Sidebar [sonnet]

- [x] Create an `entity_form` component rendered inside the sidebar when `:selected_pin` is not nil
- [x] The form uses DaisyUI `fieldset` with `fieldset-legend` for each field group
- [x] Use compact sizing throughout: `input-sm` for inputs, `textarea-sm` for textareas, `text-xs` for legends, `gap-3` between field groups
- [x] Add `:editing_fields` assign to socket — a MapSet of field names currently being edited
- [x] Add `:field_values` assign to track field values synced via `phx-change`
- [x] Field: **Name** — `fieldset-legend` "Name", `input input-sm input-bordered w-full`, disabled unless field is in `:editing_fields` or value is empty
- [x] Field: **Display Name** — same pattern, legend "Display Name"
- [x] Field: **Description** — legend "Description", `textarea textarea-sm textarea-bordered w-full`, 2 rows
- [x] Field: **Position** — legend "Position", read-only text showing `"#{Float.round(x * 100, 1)}%, #{Float.round(y * 100, 1)}%"`, no edit button
- [x] Each editable field row is a flex container with the input taking `flex-1` and a small pencil button (`hero-pencil-square-micro`, `btn-ghost btn-xs`) on the right
- [x] Add `handle_event("toggle_field_edit", %{"field" => field_name})` — if field in editing set: save the field value (read from `:field_values`), remove from editing set; if not: add to editing set
- [x] Add `handle_event("sync_field_value", %{"field" => field, "value" => value})` — sync input value to `:field_values` on phx-change
- [x] Empty fields auto-edit: disabled unless field is in `:editing_fields` or value is empty (e.g., `disabled={!MapSet.member?(...) and field_value != ""}`)
- [x] Wrap the fields area in a scrollable div: `overflow-y-auto` with `flex-1` so it fills available space above the fixed bottom actions
- [x] The overall sidebar layout is a flex column: header (entity type label), scrollable fields area (`flex-1 overflow-y-auto`), fixed bottom actions (stub for Section 7)

---

## Section 7 — Pin Actions (Move and Delete) [sonnet]

- [x] Create a `sidebar_actions` component rendered at the bottom of the sidebar, inside a fixed/sticky container: `border-t border-base-content/10 p-2 bg-base-200 flex gap-2`
- [x] **Move Pin** button: `btn btn-outline btn-sm flex-1` with `hero-arrows-pointing-out-micro` icon and text "Move"
- [x] **Delete** button: `btn btn-error btn-outline btn-sm flex-1` with `hero-trash-micro` icon and text "Delete"
- [x] Add `:moving_pin` assign to socket (nil or `%{pin_id, original_x, original_y}`), initialized to nil
- [x] Add `handle_event("start_move_pin")` — store original position in `:moving_pin`, collapse the sidebar, change cursor to crosshair (reuse pin placement mode cursor logic)
- [x] In the JS hook: when `:moving_pin` is set, next map click calculates new normalized coords and pushes `"move_pin_to"` event with `%{x, y}`
- [x] Add `handle_event("move_pin_to", %{"x" => x, "y" => y})` — temporarily update the pin position in assigns (for visual feedback), set a `:confirm_move` assign with the new coordinates
- [x] Show a small confirmation modal: "Confirm new position?" with Confirm and Cancel buttons
- [x] Add `handle_event("confirm_move")` — call `Pins.update_pin(pin, %{x: new_x, y: new_y})`, clear `:moving_pin` and `:confirm_move`, reload pin data, reopen sidebar
- [x] Add `handle_event("cancel_move")` — restore pin to original position from `:moving_pin`, clear `:moving_pin` and `:confirm_move`, reopen sidebar
- [x] **Delete** button has `phx-confirm={"Delete this #{entity_type} and its pin? This cannot be undone."}`
- [x] Add `handle_event("delete_entity")` — call `Entities.delete_continent/1` or `delete_ocean/1` (which cascade-deletes pins), clear `:selected_pin`, set `:sidebar_open` to false, reload pins for current map

---

## Section 8 — Smoke Test [sonnet]

- [x] `make up` → app boots, map loads
- [x] Click the pin button in navbar → button appears pressed, cursor is crosshair on map
- [x] Click on the map → pin icon appears at click location, creation modal opens
- [x] Select "Continent", fill name, save → pin is saved, visible on map with green color
- [x] Hover over pin → tooltip shows name (bold) and "Continent" below
- [x] Click pin → sidebar expands from left (255px) showing continent details
- [x] Edit the name field via pencil icon → field becomes editable → click pencil again → saves
- [x] Empty description field is already editable without clicking pencil
- [x] Click sidebar toggle button → sidebar collapses, arrow flips
- [x] Hover toggle button with pin selected → button expands to show pin name
- [x] Click toggle again → sidebar reopens
- [x] Click "Move" → sidebar closes, cursor is crosshair → click new location → pin teleports → confirm modal → confirm → pin stays at new position
- [x] Repeat move but cancel → pin returns to original position
- [x] Click "Delete" → confirm → continent and pin removed, sidebar closes
- [x] Create an ocean pin → blue color pin, same full flow works
- [x] Switch maps → pins are scoped to each map (different maps show different pins)
- [x] Switch worlds → entities and pins belong to that world's maps
- [x] Pan/zoom the map → pins stay at correct relative positions on the image
- [x] Click map background (not a pin) → sidebar closes, pin deselected
- [x] `make test` → all tests pass

---

## Out of Scope

- Layers and layer toggling (future issue)
- Search / filtering pins
- Multiple pins per entity
- Pin clustering at low zoom
- Pin drag-and-drop (we use "Move Pin" button + click-to-place instead)
- Keyboard shortcuts for pin mode
- Pin animations
- Entity relationships (future issue)

---

## Done When

- Continent and Ocean entities can be created with name, description, display_name
- Pins can be placed on the map by clicking in pin placement mode
- Pins render at the correct normalized position and stay correct during pan/zoom
- Hovering a pin shows a tooltip with name and type
- Clicking a pin opens a collapsible sidebar showing entity details
- Entity fields can be edited inline (per-field edit toggle)
- Pins can be moved to a new location with confirmation
- Entities can be deleted (cascading to their pins)
- All pins are scoped to their map
- All entities are scoped to their world
