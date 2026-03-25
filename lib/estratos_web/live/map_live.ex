defmodule EstratosWeb.MapLive do
  use EstratosWeb, :live_view

  alias Estratos.Worlds
  alias Estratos.MapStorage

  @impl true
  def mount(_params, _session, socket) do
    world = Worlds.get_or_create_default_world()
    maps = Worlds.list_maps_for_world(world)
    map = List.first(maps)

    socket =
      socket
      |> assign(:world, world)
      |> assign(:maps, maps)
      |> assign(:map, map)
      |> assign(:image_broken, image_broken?(map))
      |> assign(:image_dimensions, nil)
      |> assign(:renaming, false)
      |> assign(:renaming_world, false)
      |> assign(:naming_new_map, nil)
      |> allow_upload(:map_image,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
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
      <.navbar world={@world} uploads={@uploads} />
      <.map_viewport uploads={@uploads} map={@map} maps={@maps} renaming={@renaming} image_broken={@image_broken} />
      <Layouts.flash_group flash={@flash} />
      <.world_modal :if={@renaming_world} world={@world} />
      <.name_map_modal :if={@naming_new_map} />
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
        <span
          class="font-semibold tracking-wide text-base-content cursor-pointer hover:text-primary transition-colors"
          title={@world.description || "Click to edit world"}
          phx-click="start_rename_world"
        >
          <%= @world.name %>
        </span>
      </div>
      <form phx-change="validate" phx-submit="save" class="flex gap-2" id="upload-form">
        <label for={@uploads.map_image.ref} class="btn btn-sm btn-outline cursor-pointer">
          Upload
        </label>
        <.live_file_input upload={@uploads.map_image} class="hidden" />
        <button
          type="submit"
          class="btn btn-sm btn-primary"
          disabled={@uploads.map_image.entries == []}
        >
          Save
        </button>
      </form>
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

  defp world_modal(assigns) do
    ~H"""
    <div class="modal modal-open modal-middle">
      <div class="modal-box max-w-sm">
        <h3 class="font-bold text-lg">Edit World</h3>
        <form phx-submit="rename_world" class="flex flex-col gap-4 mt-4">
          <label class="form-control w-full">
            <div class="label"><span class="label-text">Name</span></div>
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
            <div class="label"><span class="label-text">Description</span></div>
            <textarea
              name="description"
              class="textarea textarea-bordered w-full"
              rows="3"
              placeholder="A brief description of your world"
            ><%= @world.description %></textarea>
          </label>
          <div class="modal-action">
            <button type="button" phx-click="cancel_rename_world" class="btn">Cancel</button>
            <button type="submit" class="btn btn-primary">Save</button>
          </div>
        </form>
      </div>
      <div class="modal-backdrop" phx-click="cancel_rename_world"></div>
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
            <div class="label"><span class="label-text">Map name</span></div>
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

  defp map_viewport(assigns) do
    ~H"""
    <main
      id="map-container"
      phx-hook=".MapContainer"
      class="flex-1 overflow-hidden bg-base-300 select-none relative"
    >
      <.map_tabs maps={@maps} map={@map} renaming={@renaming} />
      <.map_actions :if={@map} map={@map} renaming={@renaming} />
      <.map_image uploads={@uploads} map={@map} image_broken={@image_broken} />
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

          this.applyTransform = () => {
            const img = this.img()
            if (!img) return
            img.style.transformOrigin = "0 0"
            img.style.transform = `translate(${this.tx}px, ${this.ty}px) scale(${this.scale})`
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

          this.syncUI()
        },

        updated() {
          this.reset()
        },

        destroyed() {
          this.el.removeEventListener("wheel", this.onWheel)
          this.el.removeEventListener("mousedown", this.onMouseDown)
          window.removeEventListener("mousemove", this.onMouseMove)
          window.removeEventListener("mouseup", this.onMouseUp)
        }
      }
    </script>
    """
  end

  defp map_image(assigns) do
    ~H"""
    <%= if entry = List.first(@uploads.map_image.entries) do %>
      <.live_img_preview
        entry={entry}
        class="w-full h-full object-contain"
        phx-hook=".MapImage"
        id="map-preview"
        draggable="false"
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
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_map", %{"id" => id}, socket) do
    map = Worlds.get_map(String.to_integer(id))

    {:noreply,
     socket
     |> assign(:map, map)
     |> assign(:image_broken, image_broken?(map))
     |> assign(:renaming, false)}
  end

  @impl true
  def handle_event("new_map", _params, socket) do
    {:noreply,
     socket
     |> assign(:map, nil)
     |> assign(:image_broken, false)
     |> assign(:renaming, false)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    case socket.assigns.uploads.map_image.entries do
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

            socket =
              case socket.assigns.map do
                nil ->
                  assign(socket, :naming_new_map, %{
                    image_path: image_path,
                    image_width: width,
                    image_height: height
                  })

                current_map ->
                  MapStorage.delete(current_map.image_path)

                  {:ok, map} =
                    Worlds.update_map(current_map, %{
                      image_path: image_path,
                      image_width: width,
                      image_height: height
                    })

                  maps = Worlds.list_maps_for_world(socket.assigns.world)
                  socket |> assign(:map, map) |> assign(:maps, maps)
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
     |> assign(:image_broken, false)}
  end

  @impl true
  def handle_event("cancel_new_map", _params, socket) do
    pending = socket.assigns.naming_new_map
    if pending, do: MapStorage.delete(pending.image_path)

    {:noreply, assign(socket, :naming_new_map, nil)}
  end

  # World editing

  @impl true
  def handle_event("start_rename_world", _params, socket) do
    {:noreply, assign(socket, :renaming_world, true)}
  end

  @impl true
  def handle_event("cancel_rename_world", _params, socket) do
    {:noreply, assign(socket, :renaming_world, false)}
  end

  @impl true
  def handle_event("rename_world", %{"name" => name, "description" => description}, socket) do
    name = String.trim(name)

    if name != "" do
      {:ok, world} =
        Worlds.update_world(socket.assigns.world, %{name: name, description: description})

      {:noreply,
       socket
       |> assign(:world, world)
       |> assign(:renaming_world, false)}
    else
      {:noreply, assign(socket, :renaming_world, false)}
    end
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
end
