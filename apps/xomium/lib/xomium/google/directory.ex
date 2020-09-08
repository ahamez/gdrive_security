defmodule Xomium.Google.Directory do
  @moduledoc """
  https://developers.google.com/admin-sdk/directory/v1/reference/users?authuser=1#resource
  """

  @path "/admin/directory/v1/users"

  @query_parameters %{
    "maxResults" => 500
  }

  @spec users(map(), binary(), binary(), binary() | nil) ::
          {:ok, list(), binary() | nil} | {:error, any()}
  def users(conf, domain, admin_account, page_token) do
    case load_page(conf, domain, admin_account, page_token) do
      {:ok, users, next_page_token} ->
        {:ok, users, next_page_token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp load_page(conf, domain, admin_account, page_token) do
    with {:ok, bearer_token} <- Xomium.Google.AccessToken.get(conf, admin_account),
         {:ok, data} <- call_directory_api(conf, domain, page_token, bearer_token),
         {:ok, json} <- Jason.decode(data) do
      users = json["users"] || []
      :telemetry.execute([:xomium, :google, :users, :load_page], %{users: length(users)})
      {:ok, users, json["nextPageToken"]}
    end
  end

  defp call_directory_api(conf, domain, page_token, bearer_token) do
    t0 = Time.utc_now()

    parameters =
      @query_parameters
      |> add_page_token(page_token)
      |> add_domain(domain)
      |> add_fields_filter()

    path = "#{@path}?#{URI.encode_query(parameters)}"
    headers = [{"Authorization", "Bearer #{bearer_token}"}]

    url = conf["google_file_api_url"]
    timeout = conf["http_timeout"]

    res =
      case Xomium.MintHttp.get(url, path, headers, timeout: timeout, protocol: :http1) do
        {:ok, %{data: data, status: 200}} ->
          {:ok, data}

        {:ok, %{data: data}} ->
          {:error, Xomium.Google.DirectoryApiError.new(data)}

        {:error, reason} ->
          {:error, reason}
      end

    time = Time.diff(Time.utc_now(), t0, :microsecond) / 1_000_000
    :telemetry.execute([:xomium, :google, :users, :call_directory_api], %{time: time})
    :telemetry.execute([:xomium, :google, :users], %{requests: 1})

    res
  end

  defp add_page_token(params, nil), do: params
  defp add_page_token(params, page_token), do: Map.put(params, "pageToken", page_token)

  defp add_domain(params, domain), do: Map.put(params, "domain", domain)

  defp add_fields_filter(params) do
    # Fields filtering syntax:
    # https://developers.google.com/admin-sdk/directory/v1/guides/performance#partial
    # Available fields:
    # https://developers.google.com/admin-sdk/directory/v1/reference/users
    filter = "users(id,primaryEmail)"
    Map.put(params, "fields", filter)
  end
end
