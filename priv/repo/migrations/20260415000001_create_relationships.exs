defmodule Estratos.Repo.Migrations.CreateRelationships do
  use Ecto.Migration

  def change do
    create table(:relationships) do
      add :source_type, :string, null: false
      add :source_id, :integer, null: false
      add :target_type, :string, null: false
      add :target_id, :integer, null: false
      add :type, :string, null: false
      add :attributes, :map, default: %{}

      timestamps()
    end

    create index(:relationships, [:source_type, :source_id])
    create index(:relationships, [:target_type, :target_id])
  end
end
