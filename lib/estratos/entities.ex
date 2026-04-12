defmodule Estratos.Entities do
  alias Estratos.Repo
  alias Estratos.Entities.Continent
  alias Estratos.Entities.Ocean
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
end
