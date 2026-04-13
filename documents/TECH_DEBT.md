# Technical Debt Tracker

A living document of known issues, inefficiencies, and refactoring opportunities. These are intentionally deferred to maintain velocity but should be addressed when the codebase reaches critical mass or when blocks future work.

---

## Backlog

### Entity Type Registry (Hardcoded Dropdowns)

**Status:** Deferred after Issue 7 Section 3

**Location:** 
- `lib/estratos_web/live/map_live/modals.ex` (pin_create_modal dropdown, lines 104-107)
- `lib/estratos_web/live/map_live/map_area.ex` (pin_color_class, lines 249-253)
- `lib/estratos_web/live/map_live.ex` (save_pin case statement, lines 533-538; delete_entity case statement, lines 717-721)

**Problem:**
Entity types are currently hardcoded in multiple places. With only 4 types (Continent, Ocean, Country, City) this is manageable, but will become unmaintainable at 6+ types. Every new entity type requires updates to:
1. Modal dropdown
2. Pin color function
3. save_pin/delete_entity pattern matches
4. Pins.get_entity_for_pin/1

**Solution:**
Create `Estratos.EntityTypes` module with:
```elixir
@entity_types [
  %{slug: "continent", name: "Continent", color: "text-green-500"},
  %{slug: "ocean", name: "Ocean", color: "text-blue-500"},
  %{slug: "country", name: "Country", color: "text-amber-500"},
  %{slug: "city", name: "City", color: "text-rose-400"}
]

def list_types/0
def get_type/1
def get_color/1
def name/1
```

Then replace hardcoded cases with dynamic dispatch (e.g., `apply(Entities, String.to_atom("create_#{type}"), [world, attrs])`).

**Trigger:** When adding 5th or 6th entity type, or if you find yourself making the same edit to 3+ files.

---

## Future Improvements (Post-MVP)

*Placeholder for structural improvements that require schema changes or major refactors.*

---

## Done / Closed

*Items that have been resolved, moved to production, or deemed unnecessary.*

---
