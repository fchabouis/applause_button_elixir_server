defmodule ApplauseButtonElixirServer.ClapCountRequest do
  use Ecto.Schema

  schema "clap_count_requests" do
    belongs_to :page, ApplauseButtonElixirServer.Page
    field :source_ip, :string
    timestamps(type: :utc_datetime)
  end
end
