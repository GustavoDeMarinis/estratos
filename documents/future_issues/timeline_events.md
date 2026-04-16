# Timeline and Time Events

## Objective

Introduce a timeline system that lets users record events affecting entities and their relationships over time. Each time event has a date (or date range) and describes a change: a city gets invaded, a river freezes, an alliance forms, a faction loses control of a territory. Events can modify entity status or create/remove relationships at a given point in time. A timeline slider or date picker lets the user view the world at any point, with the map and sidebar reflecting the state of entities and relationships as of that date.

### Examples

- "Valdoria invaded by Arkon" at year 1453 — changes Valdoria's controller from Faction A to Faction B
- "Silverstream River frozen" from year 1400 to 1420 — adds a `frozen` status to the river during that range
- "Aurelia-Valdoria alliance" at year 1200 — creates an `allied_with` relationship effective from that date
