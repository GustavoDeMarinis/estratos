defmodule Estratos.Entities do
  import Ecto.Query

  alias Estratos.Repo
  alias Estratos.Entities.Continent
  alias Estratos.Entities.Ocean
  alias Estratos.Entities.Country
  alias Estratos.Entities.City
  alias Estratos.Pins

  # ---------------------------------------------------------------------------
  # Continents
  # ---------------------------------------------------------------------------

  def create_continent(%{id: world_id}, attrs) do
    %Continent{}
    |> Continent.changeset(Map.put(attrs, :world_id, world_id))
    |> Repo.insert()
  end

  def get_continent!(id), do: Repo.get!(Continent, id)

  def update_continent(%Continent{} = continent, attrs) do
    continent
    |> Continent.changeset(attrs)
    |> Repo.update()
  end

  def delete_continent(%Continent{} = continent) do
    Pins.delete_pins_for_entity("continent", continent.id)
    Repo.delete(continent)
  end

  # ---------------------------------------------------------------------------
  # Oceans
  # ---------------------------------------------------------------------------

  def create_ocean(%{id: world_id}, attrs) do
    %Ocean{}
    |> Ocean.changeset(Map.put(attrs, :world_id, world_id))
    |> Repo.insert()
  end

  def get_ocean!(id), do: Repo.get!(Ocean, id)

  def update_ocean(%Ocean{} = ocean, attrs) do
    ocean
    |> Ocean.changeset(attrs)
    |> Repo.update()
  end

  def delete_ocean(%Ocean{} = ocean) do
    Pins.delete_pins_for_entity("ocean", ocean.id)
    Repo.delete(ocean)
  end

  # ---------------------------------------------------------------------------
  # Continents list (used for parent dropdowns)
  # ---------------------------------------------------------------------------

  def list_continents_for_world(%{id: world_id}) do
    Repo.all(from c in Continent, where: c.world_id == ^world_id, order_by: [asc: c.name])
  end

  # ---------------------------------------------------------------------------
  # Countries
  # ---------------------------------------------------------------------------

  def create_country(%{id: world_id}, attrs) do
    %Country{}
    |> Country.changeset(Map.put(attrs, :world_id, world_id))
    |> Repo.insert()
  end

  def get_country!(id), do: Repo.get!(Country, id)

  def update_country(%Country{} = country, attrs) do
    country
    |> Country.changeset(attrs)
    |> Repo.update()
  end

  def delete_country(%Country{} = country) do
    Pins.delete_pins_for_entity("country", country.id)
    Repo.delete(country)
  end

  def list_countries_for_world(%{id: world_id}) do
    Repo.all(from c in Country, where: c.world_id == ^world_id, order_by: [asc: c.name])
  end

  # ---------------------------------------------------------------------------
  # Cities
  # ---------------------------------------------------------------------------

  def create_city(%{id: world_id}, attrs) do
    %City{}
    |> City.changeset(Map.put(attrs, :world_id, world_id))
    |> Repo.insert()
  end

  def get_city!(id), do: Repo.get!(City, id)

  def update_city(%City{} = city, attrs) do
    city
    |> City.changeset(attrs)
    |> Repo.update()
  end

  def delete_city(%City{} = city) do
    Pins.delete_pins_for_entity("city", city.id)
    Repo.delete(city)
  end

  def list_cities_for_world(%{id: world_id}) do
    Repo.all(from c in City, where: c.world_id == ^world_id, order_by: [asc: c.name])
  end
end
