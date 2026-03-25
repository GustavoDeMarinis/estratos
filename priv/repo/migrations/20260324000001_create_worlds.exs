defmodule Estratos.Repo.Migrations.CreateWorlds do
  use Ecto.Migration

  def change do
    create table(:worlds) do
      add :name, :string, null: false
      add :description, :string

      timestamps()
    end
  end
end
