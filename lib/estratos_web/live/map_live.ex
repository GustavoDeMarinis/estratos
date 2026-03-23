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
      <main class="flex-1 overflow-hidden bg-base-300">
        <%= if entry = List.first(@uploads.map_image.entries) do %>
          <.live_img_preview
            entry={entry}
            class="w-full h-full object-contain"
            phx-hook=".MapImage"
            id="map-preview"
          />
        <% else %>
          <%= if @map do %>
            <img
              src={@map.image_path}
              class="w-full h-full object-contain"
              id="map-image"
            />
          <% else %>
            <div class="flex items-center justify-center h-full">
              <p class="text-base-content/40 text-sm">Upload a map image to get started</p>
            </div>
          <% end %>
        <% end %>
      </main>
      <Layouts.flash_group flash={@flash} />
    </div>
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
