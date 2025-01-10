defmodule ApplauseButtonElixirServerWeb.PageController do
  use ApplauseButtonElixirServerWeb, :controller
  alias ApplauseButtonElixirServer.Repo
  alias ApplauseButtonElixirServer.Page

  def add_claps(conn, _params) do
    %{"url" => page_url} = conn.query_params
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
        _page_url
      ) do
    # no db insertion as the current ip address is the same as the previously recorded one
    n
  end

  def increment_db_claps(
        %Page{claps: n, source_ip: _previous_source_ip} = page,
        source_ip,
        claps_to_add,
        _page_url
      ) do
    updated_claps = n + claps_to_add
    Ecto.Changeset.change(page, %{claps: updated_claps, source_ip: source_ip})
    updated_claps
  end

  def increment_db_claps(nil, source_ip, claps_to_add, page_url) do
    %Page{claps: claps_to_add, source_ip: source_ip, url: page_url}
    |> Repo.insert()

    claps_to_add
  end

  def get_claps(conn, %{"url" => url}) do
    n =
      case Page
           |> Repo.get_by(url: url) do
        nil -> 0
        %{claps: n} -> n
      end

    text(conn, n)
  end
end
