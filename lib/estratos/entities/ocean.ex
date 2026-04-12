defmodule Estratos.Entities.Ocean do
  use Ecto.Schema
  import Ecto.Changeset

  alias Estratos.Worlds.World

  schema "oceans" do
    field :name, :string
    field :description, :string
    field :display_name, :string

    belongs_to :world, World

    timestamps()
  end

  @doc false
  def changeset(ocean, attrs) do
    ocean
    |> cast(attrs, [:name, :description, :display_name, :world_id])
    |> validate_required([:name, :world_id])
  end
end
