defmodule Xomium.Google.Files do
  @moduledoc """
  https://developers.google.com/drive/api/v3/reference/files/list
  """

  require Logger

  # Some fields have an impact on pageSize, which is be reduced to 100 by Google
  # when requesting "permissions()".
  # See https://stackoverflow.com/a/42831062/21584.
  @files_fields [
                  "id",
                  "name",
                  "owners(emailAddress)",
                  "permissions(type,emailAddress)",
                  # "parents",
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

  @spec list(map(), binary(), binary() | nil) :: {:ok, list(), binary() | nil} | {:error, any()}
  def list(conf, account, page_token) do
    case load_page(conf, account, page_token) do
      {:ok, files, next_page_token} ->
        {:ok, files, next_page_token}

      {:error, reason} ->
        Logger.warn("Cannot retrieve files for #{account}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp load_page(conf, account, page_token) do
    with {:ok, bearer_token} <- Xomium.Google.AccessToken.get(conf, account),
         {:ok, data} <- call_drive_api(conf, page_token, bearer_token),
         {:ok, json} <- Jason.decode(data) do
      files = json["files"] || []
      # TODO metric for number of received files
      Logger.debug("Received #{length(files)} files for #{account}")
      {:ok, files, json["nextPageToken"]}
    end
  end

  defp call_drive_api(conf, page_token, bearer_token) do
    # TODO metric for time spent
    t0 = Time.utc_now()

    # TODO Check if this cover files shared with an address that is external
    # to the domain
    filter = ~w[
      visibility='anyoneCanFind'
      or
      visibility='anyoneWithLink'
    ] |> Enum.join(" ")

    parameters =
      case page_token do
        nil -> @query_parameters
        _ -> Map.put(@query_parameters, "pageToken", page_token)
      end

    parameters = Map.put(parameters, "q", filter)

    path = "/drive/v3/files?#{URI.encode_query(parameters)}"
    headers = [{"Authorization", "Bearer #{bearer_token}"}]

    url = conf["google_file_api_url"]
    timeout = conf["http_timeout"]

    res =
      case Xomium.MintHttp.get(url, path, headers, timeout) do
        {:ok, %{data: data, status: 200}} ->
          {:ok, data}

        {:ok, %{data: data}} ->
          {:error, Xomium.Google.DriveApiError.new(data)}

        {:error, reason} ->
          {:error, reason}
      end

    time = Time.diff(Time.utc_now(), t0, :microsecond) / 1_000_000
    Logger.debug("List files request processed in #{time}s")

    res
  end
end
