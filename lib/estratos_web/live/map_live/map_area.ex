defmodule EstratosWeb.MapLive.MapArea do
  @moduledoc """
  Main map viewport: tabs, actions, image, pins overlay, sidebar, and zoom controls.
  """
  use EstratosWeb, :html

  alias Estratos.EntityTypes
  alias Estratos.Layers
  alias EstratosWeb.MapLive.Sidebar

  attr :uploads, :map, required: true
  attr :map, :any, required: true
  attr :maps, :list, required: true
  attr :renaming, :boolean, required: true
  attr :image_broken, :boolean, required: true
  attr :pending_image, :any, required: true
  attr :pin_mode, :boolean, required: true
  attr :pending_pin, :any, required: true
  attr :pins, :list, required: true
  attr :selected_pin, :any, required: true
  attr :sidebar_open, :boolean, required: true
  attr :field_values, :map, required: true
  attr :editing_fields, :any, required: true
  attr :moving_pin, :any, required: true
  attr :entity_lists, :map, required: true
  attr :active_layers, :any, required: true
  attr :adding_relationship, :boolean, required: true
  attr :new_relationship_target_type, :string, required: true
  attr :new_relationship_type, :string, required: true

  def map_viewport(assigns) do
    ~H"""
    <main
      id="map-container"
      phx-hook="MapContainer"
      data-map-id={if @map, do: to_string(@map.id), else: ""}
      data-move-mode={if !is_nil(@moving_pin), do: "true", else: "false"}
      class={["flex-1 overflow-hidden bg-base-300 select-none relative", if(@pin_mode || !is_nil(@moving_pin), do: "cursor-crosshair", else: "")]}
    >
      <.map_tabs maps={@maps} map={@map} renaming={@renaming} sidebar_open={@sidebar_open} />
      <.map_actions :if={@map} map={@map} renaming={@renaming} />
      <.map_image uploads={@uploads} map={@map} image_broken={@image_broken} pending_image={@pending_image} />
      <.map_pins pins={@pins} pending_pin={@pending_pin} active_layers={@active_layers} selected_pin={@selected_pin} />
      <Sidebar.sidebar
        selected_pin={@selected_pin}
        sidebar_open={@sidebar_open}
        field_values={@field_values}
        editing_fields={@editing_fields}
        moving_pin={@moving_pin}
        entity_lists={@entity_lists}
        adding_relationship={@adding_relationship}
        new_relationship_target_type={@new_relationship_target_type}
        new_relationship_type={@new_relationship_type}
      />
      <.zoom_controls />
    </main>
    """
  end

  attr :maps, :list, required: true
  attr :map, :any, required: true
  attr :renaming, :boolean, required: true
  attr :sidebar_open, :boolean, required: true

  defp map_tabs(assigns) do
    ~H"""
    <div class={["absolute top-0 flex gap-1 px-2 z-10 transition-all duration-300", if(@sidebar_open, do: "left-[255px]", else: "left-0")]}>
      <%= for m <- @maps do %>
        <button
          type="button"
          phx-click="select_map"
          phx-value-id={m.id}
          class={[
            "px-3 pb-1.5 pt-1 bg-base-200 rounded-b-lg text-sm shadow-md transition-all",
            if(@map && @map.id == m.id,
              do: "pb-2 text-base-content",
              else: "text-base-content/60 hover:text-base-content"
            )
          ]}
        >
          <span class="truncate max-w-[10rem]"><%= m.name %></span>
        </button>
      <% end %>
      <button
        type="button"
        phx-click="new_map"
        class={[
          "flex items-center gap-1 px-3 rounded-b-lg text-sm bg-base-200 shadow-md transition-all",
          if(@map == nil,
            do: "pb-2 pt-1 text-base-content",
            else: "pb-1.5 pt-1 text-base-content/60 hover:text-base-content"
          )
        ]}
      >
        <.icon name="hero-plus-micro" class="w-3.5 h-3.5" />
        <span>New Map</span>
      </button>
    </div>
    """
  end

  attr :map, :map, required: true
  attr :renaming, :boolean, required: true

  defp map_actions(assigns) do
    ~H"""
    <div class="absolute bottom-4 left-4 z-10 flex gap-1">
      <%= if @renaming do %>
        <form id="rename-form" phx-submit="rename_map" class="flex items-center gap-1">
          <input
            type="text"
            name="name"
            value={@map.name}
            class="input input-sm bg-base-200 w-48"
            autofocus
          />
          <button type="submit" class="btn btn-sm btn-primary">Save</button>
          <button type="button" phx-click="cancel_rename" class="btn btn-sm">Cancel</button>
        </form>
      <% else %>
        <button
          type="button"
          phx-click="start_rename"
          class="btn btn-sm bg-base-200 border-base-content/20 hover:bg-base-100 shadow-xl"
          title="Rename map"
        >
          <.icon name="hero-pencil-square-micro" class="w-4 h-4" />
          Rename
        </button>
        <button
          type="button"
          phx-click="delete_map"
          phx-confirm={"Delete \"#{@map.name}\"? This cannot be undone."}
          class="btn btn-sm bg-base-200 border-base-content/20 hover:bg-error hover:text-error-content shadow-xl"
          title="Delete map"
        >
          <.icon name="hero-trash-micro" class="w-4 h-4" />
          Delete
        </button>
      <% end %>
    </div>
    """
  end

  attr :uploads, :map, required: true
  attr :map, :any, required: true
  attr :image_broken, :boolean, required: true
  attr :pending_image, :any, required: true

  defp map_image(assigns) do
    ~H"""
    <%= if entry = List.last(@uploads.map_image.entries) do %>
      <.live_img_preview
        entry={entry}
        class="w-full h-full object-contain"
        phx-hook=".MapImage"
        id={"map-preview-#{entry.ref}"}
        draggable="false"
      />
    <% else %>
      <%= if @pending_image do %>
        <img
          src={@pending_image}
          class="w-full h-full object-contain"
          id="map-pending-image"
          draggable="false"
          phx-hook=".MapImage"
        />
      <% else %>
        <%= if @map do %>
          <%= if @image_broken do %>
            <div class="flex flex-col items-center justify-center h-full gap-2">
              <.icon name="hero-exclamation-triangle" class="w-8 h-8 text-warning" />
              <p class="text-base-content text-sm font-medium">Map image not found</p>
              <p class="text-base-content/40 text-sm"><%= @map.name %></p>
            </div>
          <% else %>
            <img
              src={@map.image_path}
              class="w-full h-full object-contain"
              id="map-image"
              draggable="false"
              phx-hook=".MapImage"
            />
          <% end %>
        <% else %>
          <div class="flex items-center justify-center h-full">
            <p class="text-base-content/40 text-sm">Upload a map image to get started</p>
          </div>
        <% end %>
      <% end %>
    <% end %>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".MapImage">
      export default {
        mounted() {
          this.el.addEventListener("load", () => {
            this.pushEvent("image_dimensions", {
              width: this.el.naturalWidth,
              height: this.el.naturalHeight
            })
          })

          this.el.addEventListener("error", () => {
            this.pushEvent("image_error", {})
          })

          if (this.el.complete && this.el.naturalWidth > 0) {
            this.pushEvent("image_dimensions", {
              width: this.el.naturalWidth,
              height: this.el.naturalHeight
            })
          }
        }
      }
    </script>
    """
  end

  attr :pins, :list, required: true
  attr :pending_pin, :any, required: true
  attr :active_layers, :any, required: true
  attr :selected_pin, :any, required: true

  defp map_pins(assigns) do
    ~H"""
    <div data-pins-overlay class="absolute inset-0 pointer-events-none">
      <div
        :if={@pending_pin}
        data-pending-pin
        data-pin-x={@pending_pin.x}
        data-pin-y={@pending_pin.y}
        class="absolute pointer-events-none opacity-60"
        style="transform: translate(-50%, -100%)"
      >
        <.icon name="hero-map-pin-solid" class="w-7 h-7 text-primary drop-shadow" />
      </div>
      <div
        :for={%{pin: pin, entity: entity} <- Enum.filter(@pins, fn %{pin: p} ->
          case EntityTypes.get_type(p.entity_type) do
            nil -> false
            t -> MapSet.member?(@active_layers, t.layer)
          end
        end)}
        data-pin
        data-pin-x={pin.x}
        data-pin-y={pin.y}
        phx-click="select_pin"
        phx-value-id={pin.id}
        class="absolute pointer-events-auto group cursor-pointer"
        style="transform: translate(-50%, -100%)"
      >
        <%!-- Fixed-size wrapper keeps the anchor point stable regardless of selection state --%>
        <div class="relative w-7 h-7">
          <%!-- Selection indicator: ghost icon scaled up behind the real one.
               absolute + inset-0 means it never affects layout; scale-[1.5] + opacity
               gives a halo effect without moving the pin tip. --%>
          <.icon
            :if={@selected_pin && @selected_pin.pin.id == pin.id}
            name="hero-map-pin-solid"
            class={"absolute inset-0 w-7 h-7 scale-[1.5] opacity-30 #{EntityTypes.color(pin.entity_type)}"}
          />
          <.icon
            name="hero-map-pin-solid"
            class={"w-7 h-7 drop-shadow #{EntityTypes.color(pin.entity_type)}"}
          />
        </div>
        <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 hidden group-hover:block pointer-events-none z-10">
          <div class="bg-base-100 border border-base-content/20 rounded-lg shadow-lg px-2 py-1.5 text-center whitespace-nowrap">
            <p class="text-xs font-bold"><%= entity.display_name || entity.name %></p>
            <p class="text-xs opacity-60 capitalize"><%= pin.entity_type %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp zoom_controls(assigns) do
    ~H"""
    <div class="absolute bottom-4 right-4 z-10 flex flex-col shadow-xl">
      <button
        id="zoom-in-btn"
        type="button"
        class="w-9 h-9 flex items-center justify-center bg-base-200 hover:bg-base-100 text-base-content border border-base-content/20 rounded-t-lg disabled:opacity-30 disabled:cursor-not-allowed"
        phx-click={JS.dispatch("map:zoom-in", to: "#map-container")}
      >
        <.icon name="hero-plus-micro" />
      </button>
      <button
        id="zoom-out-btn"
        type="button"
        class="w-9 h-9 flex items-center justify-center bg-base-200 hover:bg-base-100 text-base-content border-x border-b border-base-content/20 disabled:opacity-30 disabled:cursor-not-allowed"
        phx-click={JS.dispatch("map:zoom-out", to: "#map-container")}
      >
        <.icon name="hero-minus-micro" />
      </button>
      <button
        id="reset-view-btn"
        type="button"
        class="w-9 h-9 flex items-center justify-center bg-base-200 hover:bg-base-100 text-base-content border-x border-b border-base-content/20 rounded-b-lg disabled:opacity-30 disabled:cursor-not-allowed"
        phx-click={JS.dispatch("map:reset-view", to: "#map-container")}
      >
        <.icon name="hero-arrows-pointing-in-micro" />
      </button>
    </div>
    """
  end
end
