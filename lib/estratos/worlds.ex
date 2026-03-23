defmodule Estratos.Worlds do
  alias Estratos.Repo
  alias Estratos.Worlds.Map

  def list_maps do
    Repo.all(Map)
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
