defmodule ApplauseButtonElixirServerWeb.PageController do
  use ApplauseButtonElixirServerWeb, :controller
  alias ApplauseButtonElixirServer.Repo
  alias ApplauseButtonElixirServer.Page
  alias ApplauseButtonElixirServer.ClapCountRequest
  require Logger

  @doc """
  Remove the scheme part of the url.

  iex> clean_url("https://applause.chabouis.fr")
  "applause.chabouis.fr"

  iex> clean_url("HTTP://applause.chabouis.fr")
  "applause.chabouis.fr"
  """
  def clean_url(page_url) do
    page_uri = URI.parse(page_url)
    String.replace(page_url, ~r/^#{page_uri.scheme}:\/\//i, "", global: false)
  end

  @spec add_claps(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def add_claps(%{query_params: %{"url" => page_url}} = conn, _params) do
    page_url = page_url |> clean_url()
    Logger.info("claps creation for #{page_url} from url parameter")
    add_claps_aux(conn, page_url)
  end

  def add_claps(conn, _params) do
    page_url = conn |> page_url_from_referer!()
    Logger.info("claps creation for #{page_url} from referer header")
    add_claps_aux(conn, page_url)
  end

  @doc """
  Return a clean url from a conn referer.

  iex>page_url_from_referer!(%Plug.Conn{req_headers: [{"referer", "https://exemple.com"}]})
  "exemple.com"
  """
  def page_url_from_referer!(conn) do
    case conn |> get_req_header("referer") do
      [page_url] -> clean_url(page_url)
      _ -> raise Plug.BadRequestError
    end
  end

  def add_claps_aux(conn, page_url) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    [claps_to_add, _js_version] = body |> String.replace("\"", "") |> String.split(",")
    claps_to_add = String.to_integer(claps_to_add)

    source_ip = get_source_ip(conn)

    updated_claps =
      Page
      |> Repo.get_by(url: page_url)
      |> increment_db_claps(source_ip, claps_to_add, page_url)

    text(conn, updated_claps)
  end

  def get_source_ip(conn) do
    # user remote address is hidden by the fly.io proxy
    case Plug.Conn.get_req_header(conn, "HTTP_FLY_CLIENT_IP") do
      [ip] ->
        ip

      v ->
        Logger.info(inspect(v))
        conn.remote_ip |> :inet_parse.ntoa() |> to_string()
    end
  end

  # functionnality deactivated for the moment, not sure it is useful
  # def increment_db_claps(
  #       %Page{claps: n, source_ip: source_ip},
  #       source_ip,
  #       _claps_to_add,
  #       page_url
  #     ) do
  #   Logger.info(
  #     "claps from #{source_ip} not recorded for #{page_url} because last clap was from the same ip"
  #   )

  #   # no db insertion as the current ip address is the same as the previously recorded one
  #   n
  # end

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

  def get_claps(conn, %{"url" => page_url}) do
    Logger.info("get claps for #{page_url} from url parameter")

    %{claps: n, page_id: page_id} =
      page_url
      |> clean_url()
      |> get_claps_from_db()

    log_clap_request(page_id, conn)

    text(conn, n)
  end

  def get_claps(conn, _) do
    page_url =
      conn
      |> page_url_from_referer!()

    Logger.info("get claps for #{page_url} from referer header")

    %{claps: n, page_id: page_id} = page_url |> get_claps_from_db()
    log_clap_request(page_id, conn)

    text(conn, n)
  end

  def get_claps_from_db(url) do
    case Page
         |> Repo.get_by(url: url) do
      nil -> %{claps: 0, page_id: nil}
      %{claps: n, id: page_id} -> %{claps: n, page_id: page_id}
    end
  end

  def log_clap_request(nil, _conn), do: nil

  def log_clap_request(page_id, conn) do
    source_ip = get_source_ip(conn)

    %ClapCountRequest{page_id: page_id, source_ip: source_ip}
    |> Repo.insert()
  end
end
