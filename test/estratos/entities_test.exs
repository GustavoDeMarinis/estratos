defmodule Estratos.EntitiesTest do
  use Estratos.DataCase, async: true

  alias Estratos.Entities
  alias Estratos.Pins
  alias Estratos.Repo
  alias Estratos.Entities.City
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

  # ---------------------------------------------------------------------------
  # list_continents_for_world/1
  # ---------------------------------------------------------------------------

  describe "list_continents_for_world/1" do
    test "returns only continents for the given world" do
      world_a = create_world()
      world_b = create_world()
      {:ok, c1} = Entities.create_continent(world_a, %{name: "Aurelia"})
      {:ok, c2} = Entities.create_continent(world_a, %{name: "Borealia"})
      {:ok, _} = Entities.create_continent(world_b, %{name: "Otheria"})

      result = Entities.list_continents_for_world(world_a)
      ids = Enum.map(result, & &1.id)
      assert c1.id in ids
      assert c2.id in ids
      assert length(result) == 2
    end

    test "returns continents ordered by name" do
      world = create_world()
      {:ok, _} = Entities.create_continent(world, %{name: "Zephyria"})
      {:ok, _} = Entities.create_continent(world, %{name: "Aurelia"})

      result = Entities.list_continents_for_world(world)
      assert Enum.map(result, & &1.name) == ["Aurelia", "Zephyria"]
    end
  end

  # ---------------------------------------------------------------------------
  # Countries
  # ---------------------------------------------------------------------------

  describe "create_country/2" do
    test "creates a country with valid attrs" do
      world = create_world()
      assert {:ok, country} = Entities.create_country(world, %{name: "Valdoria"})
      assert country.name == "Valdoria"
      assert country.world_id == world.id
    end

    test "creates a country with a continent parent" do
      world = create_world()
      {:ok, continent} = Entities.create_continent(world, %{name: "Aurelia"})
      assert {:ok, country} = Entities.create_country(world, %{name: "Valdoria", continent_id: continent.id})
      assert country.continent_id == continent.id
    end

    test "creates a country without a continent parent" do
      world = create_world()
      assert {:ok, country} = Entities.create_country(world, %{name: "Valdoria"})
      assert is_nil(country.continent_id)
    end

    test "returns error changeset when name is missing" do
      world = create_world()
      assert {:error, changeset} = Entities.create_country(world, %{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update_country/2" do
    test "updates name and description" do
      world = create_world()
      {:ok, country} = Entities.create_country(world, %{name: "Valdoria"})
      assert {:ok, updated} = Entities.update_country(country, %{name: "New Valdoria", description: "Updated"})
      assert updated.name == "New Valdoria"
      assert updated.description == "Updated"
    end

    test "updates continent_id" do
      world = create_world()
      {:ok, continent} = Entities.create_continent(world, %{name: "Aurelia"})
      {:ok, country} = Entities.create_country(world, %{name: "Valdoria"})
      assert {:ok, updated} = Entities.update_country(country, %{continent_id: continent.id})
      assert updated.continent_id == continent.id
    end

    test "returns error changeset when name is cleared" do
      world = create_world()
      {:ok, country} = Entities.create_country(world, %{name: "Valdoria"})
      assert {:error, changeset} = Entities.update_country(country, %{name: nil})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "delete_country/1" do
    test "deletes the country from DB" do
      world = create_world()
      {:ok, country} = Entities.create_country(world, %{name: "Valdoria"})
      assert {:ok, _} = Entities.delete_country(country)
      assert_raise Ecto.NoResultsError, fn -> Entities.get_country!(country.id) end
    end

    test "also deletes all pins referencing that country" do
      world = create_world()
      map = create_map(world)
      {:ok, country} = Entities.create_country(world, %{name: "Valdoria"})
      {:ok, pin} = Pins.create_pin(%{entity_type: "country", entity_id: country.id, map_id: map.id, x: 0.5, y: 0.5})
      Entities.delete_country(country)
      assert_raise Ecto.NoResultsError, fn -> Pins.get_pin!(pin.id) end
    end

    test "does NOT delete cities that reference it" do
      world = create_world()
      {:ok, country} = Entities.create_country(world, %{name: "Valdoria"})
      {:ok, city} = Entities.create_city(world, %{name: "Valdo City", country_id: country.id})
      Entities.delete_country(country)
      reloaded = Entities.get_city!(city.id)
      assert is_nil(reloaded.country_id)
    end
  end

  describe "list_countries_for_world/1" do
    test "returns only countries for the given world" do
      world_a = create_world()
      world_b = create_world()
      {:ok, c1} = Entities.create_country(world_a, %{name: "Valdoria"})
      {:ok, c2} = Entities.create_country(world_a, %{name: "Arkon"})
      {:ok, _} = Entities.create_country(world_b, %{name: "Otheria"})

      result = Entities.list_countries_for_world(world_a)
      ids = Enum.map(result, & &1.id)
      assert c1.id in ids
      assert c2.id in ids
      assert length(result) == 2
    end

    test "returns countries ordered by name" do
      world = create_world()
      {:ok, _} = Entities.create_country(world, %{name: "Zora"})
      {:ok, _} = Entities.create_country(world, %{name: "Arkon"})
      result = Entities.list_countries_for_world(world)
      assert Enum.map(result, & &1.name) == ["Arkon", "Zora"]
    end
  end

  # ---------------------------------------------------------------------------
  # Cities
  # ---------------------------------------------------------------------------

  describe "create_city/2" do
    test "creates a city with valid attrs" do
      world = create_world()
      assert {:ok, city} = Entities.create_city(world, %{name: "Valheim"})
      assert city.name == "Valheim"
      assert city.world_id == world.id
    end

    test "creates a city with a country parent" do
      world = create_world()
      {:ok, country} = Entities.create_country(world, %{name: "Valdoria"})
      assert {:ok, city} = Entities.create_city(world, %{name: "Valheim", country_id: country.id})
      assert city.country_id == country.id
    end

    test "creates a city without a country parent" do
      world = create_world()
      assert {:ok, city} = Entities.create_city(world, %{name: "Valheim"})
      assert is_nil(city.country_id)
    end

    test "returns error changeset when name is missing" do
      world = create_world()
      assert {:error, changeset} = Entities.create_city(world, %{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update_city/2" do
    test "updates name and description" do
      world = create_world()
      {:ok, city} = Entities.create_city(world, %{name: "Valheim"})
      assert {:ok, updated} = Entities.update_city(city, %{name: "New Valheim", description: "Capital"})
      assert updated.name == "New Valheim"
      assert updated.description == "Capital"
    end

    test "updates country_id" do
      world = create_world()
      {:ok, country} = Entities.create_country(world, %{name: "Valdoria"})
      {:ok, city} = Entities.create_city(world, %{name: "Valheim"})
      assert {:ok, updated} = Entities.update_city(city, %{country_id: country.id})
      assert updated.country_id == country.id
    end

    test "returns error changeset when name is cleared" do
      world = create_world()
      {:ok, city} = Entities.create_city(world, %{name: "Valheim"})
      assert {:error, changeset} = Entities.update_city(city, %{name: nil})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "delete_city/1" do
    test "deletes the city from DB" do
      world = create_world()
      {:ok, city} = Entities.create_city(world, %{name: "Valheim"})
      assert {:ok, _} = Entities.delete_city(city)
      assert_raise Ecto.NoResultsError, fn -> Entities.get_city!(city.id) end
    end

    test "also deletes all pins referencing that city" do
      world = create_world()
      map = create_map(world)
      {:ok, city} = Entities.create_city(world, %{name: "Valheim"})
      {:ok, pin} = Pins.create_pin(%{entity_type: "city", entity_id: city.id, map_id: map.id, x: 0.5, y: 0.5})
      Entities.delete_city(city)
      assert_raise Ecto.NoResultsError, fn -> Pins.get_pin!(pin.id) end
    end
  end

  describe "list_cities_for_world/1" do
    test "returns only cities for the given world" do
      world_a = create_world()
      world_b = create_world()
      {:ok, c1} = Entities.create_city(world_a, %{name: "Valheim"})
      {:ok, c2} = Entities.create_city(world_a, %{name: "Stoneport"})
      {:ok, _} = Entities.create_city(world_b, %{name: "Otherville"})

      result = Entities.list_cities_for_world(world_a)
      ids = Enum.map(result, & &1.id)
      assert c1.id in ids
      assert c2.id in ids
      assert length(result) == 2
    end

    test "returns cities ordered by name" do
      world = create_world()
      {:ok, _} = Entities.create_city(world, %{name: "Zorheim"})
      {:ok, _} = Entities.create_city(world, %{name: "Ankport"})
      result = Entities.list_cities_for_world(world)
      assert Enum.map(result, & &1.name) == ["Ankport", "Zorheim"]
    end
  end

  # ---------------------------------------------------------------------------
  # Nilify on parent deletion
  # ---------------------------------------------------------------------------

  describe "on_delete: :nilify_all behavior" do
    test "deleting a continent nilifies continent_id on its countries" do
      world = create_world()
      {:ok, continent} = Entities.create_continent(world, %{name: "Aurelia"})
      {:ok, country} = Entities.create_country(world, %{name: "Valdoria", continent_id: continent.id})
      Entities.delete_continent(continent)
      reloaded = Entities.get_country!(country.id)
      assert is_nil(reloaded.continent_id)
    end

    test "deleting a country nilifies country_id on its cities" do
      world = create_world()
      {:ok, country} = Entities.create_country(world, %{name: "Valdoria"})
      {:ok, city} = Entities.create_city(world, %{name: "Valheim", country_id: country.id})
      Entities.delete_country(country)
      reloaded = Repo.get!(City, city.id)
      assert is_nil(reloaded.country_id)
    end
  end
end
