defmodule Estratos.Repo.Migrations.CreateCities do
  use Ecto.Migration

  def change do
    create table(:cities) do
      add :name, :string, null: false
      add :description, :string
      add :display_name, :string
      add :world_id, references(:worlds, on_delete: :nothing), null: false
      add :country_id, references(:countries, on_delete: :nilify_all)

      timestamps()
    end

    create index(:cities, [:world_id])
    create index(:cities, [:country_id])
  end
end
