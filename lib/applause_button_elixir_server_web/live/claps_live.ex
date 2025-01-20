defmodule ApplauseButtonElixirServerWeb.ClapsLive do
  use ApplauseButtonElixirServerWeb, :live_view
  alias ApplauseButtonElixirServer.Repo
  alias ApplauseButtonElixirServer.Page
  import Ecto.Query

  def render(assigns) do
    ~H"""
    <h1>
      Latest claps
    </h1>

    <%= for page <- @latest_claps do %>
      {page.changed_minutes_ago} minutes ago => {page.url}
      <br />
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :refresh)
    end

    {:ok, assign(socket, latest_claps: lastest_claps())}
  end

  def handle_info(:refresh, socket) do
    socket = assign(socket, latest_claps: lastest_claps())
    {:noreply, socket}
  end

  def lastest_claps() do
    query = from p in Page, limit: 10, order_by: [desc: p.updated_at]

    query
    |> Repo.all()
    |> Enum.map(fn %{url: url, updated_at: updated_at} ->
      %{url: url, changed_minutes_ago: time_ago(updated_at)}
    end)
  end

  def time_ago(datetime) do
    DateTime.diff(DateTime.utc_now(), datetime, :minute)
  end
end
