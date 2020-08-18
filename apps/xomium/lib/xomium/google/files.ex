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
                  # "permissionIds",
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
    # "fields" => "incompleteSearch,nextPageToken,files(#{@files_fields})"
    "fields" => "incompleteSearch,nextPageToken,files(#{@files_fields})"
  }

  @spec list(binary()) :: %{}
  def list(account) do
    file_api_url = Application.fetch_env!(:xomium, :google_file_api_url)
    request_pid = Xomium.HttpRequestCache.server_process(file_api_url)

    request_fun = fn next_page_token ->
      request(request_pid, account, next_page_token)
    end

    files = get_page(request_fun, %{}, "")
    Logger.info("Retreived #{map_size(files)} files for #{account}")

    files
  end

  defp get_page(_request_fun, files, nil) do
    files
  end

  defp get_page(request_fun, files, next_page_token) do
    # Logger.debug("Get files for #{inspect(next_page_token)}")

    # TODO measure time taken (à ajouter dans les metrics telemetry)
    t0 = Time.utc_now()
    data = request_fun.(next_page_token)
    t1 = Time.utc_now()

    new_files =
      case data["files"] do
        nil ->
          Logger.info("Empty data[files]")
          files

        _ ->
          Enum.reduce(data["files"], files, fn file, acc ->
            Map.put(acc, file["id"], file)
          end)
      end

    t2 = Time.utc_now()

    t1t0 = Time.diff(t1, t0, :microsecond) / 1_000_000
    t2t1 = Time.diff(t2, t1, :microsecond) / 1_000_000

    # :telemetry.execute([:xomium, :get_page], %{duration: t1t0})

    Logger.debug(
      "Processed #{map_size(new_files) - map_size(files)} files in #{t1t0}s and in #{t2t1}s for a total of #{
        map_size(new_files)
      } files"
    )

    get_page(request_fun, new_files, data["nextPageToken"])
  end

  defp request(request_pid, account, next_page_token) do
    bearer_token = Xomium.Google.AccessToken.get(account)

    filter = ~w[
      visibility='anyoneCanFind'
      or
      visibility='anyoneWithLink'
    ] |> Enum.join(" ")

    headers = [{"Authorization", "Bearer #{bearer_token}"}]
    parameters = Map.put(@query_parameters, "pageToken", next_page_token)
    parameters = Map.put(parameters, "q", filter)

    # Logger.debug("#{URI.encode_query(parameters)}")

    {:ok, %{data: data}} =
      Xomium.HttpRequestServer.get(
        request_pid,
        "/drive/v3/files?#{URI.encode_query(parameters)}",
        headers,
        ""
      )

    Jason.decode!(data)
  end
end
