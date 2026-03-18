defmodule Estratos.Repo do
  use Ecto.Repo,
    otp_app: :estratos,
    adapter: Ecto.Adapters.Postgres
end
