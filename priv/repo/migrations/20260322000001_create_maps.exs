defmodule Estratos.Repo.Migrations.CreateMaps do
  use Ecto.Migration

  def change do
    create table(:maps) do
      add :name, :string, null: false
      add :image_path, :string, null: false
      add :image_width, :integer
      add :image_height, :integer

      timestamps()
    end
  end
end
