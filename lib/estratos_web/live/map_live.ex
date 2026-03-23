defmodule EstratosWeb.MapLive do
  use EstratosWeb, :live_view

  alias Estratos.Worlds
  alias Estratos.MapStorage

  @impl true
  def mount(_params, _session, socket) do
    map = Worlds.list_maps() |> List.first()

    socket =
      socket
      |> assign(:map, map)
      |> assign(:image_dimensions, nil)
      |> allow_upload(:map_image,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: 50_000_000
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <.navbar uploads={@uploads} />
      <.map_viewport uploads={@uploads} map={@map} />
      <Layouts.flash_group flash={@flash} />
    </div>
    """
  end

  defp navbar(assigns) do
    ~H"""
    <header class="navbar bg-base-200 border-b border-base-300 px-4 shrink-0">
      <div class="flex-1">
        <span class="font-semibold tracking-wide text-base-content">Estratos</span>
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

  defp map_viewport(assigns) do
    ~H"""
    <main
      id="map-container"
      phx-hook=".MapContainer"
      class="flex-1 overflow-hidden bg-base-300 select-none relative"
    >
      <.map_image uploads={@uploads} map={@map} />
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

          this.zoomFromCenter = (factor) => {
            const img = this.img()
            if (!img) return
            const rect = this.el.getBoundingClientRect()
            const cx = rect.width / 2
            const cy = rect.height / 2
            const newScale = Math.min(MAX_SCALE, Math.max(MIN_SCALE, this.scale * factor))
            if (newScale <= MIN_SCALE) {
              this.scale = MIN_SCALE
              this.tx = 0
              this.ty = 0
            } else {
              const ratio = newScale / this.scale
              this.tx = cx - ratio * (cx - this.tx)
              this.ty = cy - ratio * (cy - this.ty)
              this.scale = newScale
            }
            this.clamp()
            this.applyTransform()
            this.syncUI()
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
            const img = this.img()
            if (!img) return
            e.preventDefault()

            const rect = this.el.getBoundingClientRect()
            const mouseX = e.clientX - rect.left
            const mouseY = e.clientY - rect.top

            const factor = e.deltaY < 0 ? 1.1 : 1 / 1.1
            const newScale = Math.min(MAX_SCALE, Math.max(MIN_SCALE, this.scale * factor))

            if (newScale <= MIN_SCALE) {
              this.scale = MIN_SCALE
              this.tx = 0
              this.ty = 0
            } else {
              const ratio = newScale / this.scale
              this.tx = mouseX - ratio * (mouseX - this.tx)
              this.ty = mouseY - ratio * (mouseY - this.ty)
              this.scale = newScale
            }

            this.clamp()
            this.applyTransform()
            this.syncUI()
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
        <img
          src={@map.image_path}
          class="w-full h-full object-contain"
          id="map-image"
          draggable="false"
        />
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

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    entries = socket.assigns.uploads.map_image.entries

    case entries do
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

            {:ok, map} =
              Worlds.create_map(%{
                name: "Untitled Map",
                image_path: image_path,
                image_width: width,
                image_height: height
              })

            {:noreply,
             socket
             |> assign(:map, map)
             |> assign(:image_dimensions, nil)}

          _ ->
            {:noreply, put_flash(socket, :error, "Failed to save image")}
        end
    end
  end

  @impl true
  def handle_event("image_dimensions", %{"width" => width, "height" => height}, socket) do
    {:noreply, assign(socket, :image_dimensions, {width, height})}
  end
end
