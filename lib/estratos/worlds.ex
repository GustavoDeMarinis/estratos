defmodule Estratos.Worlds do
  import Ecto.Query

  alias Estratos.Repo
  alias Estratos.Worlds.Map
  alias Estratos.Worlds.World

  # World

  def get_or_create_default_world do
    case Repo.one(from w in World, limit: 1) do
      nil ->
        %World{}
        |> World.changeset(%{name: "My World"})
        |> Repo.insert!()

      world ->
        world
    end
  end

  def update_world(%World{} = world, attrs) do
    world
    |> World.changeset(attrs)
    |> Repo.update()
  end

  # Maps

  def list_maps do
    Repo.all(from m in Map, order_by: [desc: m.id])
  end

  def get_map(id) do
    Repo.get(Map, id)
  end

  def create_map(attrs) do
    %Map{}
    |> Map.changeset(attrs)
    |> Repo.insert()
  end

  def update_map(%Map{} = map, attrs) do
    map
    |> Map.changeset(attrs)
    |> Repo.update()
  end

  def delete_map(%Map{} = map) do
    Repo.delete(map)
  end
end
