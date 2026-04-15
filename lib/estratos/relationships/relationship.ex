defmodule Estratos.Relationships.Relationship do
  use Ecto.Schema
  import Ecto.Changeset

  alias Estratos.EntityTypes

  schema "relationships" do
    field :source_type, :string
    field :source_id, :integer
    field :target_type, :string
    field :target_id, :integer
    field :type, :string
    field :attributes, :map, default: %{}

    timestamps()
  end

  @doc false
  def changeset(relationship, attrs) do
    valid_slugs = EntityTypes.list_types() |> Enum.map(& &1.slug)

    relationship
    |> cast(attrs, [:source_type, :source_id, :target_type, :target_id, :type, :attributes])
    |> validate_required([:source_type, :source_id, :target_type, :target_id, :type])
    |> validate_inclusion(:source_type, valid_slugs)
    |> validate_inclusion(:target_type, valid_slugs)
    |> validate_not_self_relationship()
  end

  @doc "Changeset for updates — only type and attributes are mutable."
  def update_changeset(relationship, attrs) do
    relationship
    |> cast(attrs, [:type, :attributes])
    |> validate_required([:type])
  end

  defp validate_not_self_relationship(changeset) do
    source_type = get_field(changeset, :source_type)
    source_id = get_field(changeset, :source_id)
    target_type = get_field(changeset, :target_type)
    target_id = get_field(changeset, :target_id)

    if source_type && source_id && target_type && target_id &&
         source_type == target_type && source_id == target_id do
      add_error(changeset, :target_id, "cannot relate an entity to itself")
    else
      changeset
    end
  end
end
