defmodule Xomium.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    conf = configure()

    children = [
      Xomium.Repo,
      {Phoenix.PubSub, [name: Xomium.PubSub]},
      {Xomium.Secrets, [name: :secrets, google_secret_pem_path: conf.google_secret_pem_path]},
      Xomium.ProcessRegistry,
      Xomium.HttpRequestCache,
      Xomium.Google.AccessToken,
      {Oban, conf.oban}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Xomium.Supervisor)
  end

  defp configure() do
    google_secret_pem_path =
      case Application.get_env(:xomium, :google_secret_pem_path) do
        {:env, var} -> System.fetch_env!(var)
        google_secret_pem_path -> google_secret_pem_path
      end

    google_oauth_api_url = Application.get_env(:xomium, :google_oauth_api_url)
    google_file_api_url = Application.get_env(:xomium, :google_file_api_url)

    oban = Application.get_env(:xomium, Oban)

    %{
      google_secret_pem_path: google_secret_pem_path,
      google_oauth_api_url: google_oauth_api_url,
      google_file_api_url: google_file_api_url,
      oban: oban
    }
  end
end
