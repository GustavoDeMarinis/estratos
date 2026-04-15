defmodule EstratosWeb.MapLive do
  use EstratosWeb, :live_view

  alias Estratos.Worlds
  alias Estratos.MapStorage
  alias Estratos.Entities
  alias Estratos.Pins
  alias Estratos.Layers
  alias Estratos.EntityTypes
  alias EstratosWeb.MapLive.{Navbar, MapArea, Modals}

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
      |> assign(:pin_create_type, "continent")
      |> assign(:active_layers, Layers.all_slugs())
      |> load_pins()
      |> load_entity_lists()
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
      <Navbar.navbar
        world={@world}
        worlds={@worlds}
        map={@map}
        uploads={@uploads}
        pending_image={@pending_image}
        pin_mode={@pin_mode}
        active_layers={@active_layers}
      />
      <MapArea.map_viewport
        uploads={@uploads}
        map={@map}
        maps={@maps}
        renaming={@renaming}
        image_broken={@image_broken}
        pending_image={@pending_image}
        pin_mode={@pin_mode}
        pending_pin={@pending_pin}
        pins={@pins}
        selected_pin={@selected_pin}
        sidebar_open={@sidebar_open}
        field_values={@field_values}
        editing_fields={@editing_fields}
        moving_pin={@moving_pin}
        entity_lists={@entity_lists}
        active_layers={@active_layers}
      />
      <Layouts.flash_group flash={@flash} />
      <Modals.world_modal :if={@world_modal} world={@editing_world || @world} mode={@world_modal} />
      <Modals.name_map_modal :if={@naming_new_map} />
      <Modals.pin_create_modal
        :if={@pending_pin}
        pin_create_type={@pin_create_type}
        entity_lists={@entity_lists}
        active_layers={@active_layers}
      />
      <Modals.confirm_move_modal :if={@confirm_move} confirm_move={@confirm_move} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp load_entity_lists(socket) do
    world = socket.assigns.world

    entity_lists =
      EntityTypes.list_types()
      |> Enum.filter(& &1.parent_type)
      |> Enum.map(& &1.parent_type)
      |> Enum.uniq()
      |> Map.new(fn parent_slug ->
        type_info = EntityTypes.get_type(parent_slug)
        {parent_slug, apply(Entities, type_info.list_fn, [world])}
      end)

    assign(socket, :entity_lists, entity_lists)
  end

  # Loads the parent entity for a pin using the registry.
  defp load_parent(%{entity_type: entity_type}, entity) do
    with parent_slug when not is_nil(parent_slug) <- EntityTypes.parent_type(entity_type),
         fk when not is_nil(fk) <- EntityTypes.parent_fk(entity_type),
         parent_id when not is_nil(parent_id) <- Map.get(entity, fk) do
      parent_type_info = EntityTypes.get_type(parent_slug)
      apply(Entities, parent_type_info.get_fn, [parent_id])
    else
      _ -> nil
    end
  end

  # Builds the selected_pin assign and related assigns after selecting a pin.
  defp apply_select_pin(socket, pin) do
    entity = Pins.get_entity_for_pin(pin)
    parent = load_parent(pin, entity)

    parent_id =
      case EntityTypes.parent_fk(pin.entity_type) do
        nil -> ""
        fk -> to_string(Map.get(entity, fk) || "")
      end

    field_values = %{
      "name" => entity.name,
      "display_name" => entity.display_name || "",
      "description" => entity.description || "",
      "parent_id" => parent_id
    }

    socket
    |> assign(:selected_pin, %{pin: pin, entity: entity, parent: parent})
    |> assign(:sidebar_open, true)
    |> assign(:field_values, field_values)
    |> assign(:editing_fields, MapSet.new())
  end

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
     |> assign(:renaming, false)
     |> assign(:pin_mode, false)
     |> assign(:pending_pin, nil)
     |> assign(:selected_pin, nil)
     |> assign(:sidebar_open, false)
     |> load_pins()}
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
     |> assign(:image_broken, false)
     |> load_pins()}
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
     |> assign(:active_layers, Layers.all_slugs())
     |> load_pins()
     |> load_entity_lists()}
  end

  @impl true
  def handle_event("toggle_layer", %{"slug" => slug}, socket) do
    active = socket.assigns.active_layers

    new_active =
      if MapSet.member?(active, slug),
        do: MapSet.delete(active, slug),
        else: MapSet.put(active, slug)

    # Deselect current pin if its layer was just hidden
    socket =
      case socket.assigns.selected_pin do
        %{pin: pin} ->
          type_info = EntityTypes.get_type(pin.entity_type)
          if type_info && not MapSet.member?(new_active, type_info.layer) do
            socket
            |> assign(:selected_pin, nil)
            |> assign(:sidebar_open, false)
          else
            socket
          end

        nil ->
          socket
      end

    {:noreply, assign(socket, :active_layers, new_active)}
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
      {:noreply,
       socket
       |> assign(:pending_pin, %{x: x, y: y})
       |> assign(:pin_create_type, "continent")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("pin_type_changed", %{"pin_type" => pin_type}, socket) do
    {:noreply, assign(socket, :pin_create_type, pin_type)}
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

    parse_id = fn key ->
      case Map.get(params, key, "") do
        "" -> nil
        id -> String.to_integer(id)
      end
    end

    type_info = EntityTypes.get_type(pin_type)

    parent_attrs =
      case type_info.parent_fk do
        nil -> %{}
        fk -> %{fk => parse_id.(to_string(fk))}
      end

    result = apply(Entities, type_info.create_fn, [world, Map.merge(entity_attrs, parent_attrs)])

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
         |> load_pins()
         |> load_entity_lists()}

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
    {:noreply, apply_select_pin(socket, pin)}
  end

  @impl true
  def handle_event("deselect_pin", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_pin, nil)
     |> assign(:sidebar_open, false)}
  end

  @impl true
  def handle_event("navigate_to_parent", _params, socket) do
    parent = socket.assigns.selected_pin.parent
    entity_type = socket.assigns.selected_pin.pin.entity_type

    parent_entity_type = EntityTypes.parent_type(entity_type)

    parent_pin_entry =
      Enum.find(socket.assigns.pins, fn %{pin: p} ->
        p.entity_type == parent_entity_type and p.entity_id == parent.id
      end)

    case parent_pin_entry do
      %{pin: pin} ->
        {:noreply, apply_select_pin(socket, pin)}

      nil ->
        {:noreply, put_flash(socket, :info, "#{String.capitalize(parent_entity_type)} has no pin on this map")}
    end
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
    # Add to editing_fields so an empty field that was just typed into doesn't
    # immediately become disabled when field_values[field] transitions from "".
    editing_fields = MapSet.put(socket.assigns.editing_fields, field)
    {:noreply, socket |> assign(:field_values, field_values) |> assign(:editing_fields, editing_fields)}
  end

  @impl true
  def handle_event("toggle_field_edit", %{"field" => field}, socket) do
    editing = socket.assigns.editing_fields

    if MapSet.member?(editing, field) do
      %{pin: pin, entity: entity, parent: current_parent} = socket.assigns.selected_pin

      if field == "parent" do
        # Save parent FK
        parent_id =
          case Map.get(socket.assigns.field_values, "parent_id", "") do
            "" -> nil
            id -> String.to_integer(id)
          end

        type_info = EntityTypes.get_type(pin.entity_type)

        {:ok, updated_entity} =
          apply(Entities, type_info.update_fn, [entity, %{type_info.parent_fk => parent_id}])

        new_parent = load_parent(pin, updated_entity)

        {:noreply,
         socket
         |> assign(:selected_pin, %{pin: pin, entity: updated_entity, parent: new_parent})
         |> assign(:editing_fields, MapSet.delete(editing, field))
         |> load_entity_lists()}
      else
        # Save text field
        value = Map.get(socket.assigns.field_values, field, "")
        entity_attrs = %{String.to_atom(field) => if(value == "", do: nil, else: String.trim(value))}

        type_info = EntityTypes.get_type(pin.entity_type)

        {:ok, updated_entity} =
          apply(Entities, type_info.update_fn, [entity, entity_attrs])

        updated_field_values =
          Map.put(socket.assigns.field_values, field, Map.get(updated_entity, String.to_atom(field)) || "")

        {:noreply,
         socket
         |> assign(:selected_pin, %{pin: pin, entity: updated_entity, parent: current_parent})
         |> assign(:field_values, updated_field_values)
         |> assign(:editing_fields, MapSet.delete(editing, field))
         |> load_pins()}
      end
    else
      # Enable edit
      {:noreply, assign(socket, :editing_fields, MapSet.put(editing, field))}
    end
  end

  @impl true
  def handle_event("start_move_pin", _params, socket) do
    pin = socket.assigns.selected_pin.pin

    {:noreply,
     socket
     |> assign(:moving_pin, %{pin_id: pin.id, original_x: pin.x, original_y: pin.y})
     |> assign(:sidebar_open, false)}
  end

  @impl true
  def handle_event("move_pin_to", %{"x" => x, "y" => y}, socket) do
    if socket.assigns.moving_pin do
      %{pin: pin, entity: entity} = socket.assigns.selected_pin
      updated_pin = %{pin | x: x, y: y}

      updated_pins =
        Enum.map(socket.assigns.pins, fn
          %{pin: p} = entry when p.id == pin.id -> %{entry | pin: updated_pin}
          entry -> entry
        end)

      parent = socket.assigns.selected_pin.parent

      {:noreply,
       socket
       |> assign(:selected_pin, %{pin: updated_pin, entity: entity, parent: parent})
       |> assign(:pins, updated_pins)
       |> assign(:confirm_move, %{x: x, y: y})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("confirm_move", _params, socket) do
    %{pin_id: pin_id} = socket.assigns.moving_pin
    %{x: x, y: y} = socket.assigns.confirm_move
    pin = Pins.get_pin!(pin_id)
    {:ok, updated_pin} = Pins.update_pin(pin, %{x: x, y: y})

    {:noreply,
     socket
     |> assign(:moving_pin, nil)
     |> assign(:confirm_move, nil)
     |> apply_select_pin(updated_pin)
     |> load_pins()}
  end

  @impl true
  def handle_event("cancel_move", _params, socket) do
    pin = Pins.get_pin!(socket.assigns.moving_pin.pin_id)

    {:noreply,
     socket
     |> assign(:moving_pin, nil)
     |> assign(:confirm_move, nil)
     |> apply_select_pin(pin)
     |> load_pins()}
  end

  @impl true
  def handle_event("delete_entity", _params, socket) do
    %{pin: _pin, entity: entity} = socket.assigns.selected_pin

    type_info = EntityTypes.get_type(socket.assigns.selected_pin.pin.entity_type)
    apply(Entities, type_info.delete_fn, [entity])

    {:noreply,
     socket
     |> assign(:selected_pin, nil)
     |> assign(:sidebar_open, false)
     |> assign(:moving_pin, nil)
     |> assign(:confirm_move, nil)
     |> load_pins()}
  end
end
