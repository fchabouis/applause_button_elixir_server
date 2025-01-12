defmodule ApplauseButtonElixirServerWeb.PageController do
  use ApplauseButtonElixirServerWeb, :controller
  alias ApplauseButtonElixirServer.Repo
  alias ApplauseButtonElixirServer.Page
  require Logger

  def clean_url(page_url) do
    page_uri = URI.parse(page_url)
    String.replace(page_url, "#{page_uri.scheme}://", "", global: false)
  end

  def add_claps(conn, _params) do
    %{"url" => page_url} = conn.query_params
    page_url = clean_url(page_url)
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    [claps_to_add, _js_version] = body |> String.replace("\"", "") |> String.split(",")
    claps_to_add = String.to_integer(claps_to_add)
    source_ip = to_string(:inet_parse.ntoa(conn.remote_ip))

    updated_claps =
      Page
      |> Repo.get_by(url: page_url)
      |> increment_db_claps(source_ip, claps_to_add, page_url)

    text(conn, updated_claps)
  end

  def increment_db_claps(
        %Page{claps: n, source_ip: source_ip},
        source_ip,
        _claps_to_add,
        page_url
      ) do
    Logger.info(
      "claps from #{source_ip} not recorded for #{page_url} because last clap was from the same ip"
    )

    # no db insertion as the current ip address is the same as the previously recorded one
    n
  end

  def increment_db_claps(
        %Page{claps: n, source_ip: _previous_source_ip} = page,
        source_ip,
        claps_to_add,
        page_url
      ) do
    Logger.info("claps from #{source_ip} recorded for #{page_url}")

    updated_claps = n + claps_to_add
    page
    |> Ecto.Changeset.change(%{claps: updated_claps, source_ip: source_ip})
    |> Repo.update!()
    updated_claps
  end

  def increment_db_claps(nil, source_ip, claps_to_add, page_url) do
    Logger.info("claps from #{source_ip} created for #{page_url}")

    %Page{claps: claps_to_add, source_ip: source_ip, url: page_url}
    |> Repo.insert()

    claps_to_add
  end

  def get_claps(conn, %{"url" => url}) do
    url = clean_url(url)

    n =
      case Page
           |> Repo.get_by(url: url) do
        nil -> 0
        %{claps: n} -> n
      end

    text(conn, n)
  end
end
