defmodule Estratos.Repo.Migrations.CreateContinents do
  use Ecto.Migration

  def change do
    create table(:continents) do
      add :name, :string, null: false
      add :description, :string
      add :display_name, :string
      add :world_id, references(:worlds, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:continents, [:world_id])
  end
end
