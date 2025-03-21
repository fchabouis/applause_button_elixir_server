defmodule ApplauseButtonElixirServerWeb.ClapsLive do
  use ApplauseButtonElixirServerWeb, :live_view
  alias ApplauseButtonElixirServer.Repo
  alias ApplauseButtonElixirServer.Page
  alias ApplauseButtonElixirServer.ClapCountRequest
  import Ecto.Query

  def render(assigns) do
    ~H"""
    <h1 class="mt-2 text-pretty text-4xl font-semibold tracking-tight text-gray-900 sm:text-5xl">
      Latest claps
    </h1>

    <ul role="list" class="divide-y divide-gray-100 pt-12">
      <%= for page <- @latest_claps do %>
        <li class="flex justify-between gap-x-6 py-5">
          <div class="flex min-w-0 gap-x-4">
            <a href={"https://#{page.url}"} target="_blank">{page.url}</a>
          </div>
          <div class="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
            <span class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
              {page.changed_minutes_ago} min ago
            </span>
          </div>
        </li>
      <% end %>
    </ul>

    <h1 class="mt-2 text-pretty text-4xl font-semibold tracking-tight text-gray-900 sm:text-5xl pt-24">
      Latest visits
    </h1>
    <ul role="list" class="divide-y divide-gray-100 pt-12">
      <%= for page <- @latest_visits do %>
        <li class="flex justify-between gap-x-6 py-5">
          <div class="flex min-w-0 gap-x-4">
            <a href={"https://#{page.url}"} target="_blank">{page.url}</a>
          </div>
          <div class="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
            <span class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
              {page.changed_minutes_ago} min ago
            </span>
          </div>
        </li>
      <% end %>
    </ul>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :refresh)
    end

    {:ok, assign(socket, latest_claps: lastest_claps(), latest_visits: latest_visits())}
  end

  def handle_info(:refresh, socket) do
    socket = assign(socket, latest_claps: lastest_claps(), latest_visits: latest_visits())
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

  def latest_visits() do
    query =
      from r in ClapCountRequest,
        limit: 10,
        order_by: [desc: r.inserted_at],
        select: {r},
        preload: [:page]

    query
    |> Repo.all()
    |> Enum.map(fn {%{page: %{url: url}, inserted_at: inserted_at}} ->
      %{url: url, changed_minutes_ago: time_ago(inserted_at)}
    end)
  end

  def time_ago(datetime) do
    DateTime.diff(DateTime.utc_now(), datetime, :minute)
  end
end
