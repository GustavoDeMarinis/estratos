# Issue 5 — Multi-World Support: Selection and Deletion

## Objective

Extend the app to support multiple worlds. The user can create new worlds, switch between them via a dropdown in the navbar, and delete worlds they no longer need. Each world keeps its own set of maps.

---

## Constraints

- World management lives entirely in the navbar — no separate page
- Deleting a world deletes all its maps (cascade) and their image files from disk
- There must always be at least one world — if the last one is deleted, auto-create a default
- The existing map management (tabs, upload, rename, delete) continues to work scoped to the selected world

---

## Section 1 — Backend: World CRUD and Cascade Delete [sonnet]

- [x] Add to `Estratos.Worlds` context:
  - `list_worlds/0` — returns all worlds ordered by `inserted_at asc`
  - `create_world/1` — creates a world with given attrs (name, description)
  - `delete_world/1` — deletes a world, its maps, and all associated image files from disk
- [x] Add cascade delete: when a world is deleted, all associated maps are deleted (DB + image files)
- [x] Add context tests:
  - Creating a world
  - Listing worlds returns all worlds
  - Deleting a world removes its maps from DB
  - Deleting the last world auto-creates a default

---

## Section 2 — World Selector Dropdown in Navbar [sonnet] ✓

**Where:** Far-left of the navbar, replacing the current static world name text.

**Component:** A DaisyUI `dropdown` button.
- Shows the current world name + a `hero-chevron-down-micro` icon
- Clicking opens a dropdown menu below the button

**Dropdown contents (top to bottom):**
1. List of all worlds — each row shows the world name
   - The currently active world has bold text or a `hero-check-micro` icon
   - Clicking a world name: switches to it (closes dropdown, reloads maps)
2. A divider line
3. A "+ New World" action row at the bottom
   - Clicking opens the existing world edit modal (name + description fields)
   - On submit: creates the world and switches to it

**States:**
- Single world: dropdown shows one world + "New World" — still functional
- Many worlds: scrollable if list is long (max-h with overflow-y-auto)

---

## Section 3 — World Deletion [sonnet]

**Where:** In the world edit modal (opened by clicking the world name in the dropdown, or via a gear/edit icon on each row).

**How it works:**
- The existing world edit modal gains a "Delete World" button (bottom-left, styled as `btn-error btn-outline`)
- Clicking it shows a confirmation: "Delete [world name] and all its maps? This cannot be undone."
- On confirm:
  - All maps for the world are deleted (DB records + image files from disk)
  - The world is deleted
  - If other worlds exist: switch to the first available world
  - If no worlds remain: auto-create "My World" and switch to it

**Alternative approach (if simpler):** Add a small trash icon on each world row in the dropdown (visible on hover). Clicking it triggers the confirmation directly without opening the modal.

---

## Section 4 — World Switching Logic [sonnet]

- [ ] When a world is selected from the dropdown:
  - Update `socket.assigns.world` to the selected world
  - Reload `maps` for the new world
  - Set `map` to the first map of the new world (or nil if none)
  - Clear any pending uploads or rename state
  - Reset image-broken state
- [ ] When a new world is created:
  - Switch to the new world immediately
  - Maps list will be empty — show the empty state ("Upload a map image to get started")
- [ ] When a world is deleted:
  - Switch to next available world, or create default if none

---

## Section 5 — Smoke Test [sonnet]

- [ ] `make up` → app boots, default world exists, world name shows in navbar dropdown
- [ ] Click the world name → dropdown opens showing the current world + "New World"
- [ ] Click "+ New World" → modal opens, fill name, submit → new empty world is active
- [ ] Upload maps to the new world → maps appear in tabs, scoped to this world
- [ ] Open dropdown → click the original world → maps switch to the original world's maps
- [ ] Delete a world with maps → confirmation appears → confirm → maps and world gone, switched to another
- [ ] Delete all worlds → a default world is auto-created
- [ ] `make test` → all tests pass

---

## Out of Scope

- World reordering or sorting
- World thumbnails or previews
- World sharing or permissions
- World duplication/cloning
- Persisting "last selected world" across browser sessions

---

## Done When

- Multiple worlds can be created, each with their own maps
- A navbar dropdown allows switching between worlds
- Switching worlds updates the map tabs and viewer
- Worlds can be deleted with confirmation, cascading to all their maps
- Deleting the last world auto-creates a default
- All existing map features (upload, rename, delete, pan/zoom) work correctly within each world
