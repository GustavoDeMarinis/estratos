defmodule EstratosWeb.MapLive.Modals do
  @moduledoc """
  Modal dialogs for the map view: world create/edit, pin creation, map naming.
  """
  use EstratosWeb, :html

  alias Estratos.EntityTypes
  alias Estratos.Layers

  attr :world, :map, required: true
  attr :mode, :atom, required: true, values: [:new, :edit]

  def world_modal(%{mode: :new} = assigns) do
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

  def world_modal(%{mode: :edit} = assigns) do
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

  attr :pin_create_type, :string, required: true
  attr :entity_lists, :map, required: true
  attr :active_layers, :any, required: true

  def pin_create_modal(assigns) do
    ~H"""
    <div class="modal modal-open modal-middle">
      <div class="modal-box max-w-sm">
        <h3 class="font-bold text-lg">New Pin</h3>
        <form phx-submit="save_pin" phx-change="pin_type_changed" class="flex flex-col gap-4 mt-4" id="pin-create-form">
          <label class="form-control w-full">
            <div class="label"><span class="label-text text-[13px]">Type</span></div>
            <select name="pin_type" class="select select-bordered w-full" required>
              <%= for t <- EntityTypes.list_types(),
                      MapSet.member?(@active_layers, t.layer) do %>
                <option value={t.slug} selected={@pin_create_type == t.slug}><%= t.name %></option>
              <% end %>
            </select>
          </label>
          <%!-- Parent dropdown — rendered generically for any type that has a parent --%>
          <% parent_type = EntityTypes.parent_type(@pin_create_type) %>
          <label :if={parent_type} class="form-control w-full">
            <div class="label">
              <span class="label-text text-[13px]">
                <%= EntityTypes.name(parent_type) %>
                <span class="text-base-content/40">(optional)</span>
              </span>
            </div>
            <select name={EntityTypes.parent_fk(@pin_create_type)} class="select select-bordered w-full">
              <option value="">None</option>
              <option :for={p <- Map.get(@entity_lists, parent_type, [])} value={p.id}>
                <%= p.display_name || p.name %>
              </option>
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

  def name_map_modal(assigns) do
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

  attr :confirm_move, :map, required: true

  def confirm_move_modal(assigns) do
    ~H"""
    <div class="absolute inset-0 flex items-center justify-center z-30 pointer-events-none">
      <div class="bg-base-100 rounded-xl shadow-xl border border-base-content/20 p-4 flex flex-col gap-3 pointer-events-auto">
        <p class="text-sm font-semibold">Confirm new position?</p>
        <p class="text-xs text-base-content/60">
          <%= Float.round(@confirm_move.x * 100, 1) %>%, <%= Float.round(@confirm_move.y * 100, 1) %>%
        </p>
        <div class="flex gap-2">
          <button type="button" phx-click="confirm_move" class="btn btn-primary btn-sm flex-1">Confirm</button>
          <button type="button" phx-click="cancel_move" class="btn btn-ghost btn-sm flex-1">Cancel</button>
        </div>
      </div>
    </div>
    """
  end
end
