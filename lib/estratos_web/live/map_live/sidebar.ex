defmodule EstratosWeb.MapLive.Sidebar do
  @moduledoc """
  Left-side sidebar panel: selected-pin detail view with editable entity fields.
  """
  use EstratosWeb, :html

  alias Estratos.EntityTypes

  attr :selected_pin, :any, required: true
  attr :sidebar_open, :boolean, required: true
  attr :field_values, :map, required: true
  attr :editing_fields, :any, required: true
  attr :moving_pin, :any, required: true
  attr :entity_lists, :map, required: true
  attr :adding_relationship, :boolean, required: true
  attr :new_relationship_target_type, :string, required: true
  attr :new_relationship_type, :string, required: true

  def sidebar(assigns) do
    ~H"""
    <div data-sidebar class="absolute left-0 top-0 h-full z-20 flex items-stretch">
      <%!-- Content panel — width transitions between 0 and 255px --%>
      <div class={[
        "overflow-hidden transition-all duration-300 bg-base-200 border-r border-base-content/10 flex flex-col",
        if(@sidebar_open, do: "w-[255px]", else: "w-0")
      ]}>
        <div class="w-[255px] h-full flex flex-col">
          <%!-- Header with entity type --%>
          <%= if @selected_pin do %>
            <div class="px-4 py-2 border-b border-base-content/10 text-xs uppercase tracking-wide text-base-content/40 shrink-0">
              <%= @selected_pin.pin.entity_type %>
            </div>
          <% end %>

          <%!-- Scrollable fields area --%>
          <div class="flex-1 overflow-y-auto p-4">
            <%= if @selected_pin do %>
              <.entity_form
                selected_pin={@selected_pin}
                field_values={@field_values}
                editing_fields={@editing_fields}
                entity_lists={@entity_lists}
              />
              <.relationships_section
                selected_pin={@selected_pin}
                adding_relationship={@adding_relationship}
                new_relationship_target_type={@new_relationship_target_type}
                new_relationship_type={@new_relationship_type}
                entity_lists={@entity_lists}
              />
            <% end %>
          </div>

          <%!-- Bottom actions --%>
          <.sidebar_actions :if={@selected_pin} selected_pin={@selected_pin} moving_pin={@moving_pin} />
        </div>
      </div>

      <%!-- Toggle button — sticks out to the right of the panel --%>
      <button
        type="button"
        phx-click="toggle_sidebar"
        disabled={is_nil(@selected_pin)}
        class="group self-center min-w-[25px] h-[80px] bg-base-200 rounded-r-lg shadow-md border border-l-0 border-base-content/10 flex items-center overflow-hidden transition-all duration-200 disabled:opacity-30 disabled:cursor-not-allowed"
      >
        <span class="w-[25px] flex items-center justify-center shrink-0">
          <.icon
            name={if @sidebar_open, do: "hero-chevron-left-micro", else: "hero-chevron-right-micro"}
            class="w-4 h-4"
          />
        </span>
        <%!-- Hover preview — only shown when a pin is selected and sidebar is collapsed --%>
        <%!-- Delay 300ms to avoid showing while sidebar transition is in progress --%>
        <%= if @selected_pin && !@sidebar_open do %>
          <span class="reveal-after-transition max-w-0 group-hover:max-w-[150px] overflow-hidden transition-all duration-200 group-hover:pr-2 text-left whitespace-nowrap">
            <span class="text-xs font-bold leading-tight block"><%= @selected_pin.entity.display_name || @selected_pin.entity.name %></span>
            <span class="text-xs opacity-60 leading-tight capitalize block"><%= @selected_pin.pin.entity_type %></span>
          </span>
        <% end %>
      </button>
    </div>
    """
  end

  attr :selected_pin, :map, required: true
  attr :moving_pin, :any, required: true

  defp sidebar_actions(assigns) do
    ~H"""
    <div class="border-t border-base-content/10 p-2 bg-base-200 flex gap-2 shrink-0">
      <button
        type="button"
        phx-click="start_move_pin"
        disabled={!is_nil(@moving_pin)}
        class="btn btn-outline btn-sm flex-1"
      >
        <.icon name="hero-arrows-pointing-out-micro" class="w-4 h-4" />
        Move
      </button>
      <button
        type="button"
        phx-click="delete_entity"
        phx-confirm={"Delete this #{@selected_pin.pin.entity_type} and its pin? This cannot be undone."}
        class="btn btn-error btn-outline btn-sm flex-1"
      >
        <.icon name="hero-trash-micro" class="w-4 h-4" />
        Delete
      </button>
    </div>
    """
  end

  attr :selected_pin, :map, required: true
  attr :field_values, :map, required: true
  attr :editing_fields, :any, required: true
  attr :entity_lists, :map, required: true

  defp entity_form(assigns) do
    ~H"""
    <form phx-change="sync_field_value" class="flex flex-col gap-3">
      <%!-- Name field --%>
      <fieldset class="flex flex-col gap-1">
        <legend class="text-[10px] uppercase tracking-wide text-base-content/40">Name</legend>
        <div class="flex items-center gap-2">
          <input
            type="text"
            name="name"
            value={@field_values["name"]}
            class="input input-sm input-bordered w-full flex-1"
            disabled={!MapSet.member?(@editing_fields, "name") and @field_values["name"] != ""}
          />
          <button
            type="button"
            phx-click="toggle_field_edit"
            phx-value-field="name"
            class="btn btn-ghost btn-xs"
          >
            <.icon name="hero-pencil-square-micro" class="w-4 h-4" />
          </button>
        </div>
      </fieldset>

      <%!-- Display Name field --%>
      <fieldset class="flex flex-col gap-1">
        <legend class="text-[10px] uppercase tracking-wide text-base-content/40">Display Name</legend>
        <div class="flex items-center gap-2">
          <input
            type="text"
            name="display_name"
            value={@field_values["display_name"]}
            class="input input-sm input-bordered w-full flex-1"
            disabled={!MapSet.member?(@editing_fields, "display_name") and @field_values["display_name"] != ""}
          />
          <button
            type="button"
            phx-click="toggle_field_edit"
            phx-value-field="display_name"
            class="btn btn-ghost btn-xs"
          >
            <.icon name="hero-pencil-square-micro" class="w-4 h-4" />
          </button>
        </div>
      </fieldset>

      <%!-- Description field --%>
      <fieldset class="flex flex-col gap-1">
        <legend class="text-[10px] uppercase tracking-wide text-base-content/40">Description</legend>
        <div class="flex items-start gap-2">
          <textarea
            name="description"
            rows="2"
            class="textarea textarea-sm textarea-bordered w-full flex-1 !resize-none"
            disabled={!MapSet.member?(@editing_fields, "description") and @field_values["description"] != ""}
          ><%= @field_values["description"] %></textarea>
          <button
            type="button"
            phx-click="toggle_field_edit"
            phx-value-field="description"
            class="btn btn-ghost btn-xs mt-1"
          >
            <.icon name="hero-pencil-square-micro" class="w-4 h-4" />
          </button>
        </div>
      </fieldset>

      <%!-- Parent field — rendered generically for any type that has a parent --%>
      <% parent_type = EntityTypes.parent_type(@selected_pin.pin.entity_type) %>
      <%= if parent_type do %>
        <fieldset class="flex flex-col gap-1">
          <legend class="text-[10px] uppercase tracking-wide text-base-content/40">
            <%= EntityTypes.name(parent_type) %>
          </legend>
          <div class="flex items-center gap-2">
            <%= if MapSet.member?(@editing_fields, "parent") do %>
              <select name="parent_id" class="select select-sm select-bordered w-full flex-1">
                <option value="">None</option>
                <%= for p <- Map.get(@entity_lists, parent_type, []) do %>
                  <option value={p.id} selected={to_string(p.id) == @field_values["parent_id"]}>
                    <%= p.display_name || p.name %>
                  </option>
                <% end %>
              </select>
            <% else %>
              <%= if @selected_pin.parent do %>
                <button
                  type="button"
                  phx-click="navigate_to_parent"
                  class="text-sm text-primary hover:underline text-left flex-1 truncate"
                >
                  <%= @selected_pin.parent.display_name || @selected_pin.parent.name %>
                </button>
              <% else %>
                <span class="text-sm text-base-content/40 flex-1">None</span>
              <% end %>
            <% end %>
            <button
              type="button"
              phx-click="toggle_field_edit"
              phx-value-field="parent"
              class="btn btn-ghost btn-xs shrink-0"
            >
              <.icon
                name={if MapSet.member?(@editing_fields, "parent"), do: "hero-check-micro", else: "hero-pencil-square-micro"}
                class="w-4 h-4"
              />
            </button>
          </div>
        </fieldset>
      <% end %>

      <%!-- Position field (read-only) --%>
      <fieldset class="flex flex-col gap-1">
        <legend class="text-[10px] uppercase tracking-wide text-base-content/40">Position</legend>
        <p class="text-sm text-base-content/70">
          <%= Float.round(@selected_pin.pin.x * 100, 1) %>%, <%= Float.round(@selected_pin.pin.y * 100, 1) %>%
        </p>
      </fieldset>
    </form>
    """
  end

  attr :selected_pin, :map, required: true
  attr :adding_relationship, :boolean, required: true
  attr :new_relationship_target_type, :string, required: true
  attr :new_relationship_type, :string, required: true
  attr :entity_lists, :map, required: true

  defp relationships_section(assigns) do
    ~H"""
    <div class="border-t border-base-content/10 mt-3 pt-3 flex flex-col gap-1">
      <%!-- Section header --%>
      <div class="flex items-center justify-between mb-1">
        <span class="text-[10px] uppercase tracking-wide text-base-content/40">Relationships</span>
        <button
          :if={!@adding_relationship}
          type="button"
          phx-click="toggle_add_relationship"
          class="btn btn-ghost btn-xs"
          title="Add relationship"
        >
          <.icon name="hero-plus-micro" class="w-3 h-3" />
        </button>
      </div>

      <%!-- Relationship list --%>
      <%= for entry <- @selected_pin.relationships do %>
        <div class="flex items-center gap-1 py-0.5 min-w-0">
          <span class="text-base-content/40 text-xs shrink-0 font-mono">
            <%= if entry.direction == :source, do: "→", else: "←" %>
          </span>
          <span class="text-[10px] text-base-content/50 shrink-0 italic truncate max-w-[55px]" title={entry.relationship.type}>
            <%= entry.relationship.type %>
          </span>
          <button
            type="button"
            phx-click="navigate_to_relationship_target"
            phx-value-id={entry.relationship.id}
            class="text-xs text-primary hover:underline flex-1 text-left truncate"
          >
            <%= entry.other_entity.display_name || entry.other_entity.name %>
          </button>
          <button
            type="button"
            phx-click="delete_relationship"
            phx-value-id={entry.relationship.id}
            phx-confirm="Remove this relationship?"
            class="btn btn-ghost btn-xs shrink-0 text-error opacity-50 hover:opacity-100 p-0 min-h-0 h-auto"
            title="Remove relationship"
          >
            <.icon name="hero-x-mark-micro" class="w-3 h-3" />
          </button>
        </div>
      <% end %>

      <%= if Enum.empty?(@selected_pin.relationships) and not @adding_relationship do %>
        <p class="text-xs text-base-content/30 italic">None</p>
      <% end %>

      <%!-- Inline add form --%>
      <form
        :if={@adding_relationship}
        phx-submit="add_relationship"
        phx-change="relationship_form_changed"
        class="flex flex-col gap-1.5 mt-1"
      >
        <input
          type="text"
          name="type"
          value={@new_relationship_type}
          placeholder="e.g. contains, allied_with…"
          list="relationship-type-suggestions"
          class="input input-xs input-bordered w-full"
          required
          autofocus
        />
        <datalist id="relationship-type-suggestions">
          <option value="contains" />
          <option value="allied_with" />
          <option value="at_war_with" />
          <option value="trades_with" />
          <option value="borders" />
          <option value="controls" />
        </datalist>
        <select name="target_type" class="select select-xs select-bordered w-full" required>
          <%= for t <- EntityTypes.list_types() do %>
            <option value={t.slug} selected={@new_relationship_target_type == t.slug}>
              <%= t.name %>
            </option>
          <% end %>
        </select>
        <select name="target_id" class="select select-xs select-bordered w-full" required>
          <option value="">Select entity…</option>
          <%= for e <- Map.get(@entity_lists, @new_relationship_target_type, []) do %>
            <option value={e.id}><%= e.display_name || e.name %></option>
          <% end %>
        </select>
        <div class="flex gap-1">
          <button type="submit" class="btn btn-primary btn-xs flex-1">Add</button>
          <button type="button" phx-click="cancel_add_relationship" class="btn btn-ghost btn-xs flex-1">
            Cancel
          </button>
        </div>
      </form>
    </div>
    """
  end
end
