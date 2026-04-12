defmodule Estratos.PinsTest do
  use Estratos.DataCase, async: true

  alias Estratos.Entities
  alias Estratos.Pins
  alias Estratos.Worlds.World

  @valid_world_attrs %{name: "Test World"}
  @valid_map_attrs %{name: "Test Map", image_path: "/uploads/maps/test.png"}

  defp create_world do
    {:ok, world} =
      %World{}
      |> World.changeset(@valid_world_attrs)
      |> Estratos.Repo.insert()

    world
  end

  defp create_map(world) do
    {:ok, map} = Estratos.Worlds.create_map(world, @valid_map_attrs)
    map
  end

  defp create_continent(world) do
    {:ok, continent} = Entities.create_continent(world, %{name: "Aurelia"})
    continent
  end

  defp create_ocean(world) do
    {:ok, ocean} = Entities.create_ocean(world, %{name: "Pacific"})
    ocean
  end

  defp valid_pin_attrs(map, entity_type, entity_id, overrides \\ %{}) do
    Map.merge(
      %{entity_type: entity_type, entity_id: entity_id, map_id: map.id, x: 0.5, y: 0.5},
      overrides
    )
  end

  # ---------------------------------------------------------------------------
  # create_pin/1
  # ---------------------------------------------------------------------------

  describe "create_pin/1" do
    test "creates a pin with valid normalized coordinates" do
      world = create_world()
      map = create_map(world)
      continent = create_continent(world)

      assert {:ok, pin} =
               Pins.create_pin(valid_pin_attrs(map, "continent", continent.id))

      assert pin.entity_type == "continent"
      assert pin.entity_id == continent.id
      assert pin.map_id == map.id
      assert pin.x == 0.5
      assert pin.y == 0.5
    end

    test "rejects x below 0.0" do
      world = create_world()
      map = create_map(world)
      continent = create_continent(world)

      assert {:error, changeset} =
               Pins.create_pin(valid_pin_attrs(map, "continent", continent.id, %{x: -0.1}))

      assert %{x: [_]} = errors_on(changeset)
    end

    test "rejects x above 1.0" do
      world = create_world()
      map = create_map(world)
      continent = create_continent(world)

      assert {:error, changeset} =
               Pins.create_pin(valid_pin_attrs(map, "continent", continent.id, %{x: 1.1}))

      assert %{x: [_]} = errors_on(changeset)
    end

    test "rejects y outside 0.0–1.0 range" do
      world = create_world()
      map = create_map(world)
      continent = create_continent(world)

      assert {:error, _} =
               Pins.create_pin(valid_pin_attrs(map, "continent", continent.id, %{y: 1.5}))
    end

    test "accepts boundary values 0.0 and 1.0" do
      world = create_world()
      map = create_map(world)
      continent = create_continent(world)

      assert {:ok, _} =
               Pins.create_pin(valid_pin_attrs(map, "continent", continent.id, %{x: 0.0, y: 1.0}))
    end
  end

  # ---------------------------------------------------------------------------
  # list_pins_for_map/1
  # ---------------------------------------------------------------------------

  describe "list_pins_for_map/1" do
    test "returns only pins for the given map" do
      world = create_world()
      map = create_map(world)
      continent = create_continent(world)

      {:ok, pin} = Pins.create_pin(valid_pin_attrs(map, "continent", continent.id))
      result = Pins.list_pins_for_map(map)

      assert length(result) == 1
      assert hd(result).id == pin.id
    end

    test "does not return pins from other maps" do
      world = create_world()
      map_a = create_map(world)
      map_b = create_map(world)
      continent = create_continent(world)

      Pins.create_pin(valid_pin_attrs(map_a, "continent", continent.id))

      assert Pins.list_pins_for_map(map_b) == []
    end

    test "returns empty list when map has no pins" do
      world = create_world()
      map = create_map(world)
      assert Pins.list_pins_for_map(map) == []
    end
  end

  # ---------------------------------------------------------------------------
  # update_pin/2
  # ---------------------------------------------------------------------------

  describe "update_pin/2" do
    test "updates x and y coordinates" do
      world = create_world()
      map = create_map(world)
      continent = create_continent(world)
      {:ok, pin} = Pins.create_pin(valid_pin_attrs(map, "continent", continent.id))

      assert {:ok, updated} = Pins.update_pin(pin, %{x: 0.9, y: 0.1})
      assert updated.x == 0.9
      assert updated.y == 0.1
    end

    test "rejects coordinates outside 0.0–1.0 range" do
      world = create_world()
      map = create_map(world)
      continent = create_continent(world)
      {:ok, pin} = Pins.create_pin(valid_pin_attrs(map, "continent", continent.id))

      assert {:error, _} = Pins.update_pin(pin, %{x: 2.0})
    end
  end

  # ---------------------------------------------------------------------------
  # delete_pin/1
  # ---------------------------------------------------------------------------

  describe "delete_pin/1" do
    test "deletes the pin but not the entity" do
      world = create_world()
      map = create_map(world)
      continent = create_continent(world)
      {:ok, pin} = Pins.create_pin(valid_pin_attrs(map, "continent", continent.id))

      assert {:ok, _} = Pins.delete_pin(pin)
      assert_raise Ecto.NoResultsError, fn -> Pins.get_pin!(pin.id) end
      assert Entities.get_continent!(continent.id).id == continent.id
    end
  end

  # ---------------------------------------------------------------------------
  # delete_pins_for_entity/2
  # ---------------------------------------------------------------------------

  describe "delete_pins_for_entity/2" do
    test "deletes all pins matching entity_type and entity_id" do
      world = create_world()
      map_a = create_map(world)
      map_b = create_map(world)
      continent = create_continent(world)

      {:ok, pin_a} = Pins.create_pin(valid_pin_attrs(map_a, "continent", continent.id))
      {:ok, pin_b} = Pins.create_pin(valid_pin_attrs(map_b, "continent", continent.id, %{x: 0.2}))

      Pins.delete_pins_for_entity("continent", continent.id)

      assert_raise Ecto.NoResultsError, fn -> Pins.get_pin!(pin_a.id) end
      assert_raise Ecto.NoResultsError, fn -> Pins.get_pin!(pin_b.id) end
    end

    test "does not delete pins for other entities" do
      world = create_world()
      map = create_map(world)
      continent_a = create_continent(world)
      continent_b = Entities.create_continent(world, %{name: "Borealia"}) |> elem(1)

      {:ok, pin_a} = Pins.create_pin(valid_pin_attrs(map, "continent", continent_a.id))
      {:ok, pin_b} = Pins.create_pin(valid_pin_attrs(map, "continent", continent_b.id, %{x: 0.2}))

      Pins.delete_pins_for_entity("continent", continent_a.id)

      assert_raise Ecto.NoResultsError, fn -> Pins.get_pin!(pin_a.id) end
      assert Pins.get_pin!(pin_b.id).id == pin_b.id
    end
  end

  # ---------------------------------------------------------------------------
  # get_entity_for_pin/1
  # ---------------------------------------------------------------------------

  describe "get_entity_for_pin/1" do
    test "returns the correct continent for a continent pin" do
      world = create_world()
      map = create_map(world)
      continent = create_continent(world)
      {:ok, pin} = Pins.create_pin(valid_pin_attrs(map, "continent", continent.id))

      entity = Pins.get_entity_for_pin(pin)
      assert entity.id == continent.id
      assert entity.name == "Aurelia"
    end

    test "returns the correct ocean for an ocean pin" do
      world = create_world()
      map = create_map(world)
      ocean = create_ocean(world)
      {:ok, pin} = Pins.create_pin(valid_pin_attrs(map, "ocean", ocean.id))

      entity = Pins.get_entity_for_pin(pin)
      assert entity.id == ocean.id
      assert entity.name == "Pacific"
    end
  end
end
