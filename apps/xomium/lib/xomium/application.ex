defmodule Xomium.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    conf = configure()

    children = [
      {Oban, conf.oban},
      {Phoenix.PubSub, [name: Xomium.PubSub]},
      Xomium.Repo,
      {Xomium.Secrets, [name: :secrets, google_secret_pem_path: conf.google_secret_pem_path]},
      Xomium.ProcessRegistry,
      Xomium.MintHttpCache,
      Xomium.Google.AccessToken
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Xomium.Supervisor)
  end

  defp configure() do
    config =
      %{}
      |> load(:google_secret_pem_path)
      |> load(:google_oauth_api_url)
      |> load(:google_file_api_url)
      |> load(Oban, :oban)

    Logger.debug("#{inspect(config)}")

    config
  end

  defp load(config, key), do: load(config, key, key)

  defp load(config, key, config_key) do
    value =
      case Application.get_env(:xomium, key) do
        {:env, var, opts} ->
          {type, opts} = Keyword.pop(opts, :type, :string)
          {default, opts} = Keyword.pop(opts, :default)
          {required, _opts} = Keyword.pop(opts, :required, default == nil)

          case {System.get_env(var), required, type} do
            {nil, true, _type} ->
              raise "#{var} is required, but unset"

            {nil, false, _type} ->
              default

            {value, _required, :string} ->
              value

            {value, _required, :integer} ->
              String.to_integer(value)
          end

        value ->
          value
      end

    Map.put(config, config_key, value)
  end
end
