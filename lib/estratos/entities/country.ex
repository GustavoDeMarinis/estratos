defmodule Estratos.Entities.Country do
  use Ecto.Schema
  import Ecto.Changeset

  alias Estratos.Worlds.World
  alias Estratos.Entities.Continent

  schema "countries" do
    field :name, :string
    field :description, :string
    field :display_name, :string

    belongs_to :world, World
    belongs_to :continent, Continent

    timestamps()
  end

  @doc false
  def changeset(country, attrs) do
    country
    |> cast(attrs, [:name, :description, :display_name, :world_id, :continent_id])
    |> validate_required([:name, :world_id])
  end
end
