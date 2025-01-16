defmodule ApplauseButtonElixirServerWeb.PageController do
  use ApplauseButtonElixirServerWeb, :controller
  alias ApplauseButtonElixirServer.Repo
  alias ApplauseButtonElixirServer.Page
  require Logger


  def clean_url(page_url) do
    page_uri = URI.parse(page_url)
    String.replace(page_url, "#{page_uri.scheme}://", "", global: false)
  end

  def add_claps(%{"query_params" => %{"url" => page_url}} = conn, _params) do
    page_url = page_url |> clean_url()
    Logger.info("claps creation for #{page_url} from url parameter")
    add_claps_aux(conn, page_url)
  end

  def add_claps(conn, _params) do
    page_url = conn |> page_url_from_referer!()
    Logger.info("claps creation for #{page_url} from referer header")
    add_claps_aux(conn, page_url)
  end

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

    # user remote address is hidden by the fly.io proxy
    source_ip =
      case Plug.Conn.get_req_header(conn, "HTTP_FLY_CLIENT_IP") do
        [ip] ->
          ip

        v ->
          Logger.info(inspect(v))
          conn.remote_ip |> :inet_parse.ntoa() |> to_string()
      end

    updated_claps =
      Page
      |> Repo.get_by(url: page_url)
      |> increment_db_claps(source_ip, claps_to_add, page_url)

    text(conn, updated_claps)
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
    n = page_url
    |> clean_url()
    |> get_claps_from_db()

    text(conn, n)
  end

  def get_claps(conn, _) do
    page_url = conn
    |> page_url_from_referer!()

    Logger.info("get claps for #{page_url} from referer header")

    n = page_url |> get_claps_from_db()
    text(conn, n)
  end

  def get_claps_from_db(url) do
    case Page
         |> Repo.get_by(url: url) do
      nil -> 0
      %{claps: n} -> n
    end
  end
end
