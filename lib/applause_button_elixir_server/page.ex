defmodule ApplauseButtonElixirServer.Page do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :url, :string
    field :claps, :integer
    field :source_ip, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:url, :claps, :source_ip])
    |> validate_required([:url, :claps, :source_ip])
  end
end
