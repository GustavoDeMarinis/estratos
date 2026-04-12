defmodule Estratos.Entities.City do
  use Ecto.Schema
  import Ecto.Changeset

  alias Estratos.Worlds.World
  alias Estratos.Entities.Country

  schema "cities" do
    field :name, :string
    field :description, :string
    field :display_name, :string

    belongs_to :world, World
    belongs_to :country, Country

    timestamps()
  end

  @doc false
  def changeset(city, attrs) do
    city
    |> cast(attrs, [:name, :description, :display_name, :world_id, :country_id])
    |> validate_required([:name, :world_id])
  end
end
