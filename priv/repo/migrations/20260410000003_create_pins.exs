defmodule Estratos.Repo.Migrations.CreatePins do
  use Ecto.Migration

  def change do
    create table(:pins) do
      add :entity_type, :string, null: false
      add :entity_id, :integer, null: false
      add :map_id, references(:maps, on_delete: :nothing), null: false
      add :x, :float, null: false
      add :y, :float, null: false

      timestamps()
    end

    create index(:pins, [:entity_type, :entity_id])
    create index(:pins, [:map_id])
  end
end
