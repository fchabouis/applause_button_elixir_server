defmodule ApplauseButtonElixirServer.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :url, :text
      add :claps, :integer
      add :source_ip, :string

      timestamps(type: :utc_datetime)
    end
  end
end
