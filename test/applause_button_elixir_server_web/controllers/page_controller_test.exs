defmodule ApplauseButtonElixirServerWeb.PageControllerTest do
  # alias Phoenix.LiveView.Plug
  use ApplauseButtonElixirServerWeb.ConnCase
  alias ApplauseButtonElixirServer.ClapCountRequest
  alias ApplauseButtonElixirServer.Repo

  doctest ApplauseButtonElixirServerWeb.PageController, import: true

  test "post clap", %{conn: conn} do
    url = "https://exemple.com/blog-post"

    conn_1 =
      conn
      |> put_req_header("content-type", "text/plain")
      |> post(~p"/update-claps/?url=#{url}", "1,js_version")

    response = response(conn_1, 200)
    assert response == "1"

    # let's clap again
    url = "HTTPS://exemple.com/blog-post"

    conn_2 =
      conn
      |> put_req_header("content-type", "text/plain")
      |> post(~p"/update-claps/?url=#{url}", "2,js_version")

    response = response(conn_2, 200)
    assert response == "3"

    # get claps count
    conn_3 = get(conn, ~p"/get-claps?url=#{url}")
    response = response(conn_3, 200)
    assert response == "3"

    # check the clap count request has been logged
    assert ClapCountRequest |> Repo.all() |> length() == 1
  end

  test "post clap using referer", %{conn: conn} do
    url = "https://exemple.com/blog-post"

    conn_1 =
      conn
      |> put_req_header("content-type", "text/plain")
      |> put_req_header("referer", url)
      |> post(~p"/update-claps", "1,js_version")

    response = response(conn_1, 200)
    assert response == "1"

    # let's clap again
    url = "HTTPS://exemple.com/blog-post"

    conn_2 =
      conn
      |> put_req_header("content-type", "text/plain")
      |> put_req_header("referer", url)
      |> post(~p"/update-claps/?url=#{url}", "2,js_version")

    response = response(conn_2, 200)
    assert response == "3"

    # get claps count using request referer
    conn_3 =
      conn
      |> put_req_header("referer", url)
      |> get(~p"/get-claps")

    response = response(conn_3, 200)
    assert response == "3"

    # check the clap count request has been logged
    assert ClapCountRequest |> Repo.all() |> length() == 1
  end

  test "get clap count for non existing page", %{conn: conn} do
    url = "https://exemple.com/unknown-page"

    # get claps count using request referer
    conn =
      conn
      |> get(~p"/get-claps?url=#{url}")

    response = response(conn, 200)
    assert response == "0"
  end
end
