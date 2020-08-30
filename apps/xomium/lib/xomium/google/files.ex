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

  @spec list(binary(), binary() | nil) :: {:ok, %{}} | {:error, any}
  def list(account, page_token) do
    file_api_url = Application.fetch_env!(:xomium, :google_file_api_url)

    case load_page(file_api_url, account, page_token) do
      {:ok, files, next_page_token} ->
        if next_page_token do
          %{account: account, page_token: next_page_token}
          |> Xomium.ListFilesWorker.new()
          |> Oban.insert()
        end

        {:ok, files}

      {:error, reason} ->
        Logger.warn("Cannot retrieve files for #{account}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp load_page(url, account, page_token) do
    case request_page(url, account, page_token) do
      {:ok, data} ->
        files =
          case data["files"] do
            nil ->
              Logger.debug("Empty data[files] for #{account}")
              %{}

            files ->
              Logger.debug("Received #{length(files)} files for #{account}")
              files
          end

        {:ok, files, data["nextPageToken"]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp request_page(url, account, page_token) do
    with {:ok, bearer_token} <- Xomium.Google.AccessToken.get(account),
         {:ok, data} <- call_drive_api(url, page_token, bearer_token),
         {:ok, json} <- Jason.decode(data) do
      {:ok, json}
    end
  end

  defp call_drive_api(url, page_token, bearer_token) do
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

    res =
      case Xomium.MintHttp.get(url, path, headers) do
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
