defmodule Estratos.Worlds.World do
  use Ecto.Schema
  import Ecto.Changeset

  alias Estratos.Worlds.Map

  schema "worlds" do
    field :name, :string
    field :description, :string

    has_many :maps, Map

    timestamps()
  end

  @doc false
  def changeset(world, attrs) do
    world
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
