# Frontend Prompt Guide for Claude

How to describe UI work so Claude builds what you picture on the first pass.

---

## Why frontend needs more detail

Backend requirements are naturally precise: schemas have fields and types, APIs have inputs and outputs, business logic has clear rules. Frontend is visual and interactive — there are hundreds of valid ways to render the same feature, and without specifics, Claude will guess.

The fix is not writing more — it's writing the **right things**.

---

## The 5 things to always specify

### 1. Layout and position

Where does this element live on the screen? Relative to what?

**Vague:** "Add a world selector"
**Clear:** "Add a world selector dropdown in the left side of the navbar, before the map upload buttons"

Use spatial language: top, bottom, left, right, above, below, next to, inside, overlaying.

### 2. Component type and behavior

What kind of widget is it? What happens when you interact with it?

**Vague:** "Let the user pick a world"
**Clear:** "A dropdown that shows the current world name. Clicking it opens a list of all worlds. Clicking a world name switches to it and closes the dropdown."

Name the component type: dropdown, modal, inline input, sidebar, tab bar, toast, tooltip, popover, accordion, card grid.

### 3. States

Every UI element has multiple states. List them:

- **Empty state:** What shows when there's no data? ("No worlds yet — create one to get started")
- **Loading state:** Is there a spinner? Skeleton? Or is it instant?
- **Active/selected state:** How does the user know which item is current? (Bold text, different background, checkmark icon)
- **Error state:** What happens on failure? (Flash message, inline error, red border)
- **Disabled state:** When are buttons/actions disabled? Why?

### 4. Visual style (reference existing patterns)

Don't describe CSS — reference what already exists in the app or name a well-known pattern.

**Vague:** "Make it look nice"
**Clear:** "Same style as the map tabs — rounded-b-lg, bg-base-200, shadow-md"
**Also clear:** "Google Maps style — floating card with shadow over the map area"

If you can screenshot or describe a reference from another app, that's even better.

### 5. Interaction flow (step by step)

Walk through what the user does, click by click:

> 1. User clicks the world name in the navbar
> 2. A dropdown appears showing all worlds, with the current one highlighted
> 3. User clicks a different world
> 4. The dropdown closes, the navbar updates to show the new world name
> 5. The map area reloads with that world's maps

---

## Template for UI feature requests

Copy this and fill it in:

```
## What I want
[One sentence: what is this feature?]

## Where it goes
[Position on screen, relative to existing elements]

## How it looks
[Component type. Reference existing patterns or other apps]

## How it works (interaction flow)
1. User does X
2. Y appears/changes
3. User does Z
4. Result

## States to handle
- Default: [what it looks like normally]
- Empty: [no data]
- Selected/Active: [how current selection is shown]
- Error: [what happens on failure]

## What I don't want
[Optional but very helpful — rules out wrong guesses]
```

---

## Example: applying this to issue 5

### Bad prompt
> "Add multi-world support. User should be able to create, select, and delete worlds."

### Good prompt
> **What:** A world selector in the navbar so users can switch between multiple worlds.
>
> **Where:** In the navbar, on the far left — replace the current static world name with a dropdown.
>
> **How it looks:** A dropdown button showing the current world name with a chevron-down icon. When open, a list of world names with the active one highlighted. At the bottom of the list, a "+ New World" action. Each world row has a small trash icon on hover for deletion.
>
> **Interaction flow:**
> 1. User clicks the world name/chevron in navbar
> 2. Dropdown opens showing all worlds, current one has a checkmark or bold text
> 3. Clicking another world: dropdown closes, maps reload for that world
> 4. Clicking "+ New World": opens the existing world modal (name + description), creates the world, switches to it
> 5. Clicking the trash icon on a world: confirmation prompt "Delete X and all its maps?", then deletes
>
> **States:**
> - Single world: dropdown still works but only shows one item + "New World"
> - After deletion: switch to the next available world, or if none, create a default
>
> **Don't want:** A separate page for world management. Everything should be in the navbar dropdown.

---

## Quick tips

- **Screenshot or sketch beats 100 words.** Even a rough drawing on paper, photographed, eliminates ambiguity.
- **Name components from DaisyUI** when possible — you're already using it (dropdown, modal, btn, badge, etc.).
- **Say what you don't want.** "Not a sidebar" or "no modal for this" prevents wrong guesses.
- **Describe the happy path first**, then edge cases. Don't mix them.
- **Small sections are better.** Break a big UI change into pieces: "first do the dropdown, then the delete confirmation, then the empty state."
