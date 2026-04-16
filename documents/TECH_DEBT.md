# Technical Debt Tracker

A living document of known issues, inefficiencies, and refactoring opportunities. These are intentionally deferred to maintain velocity but should be addressed when the codebase reaches critical mass or when blocks future work.

---

## Backlog

### Selected Pin Highlight Too Subtle

The ghost-icon halo on the selected pin is functional but not prominent enough. Explore alternatives: thicker ring, animated pulse, or higher-contrast glow. Must not affect layout or the pin's click target.

### Sidebar Should Not Double as Editor

The sidebar currently serves both as the entity detail view and as the inline editor. This mixes read and edit concerns and clutters the panel. Extract entity editing into a dedicated modal so the sidebar stays a clean, read-only detail view.

### Place Pin Button Placement

The "Place Pin" button is in the navbar. It should be repositioned above the zoom-in button in the bottom-right map controls cluster, keeping map-interaction controls grouped together.

---

## Future Improvements (Post-MVP)

*Placeholder for structural improvements that require schema changes or major refactors.*

---

## Done / Closed

### Entity Type Registry (Hardcoded Dropdowns)

**Resolved in:** Issue 8 Section 1

**What was done:**
Created `Estratos.EntityTypes` module (`lib/estratos/entity_types.ex`) as the single source of truth for each entity type's slug, display name, pin color, parent relationship, layer, schema module, and Entities function names. All four hardcoded callsites were replaced with registry-driven dispatch:

- `map_area.ex` — `pin_color_class/1` removed; `EntityTypes.color/1` used inline; pin layer filter uses `t.layer` from registry
- `modals.ex` — type dropdown and parent dropdown driven by `EntityTypes.list_types/0` and `EntityTypes.parent_type/1`
- `sidebar.ex` — parent fieldset driven by `EntityTypes.parent_type/1`; `parent_options/3` helper removed
- `map_live.ex` — `save_pin`, `delete_entity`, `toggle_field_edit`, `navigate_to_parent`, `load_parent`, `apply_select_pin` all use `apply(Entities, type_info.fn, args)` dispatch
- `pins.ex` — `get_entity_for_pin/1` replaced with single clause using `type_info.schema_module` + `Repo.get!/2`

Adding a new entity type now requires only one new entry in `@types` in `EntityTypes`.

---
