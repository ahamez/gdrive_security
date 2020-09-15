defmodule Xomium.Google.Api.AccessToken do
  @moduledoc """
  https://developers.google.com/identity/protocols/oauth2/service-account
  """

  require Logger

  # 3600 seconds: max TTL authorized by Google.
  @ttl 3600
  @cache_ttl 3300
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

  @spec get(map(), binary()) :: {:ok, binary()} | {:error, any}
  def get(conf, account) do
    ConCache.fetch_or_store(:access_token_cache, account, fn ->
      request(conf, account)
    end)
  end

  @spec delete(binary()) :: :ok
  def delete(account) do
    ConCache.delete(:access_token_cache, account)
  end

  defp request(conf, account) do
    Logger.debug("Renewing access token for #{account}")

    secret = Xomium.Secrets.get(:secrets, :google)

    request_body = make_query(secret, conf["google_issuer"], account)

    with {:ok, %{data: data}} <- post_request(conf, request_body),
         {:ok, json} <- Jason.decode(data),
         {:ok, access_token} <- get_access_token(json) do
      {:ok, access_token}
    end
  end

  defp make_query(secret_key, issuer, sub) do
    URI.encode_query(%{
      "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
      "assertion" => Xomium.Google.Api.Jwt.make(secret_key, issuer, @scopes, @ttl, sub)
    })
  end

  defp post_request(conf, token_request_body) do
    Xomium.MintHttp.post(
      conf["google_oauth_api_url"],
      "/token",
      [{"Content-Type", "application/x-www-form-urlencoded"}],
      token_request_body,
      timeout: conf["http_timeout"]
    )
  end

  defp get_access_token(json) do
    case Map.fetch(json, "access_token") do
      {:ok, access_token} ->
        {:ok, access_token}

      :error ->
        {:error, Xomium.Google.Api.OauthError.new(json)}
    end
  end
end
