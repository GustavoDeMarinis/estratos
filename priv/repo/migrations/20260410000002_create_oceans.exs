defmodule Estratos.Repo.Migrations.CreateOceans do
  use Ecto.Migration

  def change do
    create table(:oceans) do
      add :name, :string, null: false
      add :description, :string
      add :display_name, :string
      add :world_id, references(:worlds, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:oceans, [:world_id])
  end
end
