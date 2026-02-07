defmodule PopulateDB do
  alias ApplauseButtonElixirServer.Repo
  alias ApplauseButtonElixirServer.Page

  @doc """
  Import pages from a DBeaver JSON export file.

  Usage: PopulateDB.run("/path/to/pages_export.json")
  """
  def run(file_path) do
    file_path
    |> File.read!()
    |> Jason.decode!()
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
