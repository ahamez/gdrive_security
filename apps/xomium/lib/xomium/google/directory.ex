defmodule Xomium.Google.Directory do
  @moduledoc """
  https://developers.google.com/admin-sdk/directory/v1/reference/users?authuser=1#resource
  """

  @path "/admin/directory/v1/users"

  @max_results 500

  @spec users(
          map(),
          {:domain, binary()} | {:customer_id, binary()},
          binary(),
          Keyword.t()
        ) ::
          {:ok, list(), binary() | nil} | {:error, any()}
  def users(conf, domain_or_customer_id, admin_account, opts \\ []) do
    {page_token, opts} = Keyword.pop(opts, :page_token, nil)
    {max_results, opts} = Keyword.pop(opts, :max_results, @max_results)
    {fields, _opts} = Keyword.pop(opts, :fields, [])

    case load_page(conf, domain_or_customer_id, admin_account, page_token, max_results, fields) do
      {:ok, users, next_page_token} ->
        {:ok, users, next_page_token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp load_page(conf, domain_or_customer_id, admin_account, page_token, max_results, fields) do
    with {:ok, bearer_token} <- Xomium.Google.AccessToken.get(conf, admin_account),
         {:ok, data} <-
           call_directory_api(
             conf,
             domain_or_customer_id,
             page_token,
             bearer_token,
             max_results,
             fields
           ),
         {:ok, json} <- Jason.decode(data) do
      users = json["users"] || []
      :telemetry.execute([:xomium, :google, :users, :load_page], %{users: length(users)})
      {:ok, users, json["nextPageToken"]}
    end
  end

  defp call_directory_api(
         conf,
         domain_or_customer_id,
         page_token,
         bearer_token,
         max_results,
         fields
       ) do
    t0 = Time.utc_now()

    parameters =
      %{}
      |> add_max_results(max_results)
      |> add_page_token(page_token)
      |> add_domain_or_customer_id(domain_or_customer_id)
      |> add_fields_filter(fields)

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

  defp add_max_results(params, value), do: Map.put(params, "maxResults", value)

  defp add_page_token(params, nil), do: params
  defp add_page_token(params, page_token), do: Map.put(params, "pageToken", page_token)

  defp add_domain_or_customer_id(params, {:domain, domain}) do
    Map.put(params, "domain", domain)
  end

  defp add_domain_or_customer_id(params, {:customer_id, customer_id}) do
    Map.put(params, "customerId", customer_id)
  end

  defp add_fields_filter(params, fields) do
    # Fields filtering syntax:
    # https://developers.google.com/admin-sdk/directory/v1/guides/performance#partial
    # Available fields:
    # https://developers.google.com/admin-sdk/directory/v1/reference/users
    filter = "users(id,primaryEmail,#{Enum.join(fields, ",")})"
    Map.put(params, "fields", filter)
  end
end
