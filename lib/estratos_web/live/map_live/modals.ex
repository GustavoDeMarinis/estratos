defmodule EstratosWeb.MapLive.Modals do
  @moduledoc """
  Modal dialogs for the map view: world create/edit, pin creation, map naming.
  """
  use EstratosWeb, :html

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

  def pin_create_modal(assigns) do
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
end
