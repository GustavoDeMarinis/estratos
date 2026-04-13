defmodule Estratos.Pins do
  import Ecto.Query

  alias Estratos.Repo
  alias Estratos.Pins.Pin

  def create_pin(attrs) do
    %Pin{}
    |> Pin.changeset(attrs)
    |> Repo.insert()
  end

  def get_pin!(id), do: Repo.get!(Pin, id)

  def list_pins_for_map(%{id: map_id}) do
    Repo.all(from p in Pin, where: p.map_id == ^map_id, order_by: [asc: p.inserted_at])
  end

  def update_pin(%Pin{} = pin, attrs) do
    pin
    |> Pin.changeset(attrs)
    |> Repo.update()
  end

  def delete_pin(%Pin{} = pin), do: Repo.delete(pin)

  def delete_pins_for_entity(entity_type, entity_id) do
    Repo.delete_all(
      from p in Pin,
        where: p.entity_type == ^entity_type and p.entity_id == ^entity_id
    )
  end

  def get_entity_for_pin(%Pin{entity_type: "continent", entity_id: id}) do
    Estratos.Entities.get_continent!(id)
  end

  def get_entity_for_pin(%Pin{entity_type: "ocean", entity_id: id}) do
    Estratos.Entities.get_ocean!(id)
  end

  def get_entity_for_pin(%Pin{entity_type: "country", entity_id: id}) do
    Estratos.Entities.get_country!(id)
  end

  def get_entity_for_pin(%Pin{entity_type: "city", entity_id: id}) do
    Estratos.Entities.get_city!(id)
  end
end
