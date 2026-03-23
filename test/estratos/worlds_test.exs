defmodule Estratos.WorldsTest do
  use Estratos.DataCase, async: true

  alias Estratos.Worlds

  @valid_attrs %{name: "Test Map", image_path: "/uploads/maps/test.png"}

  describe "create_map/1" do
    test "creates a map with valid attrs" do
      assert {:ok, map} = Worlds.create_map(@valid_attrs)
      assert map.name == "Test Map"
      assert map.image_path == "/uploads/maps/test.png"
    end

    test "returns error changeset when name is missing" do
      assert {:error, changeset} = Worlds.create_map(%{image_path: "/uploads/maps/test.png"})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset when image_path is missing" do
      assert {:error, changeset} = Worlds.create_map(%{name: "Test Map"})
      assert %{image_path: ["can't be blank"]} = errors_on(changeset)
    end

    test "stores image_width and image_height when provided" do
      attrs = Map.merge(@valid_attrs, %{image_width: 1920, image_height: 1080})
      assert {:ok, map} = Worlds.create_map(attrs)
      assert map.image_width == 1920
      assert map.image_height == 1080
    end
  end

  describe "get_map/1" do
    test "returns the map for a valid id" do
      {:ok, created} = Worlds.create_map(@valid_attrs)
      assert map = Worlds.get_map(created.id)
      assert map.id == created.id
    end

    test "returns nil for a nonexistent id" do
      assert Worlds.get_map(0) == nil
    end
  end

  describe "list_maps/0" do
    test "returns all maps ordered by id descending" do
      {:ok, first} = Worlds.create_map(@valid_attrs)
      {:ok, second} = Worlds.create_map(%{name: "Second Map", image_path: "/uploads/maps/second.png"})
      [head | _] = Worlds.list_maps()
      assert head.id == second.id
      assert second.id > first.id
    end

    test "returns empty list when no maps exist" do
      assert Worlds.list_maps() == []
    end
  end

  describe "update_map/2" do
    test "updates a map with valid attrs" do
      {:ok, map} = Worlds.create_map(@valid_attrs)
      assert {:ok, updated} = Worlds.update_map(map, %{name: "Updated Name"})
      assert updated.name == "Updated Name"
    end

    test "returns error changeset when name is cleared" do
      {:ok, map} = Worlds.create_map(@valid_attrs)
      assert {:error, changeset} = Worlds.update_map(map, %{name: nil})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "delete_map/1" do
    test "deletes the map" do
      {:ok, map} = Worlds.create_map(@valid_attrs)
      assert {:ok, _} = Worlds.delete_map(map)
      assert Worlds.get_map(map.id) == nil
    end
  end
end
