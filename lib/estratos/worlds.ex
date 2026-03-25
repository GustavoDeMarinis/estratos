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

  def get_world!(id), do: Repo.get!(World, id)

  def update_world(%World{} = world, attrs) do
    world
    |> World.changeset(attrs)
    |> Repo.update()
  end

  # Maps

  def list_maps_for_world(%World{} = world) do
    Repo.all(from m in Map, where: m.world_id == ^world.id, order_by: [desc: m.id])
  end

  def get_map(id), do: Repo.get(Map, id)

  def create_map(%World{} = world, attrs) do
    %Map{}
    |> Map.changeset(Elixir.Map.put(attrs, :world_id, world.id))
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
