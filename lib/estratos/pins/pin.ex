defmodule Estratos.Pins.Pin do
  use Ecto.Schema
  import Ecto.Changeset

  alias Estratos.Worlds.Map

  schema "pins" do
    field :entity_type, :string
    field :entity_id, :integer

    belongs_to :map, Map

    field :x, :float
    field :y, :float

    timestamps()
  end

  @doc false
  def changeset(pin, attrs) do
    pin
    |> cast(attrs, [:entity_type, :entity_id, :map_id, :x, :y])
    |> validate_required([:entity_type, :entity_id, :map_id, :x, :y])
    |> validate_inclusion(:entity_type, ["continent", "ocean"])
    |> validate_number(:x, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> validate_number(:y, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
  end
end
