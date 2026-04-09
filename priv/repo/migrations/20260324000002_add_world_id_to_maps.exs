defmodule Estratos.Repo.Migrations.AddWorldIdToMaps do
  use Ecto.Migration

  def change do
    alter table(:maps) do
      add :world_id, references(:worlds, on_delete: :nothing)
    end
  end
end
