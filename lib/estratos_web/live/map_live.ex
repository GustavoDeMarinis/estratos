defmodule EstratosWeb.MapLive do
  use EstratosWeb, :live_view

  alias Estratos.Worlds
  alias Estratos.MapStorage
  alias Estratos.Entities
  alias Estratos.Pins

  @impl true
  def mount(_params, _session, socket) do
    world = Worlds.get_or_create_default_world()
    worlds = Worlds.list_worlds()
    maps = Worlds.list_maps_for_world(world)
    map = List.first(maps)

    socket =
      socket
      |> assign(:world, world)
      |> assign(:worlds, worlds)
      |> assign(:maps, maps)
      |> assign(:map, map)
      |> assign(:image_broken, image_broken?(map))
      |> assign(:image_dimensions, nil)
      |> assign(:renaming, false)
      |> assign(:world_modal, nil)
      |> assign(:editing_world, nil)
      |> assign(:naming_new_map, nil)
      |> assign(:pending_image, nil)
      |> assign(:pin_mode, false)
      |> assign(:pending_pin, nil)
      |> assign(:pins, [])
      |> assign(:selected_pin, nil)
      |> assign(:sidebar_open, false)
      |> assign(:field_values, %{})
      |> assign(:editing_fields, MapSet.new())
      |> assign(:moving_pin, nil)
      |> assign(:confirm_move, nil)
      |> load_pins()
      # max_entries: 2 allows selecting a replacement image while keeping the
      # current preview — validate cancels the older entry once the new one arrives.
      |> allow_upload(:map_image,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 2,
        max_file_size: 50_000_000
      )

    {:ok, socket}
  end

  # ---------------------------------------------------------------------------
  # Render
  # ---------------------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <.navbar world={@world} worlds={@worlds} uploads={@uploads} pending_image={@pending_image} pin_mode={@pin_mode} />
      <.map_viewport uploads={@uploads} map={@map} maps={@maps} renaming={@renaming} image_broken={@image_broken} pending_image={@pending_image} pin_mode={@pin_mode} pending_pin={@pending_pin} pins={@pins} selected_pin={@selected_pin} sidebar_open={@sidebar_open} field_values={@field_values} editing_fields={@editing_fields} />
      <Layouts.flash_group flash={@flash} />
      <.world_modal :if={@world_modal} world={@editing_world || @world} mode={@world_modal} />
      <.name_map_modal :if={@naming_new_map} />
      <.pin_create_modal :if={@pending_pin} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Components
  # ---------------------------------------------------------------------------

  defp navbar(assigns) do
    ~H"""
    <header class="navbar bg-base-200 px-4 shrink-0 gap-3 min-h-0 h-12">
      <div class="flex-1 flex items-center gap-2">
        <div class="dropdown" id="world-dropdown" phx-hook=".WorldDropdown">
          <button
            tabindex="0"
            type="button"
            class="btn btn-sm btn-ghost gap-1 font-semibold tracking-wide"
          >
            <span class="max-w-[12rem] truncate"><%= @world.name %></span>
            <.icon name="hero-chevron-down-micro" class="w-3.5 h-3.5 opacity-60 shrink-0" />
          </button>
          <ul
            tabindex="0"
            class="dropdown-content menu bg-base-100 border border-base-content/10 rounded-box shadow-lg z-20 w-56 mt-1 max-h-72 overflow-y-auto flex-nowrap p-1"
          >
            <%= for w <- @worlds do %>
              <li>
                <div class="flex flex-row items-center gap-1">
                  <button
                    type="button"
                    phx-click="select_world"
                    phx-value-id={w.id}
                    class={["flex items-center gap-2 flex-1 text-left rounded px-2 py-1.5 hover:bg-base-content/10", if(@world.id == w.id, do: "font-semibold", else: "")]}
                  >
                    <.icon
                      :if={@world.id == w.id}
                      name="hero-check-micro"
                      class="w-3.5 h-3.5 shrink-0 text-primary"
                    />
                    <span :if={@world.id != w.id} class="w-3.5 shrink-0" />
                    <span class="truncate"><%= w.name %></span>
                  </button>
                  <button
                    type="button"
                    phx-click="start_rename_world_id"
                    phx-value-id={w.id}
                    class="p-1.5 shrink-0 text-base-content/40 hover:text-primary rounded transition-colors"
                    title="Edit world"
                  >
                    <.icon name="hero-pencil-square-micro" class="w-3.5 h-3.5" />
                  </button>
                </div>
              </li>
            <% end %>
            <li><div class="divider my-0.5"></div></li>
            <li>
              <button
                type="button"
                phx-click="new_world"
                class="flex items-center gap-2 w-full text-left rounded"
              >
                <.icon name="hero-plus-micro" class="w-3.5 h-3.5 shrink-0" />
                <span>New World</span>
              </button>
            </li>
          </ul>
          <script :type={Phoenix.LiveView.ColocatedHook} name=".WorldDropdown">
            export default {
              mounted() {
                this.closeOnOutsideClick = (e) => {
                  if (!this.el.contains(e.target)) {
                    this.el.removeAttribute("open")
                    const btn = this.el.querySelector("[tabindex='0']")
                    if (btn) btn.blur()
                  }
                }
                this.closeOnSelect = (e) => {
                  if (e.target.closest("[phx-click]")) {
                    this.el.removeAttribute("open")
                    const btn = this.el.querySelector("[tabindex='0']")
                    if (btn) btn.blur()
                  }
                }
                document.addEventListener("click", this.closeOnOutsideClick)
                this.el.addEventListener("click", this.closeOnSelect)
              },
              destroyed() {
                document.removeEventListener("click", this.closeOnOutsideClick)
              }
            }
          </script>
        </div>
      </div>
      <button
        type="button"
        phx-click="toggle_pin_mode"
        class={["btn btn-sm", if(@pin_mode, do: "btn-primary", else: "btn-ghost")]}
        title={if(@pin_mode, do: "Exit pin mode", else: "Place a pin")}
      >
        <.icon name="hero-map-pin-solid" class="w-4 h-4" />
      </button>
      <form phx-change="validate" phx-submit="save" class="flex gap-2" id="upload-form" phx-hook=".UploadForm">
        <button
          type="button"
          class="btn btn-sm btn-outline cursor-pointer"
          phx-click="reupload"
        >
          Upload
        </button>
        <.live_file_input upload={@uploads.map_image} class="hidden" />
        <button
          type="submit"
          class="btn btn-sm btn-primary"
          disabled={@uploads.map_image.entries == [] and is_nil(@pending_image)}
        >
          Save
        </button>
      </form>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".UploadForm">
        export default {
          mounted() {
            this.handleEvent("trigger-upload", ({ id }) => {
              const inp = document.getElementById(id)
              if (inp) {
                inp.disabled = false
                inp.value = ""
                inp.click()
              }
            })
          }
        }
      </script>
    </header>
    """
  end

  defp map_tabs(assigns) do
    ~H"""
    <div class="absolute top-0 left-0 flex gap-1 px-2 z-10">
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

  defp world_modal(%{mode: :new} = assigns) do
    ~H"""
    <div class="modal modal-open modal-middle">
      <div class="modal-box max-w-sm">
        <h3 class="font-bold text-lg">New World</h3>
        <form phx-submit="create_world" class="flex flex-col gap-4 mt-4">
          <label class="form-control w-full">
            <div class="label"><span class="label-text text-[13px]">Name</span></div>
            <input
              type="text"
              name="name"
              value=""
              placeholder="My World"
              class="input input-bordered w-full"
              autofocus
              required
            />
          </label>
          <label class="form-control w-full">
            <div class="label"><span class="label-text text-[13px]">Description</span></div>
            <textarea
              name="description"
              class="textarea textarea-bordered w-full"
              rows="3"
              placeholder="A brief description of your world"
            ></textarea>
          </label>
          <div class="modal-action">
            <button type="button" phx-click="cancel_rename_world" class="btn">Cancel</button>
            <button type="submit" class="btn btn-primary">Create</button>
          </div>
        </form>
      </div>
      <div class="modal-backdrop" phx-click="cancel_rename_world"></div>
    </div>
    """
  end

  defp world_modal(%{mode: :edit} = assigns) do
    ~H"""
    <div class="modal modal-open modal-middle">
      <div class="modal-box max-w-sm">
        <h3 class="font-bold text-lg">Edit World</h3>
        <form phx-submit="rename_world" class="flex flex-col gap-4 mt-4">
          <label class="form-control w-full">
            <div class="label"><span class="label-text text-[13px]">Name</span></div>
            <input
              type="text"
              name="name"
              value={@world.name}
              class="input input-bordered w-full"
              autofocus
              required
            />
          </label>
          <label class="form-control w-full">
            <div class="label"><span class="label-text text-[13px]">Description</span></div>
            <textarea
              name="description"
              class="textarea textarea-bordered w-full"
              rows="3"
              placeholder="A brief description of your world"
            ><%= @world.description %></textarea>
          </label>
          <div class="modal-action justify-between">
            <button
              type="button"
              phx-click="delete_world"
              phx-value-id={@world.id}
              phx-confirm={"Delete \"#{@world.name}\" and all its maps? This cannot be undone."}
              class="btn btn-error btn-outline"
            >
              Delete World
            </button>
            <div class="flex gap-2">
              <button type="button" phx-click="cancel_rename_world" class="btn">Cancel</button>
              <button type="submit" class="btn btn-primary">Save</button>
            </div>
          </div>
        </form>
      </div>
      <div class="modal-backdrop" phx-click="cancel_rename_world"></div>
    </div>
    """
  end

  defp pin_create_modal(assigns) do
    ~H"""
    <div class="modal modal-open modal-middle">
      <div class="modal-box max-w-sm">
        <h3 class="font-bold text-lg">New Pin</h3>
        <form phx-submit="save_pin" phx-change="pin_type_changed" class="flex flex-col gap-4 mt-4" id="pin-create-form">
          <label class="form-control w-full">
            <div class="label"><span class="label-text text-[13px]">Type</span></div>
            <select name="pin_type" class="select select-bordered w-full" required>
              <option value="continent">Continent</option>
              <option value="ocean">Ocean</option>
            </select>
          </label>
          <label class="form-control w-full">
            <div class="label"><span class="label-text text-[13px]">Name <span class="text-error">*</span></span></div>
            <input
              type="text"
              name="name"
              class="input input-bordered w-full"
              placeholder="Required"
              autofocus
              required
            />
          </label>
          <label class="form-control w-full">
            <div class="label"><span class="label-text text-[13px]">Display Name</span></div>
            <input
              type="text"
              name="display_name"
              class="input input-bordered w-full"
              placeholder="Optional label"
            />
          </label>
          <label class="form-control w-full">
            <div class="label"><span class="label-text text-[13px]">Description</span></div>
            <textarea
              name="description"
              class="textarea textarea-bordered w-full"
              rows="2"
              placeholder="Optional"
            ></textarea>
          </label>
          <div class="modal-action">
            <button type="button" phx-click="cancel_pin" class="btn">Cancel</button>
            <button type="submit" class="btn btn-primary">Save Pin</button>
          </div>
        </form>
      </div>
      <div class="modal-backdrop" phx-click="cancel_pin"></div>
    </div>
    """
  end

  defp name_map_modal(assigns) do
    ~H"""
    <div class="modal modal-open modal-middle">
      <div class="modal-box max-w-sm">
        <h3 class="font-bold text-lg">Name your map</h3>
        <form phx-submit="confirm_new_map" class="flex flex-col gap-4 mt-4">
          <label class="form-control w-full">
            <div class="label"><span class="label-text text-[13px]">Map name</span></div>
            <input
              type="text"
              name="name"
              value="Untitled Map"
              class="input input-bordered w-full"
              autofocus
              required
            />
          </label>
          <div class="modal-action">
            <button type="button" phx-click="cancel_new_map" class="btn">Cancel</button>
            <button type="submit" class="btn btn-primary">Create</button>
          </div>
        </form>
      </div>
      <div class="modal-backdrop" phx-click="cancel_new_map"></div>
    </div>
    """
  end

  defp entity_form(assigns) do
    ~H"""
    <form phx-change="sync_field_value" phx-debounce="blur" class="flex flex-col gap-3">
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

  defp sidebar(assigns) do
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
              />
            <% end %>
          </div>

          <%!-- Bottom actions (Section 7 — stub) --%>
          <div class="border-t border-base-content/10 p-2 bg-base-200 flex gap-2 shrink-0">
            <%!-- Move and Delete buttons go here --%>
          </div>
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
        <%= if @selected_pin && !@sidebar_open do %>
          <span class="max-w-0 group-hover:max-w-[150px] overflow-hidden transition-all duration-200 group-hover:pr-2 text-left whitespace-nowrap">
            <span class="text-xs font-bold leading-tight block"><%= @selected_pin.entity.name %></span>
            <span class="text-xs opacity-60 leading-tight capitalize block"><%= @selected_pin.pin.entity_type %></span>
          </span>
        <% end %>
      </button>
    </div>
    """
  end

  defp map_pins(assigns) do
    ~H"""
    <div
      data-pins-overlay
      class="absolute inset-0 pointer-events-none"
      style="transform-origin: 0 0"
    >
      <div
        :if={@pending_pin}
        data-pending-pin
        class="absolute pointer-events-none opacity-60"
        style={"left: #{@pending_pin.x * 100}%; top: #{@pending_pin.y * 100}%; transform: translate(-50%, -100%)"}
      >
        <.icon name="hero-map-pin-solid" class="w-7 h-7 text-primary drop-shadow" />
      </div>
      <div
        :for={%{pin: pin, entity: entity} <- @pins}
        data-pin
        phx-click="select_pin"
        phx-value-id={pin.id}
        class="absolute pointer-events-auto group cursor-pointer"
        style={"left: #{pin.x * 100}%; top: #{pin.y * 100}%; transform: translate(-50%, -100%)"}
      >
        <.icon
          name="hero-map-pin-solid"
          class={"w-7 h-7 drop-shadow #{pin_color_class(pin.entity_type)}"}
        />
        <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 hidden group-hover:block pointer-events-none z-10">
          <div class="bg-base-100 border border-base-content/20 rounded-lg shadow-lg px-2 py-1.5 text-center whitespace-nowrap">
            <p class="text-xs font-bold"><%= entity.name %></p>
            <p class="text-xs opacity-60 capitalize"><%= pin.entity_type %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp pin_color_class("continent"), do: "text-green-500"
  defp pin_color_class("ocean"), do: "text-blue-500"
  defp pin_color_class(_), do: "text-base-content"

  defp map_viewport(assigns) do
    ~H"""
    <main
      id="map-container"
      phx-hook=".MapContainer"
      data-map-id={if @map, do: to_string(@map.id), else: ""}
      class={["flex-1 overflow-hidden bg-base-300 select-none relative", if(@pin_mode, do: "cursor-crosshair", else: "")]}
    >
      <.map_tabs maps={@maps} map={@map} renaming={@renaming} />
      <.map_actions :if={@map} map={@map} renaming={@renaming} />
      <.map_image uploads={@uploads} map={@map} image_broken={@image_broken} pending_image={@pending_image} />
      <.map_pins pins={@pins} pending_pin={@pending_pin} />
      <.sidebar selected_pin={@selected_pin} sidebar_open={@sidebar_open} field_values={@field_values} editing_fields={@editing_fields} />
      <.zoom_controls />
    </main>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".MapContainer">
      export default {
        mounted() {
          this.scale = 1
          this.tx = 0
          this.ty = 0
          this.dragging = false
          this.dragStartX = 0
          this.dragStartY = 0

          const MIN_SCALE = 1
          const MAX_SCALE = 10

          this.img = () => this.el.querySelector("img")
          this.pinsOverlay = () => this.el.querySelector("[data-pins-overlay]")

          this.applyTransform = () => {
            const img = this.img()
            if (!img) return
            img.style.transformOrigin = "0 0"
            img.style.transform = `translate(${this.tx}px, ${this.ty}px) scale(${this.scale})`

            const overlay = this.pinsOverlay()
            if (overlay) {
              overlay.style.transformOrigin = "0 0"
              overlay.style.transform = `translate(${this.tx}px, ${this.ty}px) scale(${this.scale})`
              overlay.querySelectorAll("[data-pin],[data-pending-pin]").forEach(pin => {
                pin.style.transform = `translate(-50%, -100%) scale(${1 / this.scale})`
              })
            }
          }

          this.reset = () => {
            this.scale = 1
            this.tx = 0
            this.ty = 0
            this.applyTransform()
            this.syncUI()
          }

          this.clamp = () => {
            const W = this.el.offsetWidth
            const H = this.el.offsetHeight
            const img = this.img()
            const s = this.scale

            let ox = 0, oy = 0
            if (img && img.naturalWidth && img.naturalHeight) {
              if (img.naturalWidth / img.naturalHeight > W / H) {
                oy = (H - W * img.naturalHeight / img.naturalWidth) / 2
              } else {
                ox = (W - H * img.naturalWidth / img.naturalHeight) / 2
              }
            }

            const txMax = -ox * s
            const txMin = W * (1 - s) + ox * s
            this.tx = txMin > txMax
              ? (txMin + txMax) / 2
              : Math.min(txMax, Math.max(txMin, this.tx))

            const tyMax = -oy * s
            const tyMin = H * (1 - s) + oy * s
            this.ty = tyMin > tyMax
              ? (tyMin + tyMax) / 2
              : Math.min(tyMax, Math.max(tyMin, this.ty))
          }

          this.applyZoom = (factor, originX, originY) => {
            const newScale = Math.min(MAX_SCALE, Math.max(MIN_SCALE, this.scale * factor))
            if (newScale <= MIN_SCALE) {
              this.scale = MIN_SCALE
              this.tx = 0
              this.ty = 0
            } else {
              const ratio = newScale / this.scale
              this.tx = originX - ratio * (originX - this.tx)
              this.ty = originY - ratio * (originY - this.ty)
              this.scale = newScale
            }
            this.clamp()
            this.applyTransform()
            this.syncUI()
          }

          this.zoomFromCenter = (factor) => {
            if (!this.img()) return
            const rect = this.el.getBoundingClientRect()
            this.applyZoom(factor, rect.width / 2, rect.height / 2)
          }

          this.syncUI = () => {
            const zoomInBtn = document.getElementById("zoom-in-btn")
            const zoomOutBtn = document.getElementById("zoom-out-btn")
            const resetBtn = document.getElementById("reset-view-btn")
            if (zoomInBtn) zoomInBtn.disabled = this.scale >= MAX_SCALE
            if (zoomOutBtn) zoomOutBtn.disabled = this.scale <= MIN_SCALE
            if (resetBtn) resetBtn.disabled = this.scale <= MIN_SCALE
            this.el.style.cursor = this.scale > MIN_SCALE ? "grab" : ""
          }

          this.onWheel = (e) => {
            if (!this.img()) return
            e.preventDefault()
            const rect = this.el.getBoundingClientRect()
            this.applyZoom(e.deltaY < 0 ? 1.1 : 1 / 1.1, e.clientX - rect.left, e.clientY - rect.top)
          }

          this.onMouseDown = (e) => {
            if (e.button !== 0 || this.scale <= MIN_SCALE) return
            if (e.target.closest("button")) return
            this.dragging = true
            this.dragStartX = e.clientX - this.tx
            this.dragStartY = e.clientY - this.ty
            this.el.style.cursor = "grabbing"
            e.preventDefault()
          }

          this.onMouseMove = (e) => {
            if (!this.dragging) return
            this.tx = e.clientX - this.dragStartX
            this.ty = e.clientY - this.dragStartY
            this.clamp()
            this.applyTransform()
          }

          this.onMouseUp = () => {
            if (!this.dragging) return
            this.dragging = false
            this.el.style.cursor = this.scale > 1 ? "grab" : ""
          }

          this.el.addEventListener("wheel", this.onWheel, { passive: false })
          this.el.addEventListener("mousedown", this.onMouseDown)
          window.addEventListener("mousemove", this.onMouseMove)
          window.addEventListener("mouseup", this.onMouseUp)
          this.el.addEventListener("map:zoom-in", () => this.zoomFromCenter(1.5))
          this.el.addEventListener("map:zoom-out", () => this.zoomFromCenter(1 / 1.5))
          this.el.addEventListener("map:reset-view", () => this.reset())

          // Map click handler: pin placement or background deselect
          this.onPinClick = (e) => {
            const onPin = !!e.target.closest("[data-pin]")
            const onButton = !!e.target.closest("button")

            const onSidebar = !!e.target.closest("[data-sidebar]")

            if (this.el.classList.contains("cursor-crosshair")) {
              // Pin placement mode — place pin on background click
              if (onButton || onPin || onSidebar) return
              e.stopPropagation()

              const rect = this.el.getBoundingClientRect()
              const rawX = e.clientX - rect.left
              const rawY = e.clientY - rect.top
              const x = Math.max(0, Math.min(1, (rawX - this.tx) / (rect.width * this.scale)))
              const y = Math.max(0, Math.min(1, (rawY - this.ty) / (rect.height * this.scale)))
              this.pushEvent("pin_clicked", { x, y })
            } else {
              // Normal mode — background click deselects current pin
              if (!onPin && !onButton && !onSidebar) {
                this.pushEvent("deselect_pin", {})
              }
            }
          }
          this.el.addEventListener("click", this.onPinClick)

          this._lastMapId = this.el.dataset.mapId
          this.syncUI()
        },

        updated() {
          const mapId = this.el.dataset.mapId
          if (mapId !== this._lastMapId) {
            this._lastMapId = mapId
            this.reset()
          } else {
            // Re-apply transform so newly rendered pins get correct position
            this.applyTransform()
          }
        },

        destroyed() {
          this.el.removeEventListener("wheel", this.onWheel)
          this.el.removeEventListener("mousedown", this.onMouseDown)
          window.removeEventListener("mousemove", this.onMouseMove)
          window.removeEventListener("mouseup", this.onMouseUp)
          this.el.removeEventListener("click", this.onPinClick)
        }
      }
    </script>
    """
  end

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

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp load_pins(socket) do
    case socket.assigns.map do
      nil ->
        assign(socket, :pins, [])

      map ->
        pin_data =
          map
          |> Pins.list_pins_for_map()
          |> Enum.map(fn pin -> %{pin: pin, entity: Pins.get_entity_for_pin(pin)} end)

        assign(socket, :pins, pin_data)
    end
  end

  defp clear_pending(socket) do
    socket =
      socket.assigns.uploads.map_image.entries
      |> Enum.reduce(socket, fn entry, sock ->
        cancel_upload(sock, :map_image, entry.ref)
      end)

    if socket.assigns.pending_image do
      MapStorage.delete(socket.assigns.pending_image)
    end

    socket
    |> assign(:pending_image, nil)
    |> assign(:naming_new_map, nil)
    |> assign(:image_dimensions, nil)
  end

  defp image_broken?(nil), do: false

  defp image_broken?(map) do
    disk_path =
      Path.join([
        :code.priv_dir(:estratos),
        "static",
        "uploads",
        "maps",
        Path.basename(map.image_path)
      ])

    not File.exists?(disk_path)
  end

  # ---------------------------------------------------------------------------
  # Events
  # ---------------------------------------------------------------------------

  @impl true
  def handle_event("validate", _params, socket) do
    entries = socket.assigns.uploads.map_image.entries

    socket =
      if length(entries) > 1 do
        entries
        |> List.delete_at(-1)
        |> Enum.reduce(socket, fn entry, sock ->
          cancel_upload(sock, :map_image, entry.ref)
        end)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("reupload", _params, socket) do
    {:noreply, push_event(socket, "trigger-upload", %{id: socket.assigns.uploads.map_image.ref})}
  end

  @impl true
  def handle_event("select_map", %{"id" => id}, socket) do
    map = Worlds.get_map(String.to_integer(id))

    {:noreply,
     socket
     |> clear_pending()
     |> assign(:map, map)
     |> assign(:image_broken, image_broken?(map))
     |> assign(:renaming, false)
     |> load_pins()}
  end

  @impl true
  def handle_event("new_map", _params, socket) do
    {:noreply,
     socket
     |> clear_pending()
     |> assign(:map, nil)
     |> assign(:image_broken, false)
     |> assign(:renaming, false)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    case socket.assigns.uploads.map_image.entries do
      [] when socket.assigns.pending_image != nil ->
        {w, h} = socket.assigns.image_dimensions || {nil, nil}

        {:noreply,
         assign(socket, :naming_new_map, %{
           image_path: socket.assigns.pending_image,
           image_width: w,
           image_height: h
         })}

      [] ->
        {:noreply, socket}

      _ ->
        result =
          consume_uploaded_entries(socket, :map_image, fn %{path: tmp_path}, entry ->
            {:ok, MapStorage.store(tmp_path, entry.client_name)}
          end)

        case result do
          [{:ok, image_path}] when is_binary(image_path) ->
            {width, height} = socket.assigns.image_dimensions || {nil, nil}

            # Clean up previous pending image if replacing before save
            if socket.assigns.pending_image do
              MapStorage.delete(socket.assigns.pending_image)
            end

            socket =
              case socket.assigns.map do
                nil ->
                  socket
                  |> assign(:naming_new_map, %{
                    image_path: image_path,
                    image_width: width,
                    image_height: height
                  })
                  |> assign(:pending_image, image_path)

                current_map ->
                  MapStorage.delete(current_map.image_path)

                  {:ok, map} =
                    Worlds.update_map(current_map, %{
                      image_path: image_path,
                      image_width: width,
                      image_height: height
                    })

                  maps = Worlds.list_maps_for_world(socket.assigns.world)

                  socket
                  |> assign(:map, map)
                  |> assign(:maps, maps)
                  |> assign(:pending_image, nil)
              end

            {:noreply,
             socket
             |> assign(:image_broken, false)
             |> assign(:image_dimensions, nil)}

          _ ->
            {:noreply, put_flash(socket, :error, "Failed to save image")}
        end
    end
  end

  # New map naming

  @impl true
  def handle_event("confirm_new_map", %{"name" => name}, socket) do
    name = String.trim(name)
    name = if name == "", do: "Untitled Map", else: name
    pending = socket.assigns.naming_new_map

    {:ok, map} =
      Worlds.create_map(socket.assigns.world, %{
        name: name,
        image_path: pending.image_path,
        image_width: pending.image_width,
        image_height: pending.image_height
      })

    maps = Worlds.list_maps_for_world(socket.assigns.world)

    {:noreply,
     socket
     |> assign(:map, map)
     |> assign(:maps, maps)
     |> assign(:naming_new_map, nil)
     |> assign(:pending_image, nil)
     |> assign(:image_broken, false)}
  end

  @impl true
  def handle_event("cancel_new_map", _params, socket) do
    {:noreply, assign(socket, :naming_new_map, nil)}
  end

  # World modal (edit existing or create new)

  @impl true
  def handle_event("new_world", _params, socket) do
    {:noreply, assign(socket, :world_modal, :new)}
  end

  @impl true
  def handle_event("start_rename_world", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_world, socket.assigns.world)
     |> assign(:world_modal, :edit)}
  end

  @impl true
  def handle_event("start_rename_world_id", %{"id" => id}, socket) do
    editing_world = Worlds.get_world!(String.to_integer(id))

    {:noreply,
     socket
     |> assign(:editing_world, editing_world)
     |> assign(:world_modal, :edit)}
  end

  @impl true
  def handle_event("cancel_rename_world", _params, socket) do
    {:noreply,
     socket
     |> assign(:world_modal, nil)
     |> assign(:editing_world, nil)}
  end

  @impl true
  def handle_event("rename_world", %{"name" => name, "description" => description}, socket) do
    name = String.trim(name)
    target = socket.assigns.editing_world || socket.assigns.world

    if name != "" do
      {:ok, updated} = Worlds.update_world(target, %{name: name, description: description})
      worlds = Worlds.list_worlds()

      # If we edited the active world, update it
      world =
        if target.id == socket.assigns.world.id, do: updated, else: socket.assigns.world

      {:noreply,
       socket
       |> assign(:world, world)
       |> assign(:worlds, worlds)
       |> assign(:editing_world, nil)
       |> assign(:world_modal, nil)}
    else
      {:noreply,
       socket
       |> assign(:editing_world, nil)
       |> assign(:world_modal, nil)}
    end
  end

  @impl true
  def handle_event("create_world", %{"name" => name, "description" => description}, socket) do
    name = String.trim(name)
    name = if name == "", do: "New World", else: name

    {:ok, world} = Worlds.create_world(%{name: name, description: description})
    worlds = Worlds.list_worlds()
    maps = Worlds.list_maps_for_world(world)

    {:noreply,
     socket
     |> clear_pending()
     |> assign(:world, world)
     |> assign(:worlds, worlds)
     |> assign(:maps, maps)
     |> assign(:map, nil)
     |> assign(:image_broken, false)
     |> assign(:renaming, false)
     |> assign(:world_modal, nil)
     |> load_pins()}
  end

  # World deletion

  @impl true
  def handle_event("delete_world", %{"id" => id}, socket) do
    world_to_delete = Worlds.get_world!(String.to_integer(id))
    Worlds.delete_world(world_to_delete)

    next_world = Worlds.get_or_create_default_world()
    worlds = Worlds.list_worlds()
    maps = Worlds.list_maps_for_world(next_world)
    map = List.first(maps)

    {:noreply,
     socket
     |> clear_pending()
     |> assign(:world, next_world)
     |> assign(:worlds, worlds)
     |> assign(:maps, maps)
     |> assign(:map, map)
     |> assign(:image_broken, image_broken?(map))
     |> assign(:renaming, false)
     |> assign(:editing_world, nil)
     |> assign(:world_modal, nil)
     |> load_pins()}
  end

  # World switching

  @impl true
  def handle_event("select_world", %{"id" => id}, socket) do
    world = Worlds.get_world!(String.to_integer(id))
    maps = Worlds.list_maps_for_world(world)
    map = List.first(maps)

    {:noreply,
     socket
     |> clear_pending()
     |> assign(:world, world)
     |> assign(:maps, maps)
     |> assign(:map, map)
     |> assign(:image_broken, image_broken?(map))
     |> assign(:renaming, false)
     |> load_pins()}
  end

  # Map renaming

  @impl true
  def handle_event("start_rename", _params, socket) do
    {:noreply, assign(socket, :renaming, true)}
  end

  @impl true
  def handle_event("cancel_rename", _params, socket) do
    {:noreply, assign(socket, :renaming, false)}
  end

  @impl true
  def handle_event("rename_map", %{"name" => name}, socket) do
    name = String.trim(name)

    if name != "" do
      {:ok, map} = Worlds.update_map(socket.assigns.map, %{name: name})
      maps = Worlds.list_maps_for_world(socket.assigns.world)

      {:noreply,
       socket
       |> assign(:map, map)
       |> assign(:maps, maps)
       |> assign(:renaming, false)}
    else
      {:noreply, assign(socket, :renaming, false)}
    end
  end

  # Map deletion

  @impl true
  def handle_event("delete_map", _params, socket) do
    map = socket.assigns.map
    MapStorage.delete(map.image_path)
    Worlds.delete_map(map)

    maps = Worlds.list_maps_for_world(socket.assigns.world)
    next_map = List.first(maps)

    {:noreply,
     socket
     |> assign(:map, next_map)
     |> assign(:maps, maps)
     |> assign(:image_broken, image_broken?(next_map))
     |> assign(:renaming, false)}
  end

  # Image events

  @impl true
  def handle_event("image_dimensions", %{"width" => width, "height" => height}, socket) do
    {:noreply, assign(socket, :image_dimensions, {width, height})}
  end

  @impl true
  def handle_event("image_error", _params, socket) do
    {:noreply,
     socket
     |> assign(:image_broken, true)
     |> put_flash(:error, "Map image failed to load")}
  end

  # Pin mode

  @impl true
  def handle_event("toggle_pin_mode", _params, socket) do
    {:noreply,
     socket
     |> assign(:pin_mode, !socket.assigns.pin_mode)
     |> assign(:pending_pin, nil)}
  end

  @impl true
  def handle_event("pin_clicked", %{"x" => x, "y" => y}, socket) do
    if socket.assigns.pin_mode do
      {:noreply, assign(socket, :pending_pin, %{x: x, y: y})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("pin_type_changed", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_pin", params, socket) do
    %{"pin_type" => pin_type, "name" => name} = params
    description = Map.get(params, "description", "")
    display_name = Map.get(params, "display_name", "")
    pending = socket.assigns.pending_pin
    world = socket.assigns.world
    map = socket.assigns.map

    entity_attrs = %{
      name: String.trim(name),
      description: if(description == "", do: nil, else: String.trim(description)),
      display_name: if(display_name == "", do: nil, else: String.trim(display_name))
    }

    result =
      case pin_type do
        "continent" -> Entities.create_continent(world, entity_attrs)
        "ocean" -> Entities.create_ocean(world, entity_attrs)
      end

    case result do
      {:ok, entity} ->
        {:ok, _pin} =
          Pins.create_pin(%{
            entity_type: pin_type,
            entity_id: entity.id,
            map_id: map.id,
            x: pending.x,
            y: pending.y
          })

        {:noreply,
         socket
         |> assign(:pending_pin, nil)
         |> assign(:pin_mode, false)
         |> load_pins()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save pin — name is required")}
    end
  end

  @impl true
  def handle_event("cancel_pin", _params, socket) do
    {:noreply,
     socket
     |> assign(:pending_pin, nil)}
  end

  @impl true
  def handle_event("select_pin", %{"id" => id}, socket) do
    pin = Pins.get_pin!(String.to_integer(id))
    entity = Pins.get_entity_for_pin(pin)

    field_values = %{
      "name" => entity.name,
      "display_name" => entity.display_name || "",
      "description" => entity.description || ""
    }

    {:noreply,
     socket
     |> assign(:selected_pin, %{pin: pin, entity: entity})
     |> assign(:sidebar_open, true)
     |> assign(:field_values, field_values)
     |> assign(:editing_fields, MapSet.new())}
  end

  @impl true
  def handle_event("deselect_pin", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_pin, nil)
     |> assign(:sidebar_open, false)}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    if socket.assigns.selected_pin do
      {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("sync_field_value", %{"_target" => [field]} = params, socket) do
    value = params[field] || ""
    field_values = Map.put(socket.assigns.field_values, field, value)
    {:noreply, assign(socket, :field_values, field_values)}
  end

  @impl true
  def handle_event("toggle_field_edit", %{"field" => field}, socket) do
    editing = socket.assigns.editing_fields

    if MapSet.member?(editing, field) do
      # Save field
      value = Map.get(socket.assigns.field_values, field, "")
      entity = socket.assigns.selected_pin.entity
      pin = socket.assigns.selected_pin.pin

      entity_attrs = %{
        String.to_atom(field) => if(value == "", do: nil, else: String.trim(value))
      }

      {:ok, updated_entity} =
        case pin.entity_type do
          "continent" -> Entities.update_continent(entity, entity_attrs)
          "ocean" -> Entities.update_ocean(entity, entity_attrs)
        end

      selected_pin = %{pin: pin, entity: updated_entity}

      # Update field_values to reflect saved value
      updated_field_values = Map.put(socket.assigns.field_values, field, Map.get(updated_entity, String.to_atom(field)) || "")

      {:noreply,
       socket
       |> assign(:selected_pin, selected_pin)
       |> assign(:field_values, updated_field_values)
       |> assign(:editing_fields, MapSet.delete(editing, field))}
    else
      # Enable edit
      {:noreply, assign(socket, :editing_fields, MapSet.put(editing, field))}
    end
  end
end
