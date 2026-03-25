defmodule Estratos.Worlds.Map do
  use Ecto.Schema
  import Ecto.Changeset

  alias Estratos.Worlds.World

  schema "maps" do
    field :name, :string
    field :image_path, :string
    field :image_width, :integer
    field :image_height, :integer

    belongs_to :world, World

    timestamps()
  end

  @doc false
  def changeset(map, attrs) do
    map
    |> cast(attrs, [:name, :image_path, :image_width, :image_height, :world_id])
    |> validate_required([:name, :image_path])
  end
end
