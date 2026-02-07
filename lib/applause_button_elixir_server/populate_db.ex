defmodule PopulateDB do
  alias ApplauseButtonElixirServer.Repo
  alias ApplauseButtonElixirServer.Page

  @json_url "https://raw.githubusercontent.com/fchabouis/applause_button_elixir_server/refs/heads/main/pages_202602071738.json"

  @doc """
  Import pages from the GitHub JSON export.

  Usage: PopulateDB.run()
  """
  def run do
    Req.get!(@json_url).body
    |> Map.fetch!("pages")
    |> Enum.each(fn row ->
      %Page{}
      |> Page.changeset(%{
        "url" => row["url"],
        "claps" => row["claps"],
        "source_ip" => row["source_ip"]
      })
      |> Repo.insert!()
    end)
  end
end
