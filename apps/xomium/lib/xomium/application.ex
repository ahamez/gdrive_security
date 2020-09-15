defmodule Xomium.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    conf = configure()

    children = [
      {Oban, Application.get_env(:xomium, Oban)},
      {Phoenix.PubSub, [name: Xomium.PubSub]},
      Xomium.Repo,
      {Xomium.Secrets, [name: :secrets, conf: conf]},
      Xomium.Google.Api.AccessToken
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Xomium.Supervisor)
  end

  def configure() do
    config =
      %{}
      |> load(:google_secret_pem_path)
      |> load(:google_oauth_api_url)
      |> load(:google_file_api_url)
      |> load(:google_issuer)
      |> load(:http_timeout)

    Logger.debug("#{inspect(config)}")

    config
  end

  defp load(config, key) do
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

    # We transform keys into strings as Oban will deserialize back the configuration to
    # workers with keys as strings: https://hexdocs.pm/oban/Oban.html#module-defining-workers
    # We thus have to lookup a configuration entry via "foo" rather than :foo.
    Map.put(config, Atom.to_string(key), value)
  end
end
