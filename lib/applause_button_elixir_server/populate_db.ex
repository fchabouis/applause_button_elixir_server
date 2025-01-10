defmodule PopulateDB do
  alias ApplauseButtonElixirServer.Repo
  alias ApplauseButtonElixirServer.Page

  def transform_data(%{
    "Item" => %{
      "claps" => %{"N" => claps},
      "sourceIp" => %{"S" => source_ip},
      "url" => %{"S" => url}
    }}) do
      %{"url" => url, "claps" => claps, "source_ip" => source_ip}
    end

    def transform_data(%{
    "Item" => %{
      "claps" => %{"N" => claps},
      "url" => %{"S" => url}
    }}) do
      %{"url" => url, "claps" => claps, "source_ip" => nil}
    end

    def run() do
      "db/db.json"
      |> File.read!()
      |> Jason.decode!()
      |> Enum.map(fn d -> PopulateDB.transform_data(d) end)
      |> Enum.map(fn r -> Page.changeset(%Page{}, r) end)
      |> Enum.each(fn c -> Repo.insert(c) end)
    end
end
