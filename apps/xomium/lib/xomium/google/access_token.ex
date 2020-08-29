defmodule Xomium.Google.AccessToken do
  @moduledoc """
  https://developers.google.com/identity/protocols/oauth2/service-account
  """

  require Logger

  # 3600 seconds: max TTL authorized by Google.
  @ttl 3600
  @cache_ttl 1800
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

  @spec get(binary()) :: {:ok, binary()} | {:error, any}
  def get(account) do
    ConCache.fetch_or_store(:access_token_cache, account, fn ->
      request(account)
    end)
  end

  @spec delete(binary()) :: :ok
  def delete(account) do
    ConCache.delete(:access_token_cache, account)
  end

  defp request(account) do
    Logger.debug("Renewing access token for #{account}")

    secret = Xomium.Secrets.get(:secrets, :google)
    issuer = Application.fetch_env!(:xomium, :issuer)
    oauth_api_url = Application.fetch_env!(:xomium, :google_oauth_api_url)
    request_body = Xomium.Google.Jwt.make_query(secret, issuer, @scopes, @ttl, account)

    with {:ok, %{data: data}} <- post_request(oauth_api_url, request_body),
         {:ok, json} <- Jason.decode(data),
         {:ok, access_token} <- get_access_token(json) do
      {:ok, access_token}
    end
  end

  defp post_request(url, token_request_body) do
    Xomium.HttpRequest.post(
      url,
      "/token",
      [{"Content-Type", "application/x-www-form-urlencoded"}],
      token_request_body
    )
  end

  defp get_access_token(json) do
    case Map.fetch(json, "access_token") do
      {:ok, access_token} ->
        {:ok, access_token}

      :error ->
        error = json["error"]
        error_description = json["error_description"]

        reason =
          case {error, error_description} do
            {"invalid_grant", "Invalid email or User ID"} ->
              :invalid_email_or_user_id

            other ->
              other
          end

        {:error, reason}
    end
  end
end
