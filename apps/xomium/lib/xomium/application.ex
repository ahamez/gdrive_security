defmodule Xomium.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    conf = configure()

    children = [
      Xomium.Repo,
      {Phoenix.PubSub, name: Xomium.PubSub},
      {Xomium.Secrets, [google_secret_pem_path: conf.google_secret_pem_path, name: :secrets]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Xomium.Supervisor)
  end

  defp configure() do
    google_secret_pem_path =
      case Application.get_env(:xomium, :google_secret_pem_path) do
        {:env, var} -> System.fetch_env!(var)
        google_secret_pem_path -> google_secret_pem_path
      end

    %{
      google_secret_pem_path: google_secret_pem_path
    }
  end
end
