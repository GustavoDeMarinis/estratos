defmodule Estratos.EntitiesTest do
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

  # ---------------------------------------------------------------------------
  # Continents
  # ---------------------------------------------------------------------------

  describe "create_continent/2" do
    test "creates a continent with valid attrs" do
      world = create_world()
      assert {:ok, continent} = Entities.create_continent(world, %{name: "Aurelia"})
      assert continent.name == "Aurelia"
      assert continent.world_id == world.id
    end

    test "creates a continent with all fields" do
      world = create_world()

      assert {:ok, continent} =
               Entities.create_continent(world, %{
                 name: "Aurelia",
                 description: "A vast continent",
                 display_name: "The Golden Lands"
               })

      assert continent.description == "A vast continent"
      assert continent.display_name == "The Golden Lands"
    end

    test "returns error changeset when name is missing" do
      world = create_world()
      assert {:error, changeset} = Entities.create_continent(world, %{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update_continent/2" do
    test "updates name and description" do
      world = create_world()
      {:ok, continent} = Entities.create_continent(world, %{name: "Aurelia"})

      assert {:ok, updated} =
               Entities.update_continent(continent, %{
                 name: "New Aurelia",
                 description: "Renamed"
               })

      assert updated.name == "New Aurelia"
      assert updated.description == "Renamed"
    end

    test "returns error changeset when name is cleared" do
      world = create_world()
      {:ok, continent} = Entities.create_continent(world, %{name: "Aurelia"})
      assert {:error, changeset} = Entities.update_continent(continent, %{name: nil})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "delete_continent/1" do
    test "deletes the continent from DB" do
      world = create_world()
      {:ok, continent} = Entities.create_continent(world, %{name: "Aurelia"})
      assert {:ok, _} = Entities.delete_continent(continent)
      assert_raise Ecto.NoResultsError, fn -> Entities.get_continent!(continent.id) end
    end

    test "also deletes all pins referencing that continent" do
      world = create_world()
      map = create_map(world)
      {:ok, continent} = Entities.create_continent(world, %{name: "Aurelia"})

      {:ok, pin} =
        Pins.create_pin(%{
          entity_type: "continent",
          entity_id: continent.id,
          map_id: map.id,
          x: 0.5,
          y: 0.5
        })

      Entities.delete_continent(continent)
      assert_raise Ecto.NoResultsError, fn -> Pins.get_pin!(pin.id) end
    end
  end

  # ---------------------------------------------------------------------------
  # Oceans
  # ---------------------------------------------------------------------------

  describe "create_ocean/2" do
    test "creates an ocean with valid attrs" do
      world = create_world()
      assert {:ok, ocean} = Entities.create_ocean(world, %{name: "Pacific"})
      assert ocean.name == "Pacific"
      assert ocean.world_id == world.id
    end

    test "returns error changeset when name is missing" do
      world = create_world()
      assert {:error, changeset} = Entities.create_ocean(world, %{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update_ocean/2" do
    test "updates name and description" do
      world = create_world()
      {:ok, ocean} = Entities.create_ocean(world, %{name: "Pacific"})
      assert {:ok, updated} = Entities.update_ocean(ocean, %{name: "Atlantic"})
      assert updated.name == "Atlantic"
    end

    test "returns error changeset when name is cleared" do
      world = create_world()
      {:ok, ocean} = Entities.create_ocean(world, %{name: "Pacific"})
      assert {:error, changeset} = Entities.update_ocean(ocean, %{name: nil})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "delete_ocean/1" do
    test "deletes the ocean from DB" do
      world = create_world()
      {:ok, ocean} = Entities.create_ocean(world, %{name: "Pacific"})
      assert {:ok, _} = Entities.delete_ocean(ocean)
      assert_raise Ecto.NoResultsError, fn -> Entities.get_ocean!(ocean.id) end
    end

    test "also deletes all pins referencing that ocean" do
      world = create_world()
      map = create_map(world)
      {:ok, ocean} = Entities.create_ocean(world, %{name: "Pacific"})

      {:ok, pin} =
        Pins.create_pin(%{
          entity_type: "ocean",
          entity_id: ocean.id,
          map_id: map.id,
          x: 0.3,
          y: 0.7
        })

      Entities.delete_ocean(ocean)
      assert_raise Ecto.NoResultsError, fn -> Pins.get_pin!(pin.id) end
    end
  end
end
