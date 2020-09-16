defmodule Xomium.Google.Api.Drive do
  @moduledoc """
  https://developers.google.com/drive/api/v3/reference/files/list
  """

  @path "/drive/v3/files"

  # Some fields have an impact on pageSize, which is be reduced to 100 by Google
  # when requesting "permissions()".
  # See https://stackoverflow.com/a/42831062/21584.
  @files_fields [
                  "id",
                  "name",
                  "owners(emailAddress)",
                  "permissions(type,emailAddress)",
                  "parents",
                  "webViewLink",
                  "shared",
                  "writersCanShare"
                ]
                |> Enum.join(",")

  @query_parameters %{
    "supportsAllDrives" => true,
    "includeItemsFromAllDrives" => true,
    "pageSize" => 1000,
    "corpora" => "allDrives",
    "fields" => "incompleteSearch,nextPageToken,files(#{@files_fields})"
  }

  @spec files(map(), binary(), binary() | nil) :: {:ok, list(), binary() | nil} | {:error, any()}
  def files(conf, account, page_token) do
    case load_page(conf, account, page_token) do
      {:ok, files, next_page_token} ->
        {:ok, files, next_page_token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp load_page(conf, account, page_token) do
    with {:ok, bearer_token} <- Xomium.Google.Api.AccessToken.get(conf, account),
         {:ok, data} <- call_drive_api(conf, page_token, bearer_token),
         {:ok, json} <- Jason.decode(data) do
      files = json["files"] || []
      :telemetry.execute([:xomium, :google, :drive, :load_page], %{files: length(files)})

      {:ok, files, json["nextPageToken"]}
    end
  end

  defp call_drive_api(conf, page_token, bearer_token) do
    t0 = Time.utc_now()

    parameters =
      @query_parameters
      |> add_page_token(page_token)
      |> add_visibility_filter()

    path = "#{@path}?#{URI.encode_query(parameters)}"
    headers = [{"Authorization", "Bearer #{bearer_token}"}]

    url = conf["google_file_api_url"]
    timeout = conf["http_timeout"]

    res =
      case Xomium.MintHttp.get(url, path, headers, timeout: timeout) do
        {:ok, %{data: data, status: 200}} ->
          {:ok, data}

        {:ok, %{data: data}} ->
          {:error, Xomium.Google.Api.DriveError.new(data)}

        {:error, reason} ->
          {:error, reason}
      end

    time = Time.diff(Time.utc_now(), t0, :microsecond) / 1_000_000
    :telemetry.execute([:xomium, :google, :drive, :call_drive_api], %{time: time})
    :telemetry.execute([:xomium, :google, :drive], %{requests: 1})

    res
  end

  defp add_page_token(params, nil), do: params
  defp add_page_token(params, page_token), do: Map.put(params, "pageToken", page_token)

  defp add_visibility_filter(params) do
    # TODO Check if this cover files shared with an address that is external
    # to the domain
    filter = ~w[
      visibility='anyoneCanFind'
      or
      visibility='anyoneWithLink'
    ] |> Enum.join(" ")

    Map.put(params, "q", filter)
  end
end
