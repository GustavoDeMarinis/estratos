# Issue 3 — Map Viewer: Pan, Zoom and Broken Image Handling

## Objective

Improve the map viewing experience with two focused enhancements: (1) make the map an interactive canvas with pan and zoom, so users can navigate large or detailed maps; (2) detect and gracefully handle broken/missing map images instead of showing a browser-default broken image icon.

---

## Constraints

- Pan & zoom is purely client-side (CSS transforms) — no server-side image processing
- The saved map record is not modified by pan/zoom — these are view-only interactions
- Broken image detection applies to saved maps only (upload previews are ephemeral and handled by the browser)

---

## Section 1 — Pan & Zoom Hook [sonnet]

- [x] Create a colocated `.MapContainer` JS hook on the map's container element
- [x] Implement zoom via mouse wheel:
  - Scale the image using CSS `transform: scale()`
  - Zoom toward the cursor position (not the center)
  - Minimum zoom: fit-to-container (1x, the current default behavior)
  - Maximum zoom: 10x
  - Smooth step increments (e.g., 1.1x per wheel tick)
- [x] Implement pan via click-and-drag:
  - On mousedown + mousemove, translate the image using CSS `transform: translate()`
  - Only allow panning when zoomed in (at 1x the image is already fully visible)
  - Cursor changes to `grab` when hoverable, `grabbing` while dragging
- [x] Combine scale and translate in a single `transform` property to avoid conflicts
- [x] Add zoom control buttons in the bottom-right corner (Google Maps style):
  - A stacked group of 3 buttons: `+` (zoom in), `-` (zoom out), fit icon (reset view)
  - Connected appearance: no gap, rounded container, border, shadow
  - `+` button is disabled when at maximum zoom (10x)
  - `-` and reset buttons are disabled when at minimum zoom (1x)
  - Button zoom steps by 1.5x from container center (vs cursor-based scroll zoom)
  - Clicking buttons does not trigger pan (blocked via `e.target.closest("button")` check)
- [x] Ensure pan & zoom works on both the saved map image and the upload preview

> The hook manages all state (scale, translateX, translateY) in JS. No server roundtrips needed for viewport changes.

---

## Section 2 — Broken Image Detection [sonnet]

- [x] Add a server-side check: when mounting MapLive, if a map exists in the DB, verify the image file exists on disk via `File.exists?/1`
- [x] If the file is missing, assign an `:image_broken` flag in the socket
- [x] Render a broken-image state instead of the `<img>` tag:
  - Centered in the main area (same position as the "Upload a map" empty state)
  - Show a warning icon and the message: "Map image not found"
  - Show a secondary line with the map name, so the user knows which map is affected
  - The "Upload" button remains functional so the user can re-upload
- [x] Add a client-side fallback: attach an `error` event listener on the `<img>` tag via the hook, so if the file exists at mount time but fails to load (e.g., corrupted file), push an event to the server to set the broken state
- [x] Handle the `image_error` event on the server: set `:image_broken` to true and show an error flash

---

## Section 3 — Smoke Test [sonnet]

- [ ] `make up` → app boots, map loads at `localhost:4000`
- [ ] Scroll wheel on the map → image zooms in/out smoothly, centered on cursor
- [ ] Click and drag while zoomed in → image pans
- [ ] "Reset view" button appears when zoomed → click it → view returns to fit
- [ ] Pan is not possible when at 1x zoom (no dragging the image off-screen)
- [ ] Upload a new image while zoomed → zoom resets, new preview shows at 1x
- [ ] Manually rename/delete the image file in `priv/static/uploads/maps/` → refresh the page → broken image state renders with warning message
- [ ] Re-upload an image while in broken state → image renders normally

---

## Out of Scope

- Touch/pinch gestures for mobile
- Minimap or zoom indicator
- Persisting viewport position across reloads
- Keyboard shortcuts for zoom/pan
- Map image re-processing or repair

---

## Done When

- The user can zoom into the map with the scroll wheel and pan by dragging
- Zoom is bounded (1x to 10x) and centers on the cursor position
- A reset button appears when zoomed in and restores the default view
- If a saved map's image file is missing or fails to load, the user sees a clear "Map image not found" message instead of a broken image
- The upload flow works correctly from any state (normal, zoomed, broken)
