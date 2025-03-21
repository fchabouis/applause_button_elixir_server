defmodule ApplauseButtonElixirServer.Repo.Migrations.CreateClapCountRequests do
  use Ecto.Migration

  def change do
    create table(:clap_count_requests) do
      add :page_id, references(:pages), null: false
      add :source_ip, :string

      timestamps(type: :utc_datetime)
    end

    create index(:clap_count_requests, [:page_id])
    create index(:clap_count_requests, [:inserted_at])
  end
end
