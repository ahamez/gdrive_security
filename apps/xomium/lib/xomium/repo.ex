defmodule Xomium.Repo do
  use Ecto.Repo,
    otp_app: :xomium,
    adapter: Ecto.Adapters.Postgres
end
