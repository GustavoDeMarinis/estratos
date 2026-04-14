defmodule Estratos.Repo.Migrations.CreateCountries do
  use Ecto.Migration

  def change do
    create table(:countries) do
      add :name, :string, null: false
      add :description, :string
      add :display_name, :string
      add :world_id, references(:worlds, on_delete: :nothing), null: false
      add :continent_id, references(:continents, on_delete: :nilify_all)

      timestamps()
    end

    create index(:countries, [:world_id])
    create index(:countries, [:continent_id])
  end
end
