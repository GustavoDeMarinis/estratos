defmodule Estratos.Worlds.Map do
  use Ecto.Schema
  import Ecto.Changeset

  schema "maps" do
    field :name, :string
    field :image_path, :string
    field :image_width, :integer
    field :image_height, :integer

    timestamps()
  end

  @doc false
  def changeset(map, attrs) do
    map
    |> cast(attrs, [:name, :image_path, :image_width, :image_height])
    |> validate_required([:name, :image_path])
  end
end
