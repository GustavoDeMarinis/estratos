defmodule EstratosWeb.MapLive.Navbar do
  @moduledoc """
  Top navbar for the map view: world dropdown, pin-mode toggle, upload form.
  """
  use EstratosWeb, :html

  attr :world, :map, required: true
  attr :worlds, :list, required: true
  attr :map, :any, required: true
  attr :uploads, :map, required: true
  attr :pending_image, :any, required: true
  attr :pin_mode, :boolean, required: true

  def navbar(assigns) do
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
        disabled={is_nil(@map) || @pending_image != nil || @uploads.map_image.entries != []}
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
end
