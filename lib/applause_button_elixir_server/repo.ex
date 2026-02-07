defmodule ApplauseButtonElixirServer.Repo do
  use Ecto.Repo,
    otp_app: :applause_button_elixir_server,
    adapter: Ecto.Adapters.SQLite3
end
