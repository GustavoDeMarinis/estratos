defmodule Estratos.Relationships do
  import Ecto.Query

  alias Estratos.Repo
  alias Estratos.Relationships.Relationship

  def create_relationship(attrs) do
    %Relationship{}
    |> Relationship.changeset(attrs)
    |> Repo.insert()
  end

  def get_relationship!(id), do: Repo.get!(Relationship, id)

  def update_relationship(%Relationship{} = relationship, attrs) do
    relationship
    |> Relationship.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_relationship(%Relationship{} = relationship), do: Repo.delete(relationship)

  @doc """
  Returns all relationships where the given entity is either source or target,
  ordered by insertion time.
  """
  def list_relationships_for_entity(entity_type, entity_id) do
    Repo.all(
      from r in Relationship,
        where:
          (r.source_type == ^entity_type and r.source_id == ^entity_id) or
            (r.target_type == ^entity_type and r.target_id == ^entity_id),
        order_by: [asc: r.inserted_at]
    )
  end

  @doc """
  Bulk-deletes all relationships where the given entity is either source or target.
  Called before deleting an entity to avoid orphan relationship rows.
  """
  def delete_relationships_for_entity(entity_type, entity_id) do
    Repo.delete_all(
      from r in Relationship,
        where:
          (r.source_type == ^entity_type and r.source_id == ^entity_id) or
            (r.target_type == ^entity_type and r.target_id == ^entity_id)
    )
  end
end
