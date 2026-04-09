defmodule Estratos.WorldsTest do
  use Estratos.DataCase, async: true

  alias Estratos.Worlds
  alias Estratos.Worlds.World

  @valid_map_attrs %{name: "Test Map", image_path: "/uploads/maps/test.png"}
  @valid_world_attrs %{name: "Test World"}

  defp create_world(attrs \\ @valid_world_attrs) do
    {:ok, world} =
      %World{}
      |> World.changeset(attrs)
      |> Estratos.Repo.insert()

    world
  end

  # ---------------------------------------------------------------------------
  # World
  # ---------------------------------------------------------------------------

  describe "get_or_create_default_world/0" do
    test "creates a world when none exists" do
      world = Worlds.get_or_create_default_world()
      assert world.name == "My World"
      assert world.id != nil
    end

    test "returns the existing world when one already exists" do
      existing = create_world()
      returned = Worlds.get_or_create_default_world()
      assert returned.id == existing.id
    end
  end

  describe "get_world!/1" do
    test "returns the world for a valid id" do
      world = create_world()
      assert Worlds.get_world!(world.id).id == world.id
    end

    test "raises when world does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Worlds.get_world!(0) end
    end
  end

  describe "update_world/2" do
    test "updates world name" do
      world = create_world()
      assert {:ok, updated} = Worlds.update_world(world, %{name: "Renamed World"})
      assert updated.name == "Renamed World"
    end

    test "updates world description" do
      world = create_world()
      assert {:ok, updated} = Worlds.update_world(world, %{description: "A vast realm"})
      assert updated.description == "A vast realm"
    end

    test "returns error changeset when name is cleared" do
      world = create_world()
      assert {:error, changeset} = Worlds.update_world(world, %{name: nil})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  # ---------------------------------------------------------------------------
  # Maps
  # ---------------------------------------------------------------------------

  describe "create_map/2" do
    test "creates a map associated with the world" do
      world = create_world()
      assert {:ok, map} = Worlds.create_map(world, @valid_map_attrs)
      assert map.name == "Test Map"
      assert map.image_path == "/uploads/maps/test.png"
      assert map.world_id == world.id
    end

    test "returns error changeset when name is missing" do
      world = create_world()
      assert {:error, changeset} = Worlds.create_map(world, %{image_path: "/uploads/maps/test.png"})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset when image_path is missing" do
      world = create_world()
      assert {:error, changeset} = Worlds.create_map(world, %{name: "Test Map"})
      assert %{image_path: ["can't be blank"]} = errors_on(changeset)
    end

    test "stores image_width and image_height when provided" do
      world = create_world()
      attrs = Elixir.Map.merge(@valid_map_attrs, %{image_width: 1920, image_height: 1080})
      assert {:ok, map} = Worlds.create_map(world, attrs)
      assert map.image_width == 1920
      assert map.image_height == 1080
    end
  end

  describe "get_map/1" do
    test "returns the map for a valid id" do
      world = create_world()
      {:ok, created} = Worlds.create_map(world, @valid_map_attrs)
      assert map = Worlds.get_map(created.id)
      assert map.id == created.id
    end

    test "returns nil for a nonexistent id" do
      assert Worlds.get_map(0) == nil
    end
  end

  describe "list_maps_for_world/1" do
    test "returns maps for the given world ordered by id descending" do
      world = create_world()
      {:ok, first} = Worlds.create_map(world, @valid_map_attrs)
      {:ok, second} = Worlds.create_map(world, %{name: "Second Map", image_path: "/uploads/maps/second.png"})
      [head | _] = Worlds.list_maps_for_world(world)
      assert head.id == second.id
      assert second.id > first.id
    end

    test "returns empty list when world has no maps" do
      world = create_world()
      assert Worlds.list_maps_for_world(world) == []
    end

    test "does not return maps from other worlds" do
      world_a = create_world(%{name: "World A"})
      world_b = create_world(%{name: "World B"})
      {:ok, _} = Worlds.create_map(world_a, @valid_map_attrs)
      assert Worlds.list_maps_for_world(world_b) == []
    end
  end

  describe "update_map/2" do
    test "updates a map with valid attrs" do
      world = create_world()
      {:ok, map} = Worlds.create_map(world, @valid_map_attrs)
      assert {:ok, updated} = Worlds.update_map(map, %{name: "Updated Name"})
      assert updated.name == "Updated Name"
    end

    test "returns error changeset when name is cleared" do
      world = create_world()
      {:ok, map} = Worlds.create_map(world, @valid_map_attrs)
      assert {:error, changeset} = Worlds.update_map(map, %{name: nil})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "delete_map/1" do
    test "deletes the map" do
      world = create_world()
      {:ok, map} = Worlds.create_map(world, @valid_map_attrs)
      assert {:ok, _} = Worlds.delete_map(map)
      assert Worlds.get_map(map.id) == nil
    end
  end
end
