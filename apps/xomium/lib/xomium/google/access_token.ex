defmodule Xomium.Google.AccessToken do
  @moduledoc false

  require Logger

  # 3600 seconds: max TTL authorized by Google.
  @ttl 3600
  @cache_ttl @ttl - 100
  @scopes [
    "https://www.googleapis.com/auth/drive.metadata",
    "https://www.googleapis.com/auth/drive.readonly",
    "https://www.googleapis.com/auth/admin.directory.user.readonly"
  ]

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_opts) do
    Logger.debug("Starting #{__MODULE__}")

    ConCache.start_link(
      name: :access_token_cache,
      ttl_check_interval: :timer.seconds(5),
      global_ttl: :timer.seconds(@cache_ttl)
    )
  end

  def get(account) do
    ConCache.get_or_store(:access_token_cache, account, fn ->
      request(account)
    end)
  end

  defp request(account) do
    Logger.debug("Renewing access token for #{account}")

    secret = Xomium.Secrets.get(:secrets, :google)
    issuer = Application.fetch_env!(:xomium, :issuer)
    oauth_api_url = Application.fetch_env!(:xomium, :google_oauth_api_url)

    token_request_body = Xomium.Google.Jwt.make(secret, issuer, @scopes, @ttl, account)

    request_pid = Xomium.HttpRequestCache.server_process(oauth_api_url)

    {:ok, %{data: data}} =
      Xomium.HttpRequestServer.post(
        request_pid,
        "/token",
        [{"Content-Type", "application/x-www-form-urlencoded"}],
        token_request_body
      )

    data
    |> Jason.decode!()
    |> Map.fetch!("access_token")
  end
end
