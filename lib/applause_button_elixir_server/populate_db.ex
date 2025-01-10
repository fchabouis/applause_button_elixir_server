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
      req = Req.get!("https://raw.githubusercontent.com/fchabouis/applause_button_elixir_server/refs/heads/main/db/db.json")

      req.body()
      |> Jason.decode!()
      |> Enum.map(fn d -> PopulateDB.transform_data(d) end)
      |> Enum.map(fn r -> Page.changeset(%Page{}, r) end)
      |> Enum.each(fn c -> Repo.insert(c) end)
    end
end
