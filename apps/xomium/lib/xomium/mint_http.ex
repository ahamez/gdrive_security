defmodule Xomium.MintHttp do
  @moduledoc """
  Module responsible for handling blocking HTTP connections using Mint.

  Process-less HTTP client: each job opens a connection to Google API

  The previous architecture had a problem when requests multiplexed in a HTTP2 connection timed
  out (it's not clear if it's due to Google API or the Mint library).
  The server returned %Mint.HTTPError{module: Mint.HTTP2, reason: :too_many_concurrent_requests}.
  In other words, as some requests stalled, new ones were created until we reached the max allowed
   by the server (100 in this case).

  While it's obvious that we should reuse connections, this simple architecture now works.
  If/when we encountered performance issues, it will be the time to devise a pool-based connection,
  maybe using a higher-level library. other than Mint

  TODO Verify that non-secure or bad HTTPS connections are refused.
  """

  @behaviour Xomium.HttpClient

  @impl true
  def get(url, path, headers, opts \\ []) do
    request("GET", url, path, headers, "", opts)
  end

  @impl true
  def post(url, path, headers, body, opts \\ []) do
    request("POST", url, path, headers, body, opts)
  end

  defp request(method, url, path, headers, body, opts) do
    headers = [{"accept-encoding", "gzip"}, "user-agent", "xomium (gzip)" | headers]

    {timeout, opts} = Keyword.pop(opts, :timeout, :infinity)
    {protocol, _} = Keyword.pop(opts, :protocol, :http2)

    with {:ok, conn} <-
           Mint.HTTP.connect(:https, url, 443, mode: :passive, protocols: [protocol]),
         {:ok, conn, _request_ref} <- Mint.HTTP.request(conn, method, path, headers, body) do
      recv(%{}, conn, timeout)
    end
  end

  defp recv(acc, conn, timeout) do
    with {:ok, conn, responses} <- Mint.HTTP.recv(conn, 0, timeout) do
      case Enum.reduce(responses, acc, &handle_response/2) do
        {:done, acc} ->
          compression_algorithms = get_content_encoding_header(acc.headers)
          response = update_in(acc.data, &decompress_data(&1, compression_algorithms))

          {:ok, response}

        {:error, reason} ->
          {:error, reason}

        acc ->
          recv(acc, conn, timeout)
      end
    end
  end

  defp handle_response({:status, _request_ref, status}, acc) do
    Map.put(acc, :status, status)
  end

  defp handle_response({:headers, _request_ref, headers}, acc) do
    Map.update(acc, :headers, headers, fn previous -> previous ++ headers end)
  end

  defp handle_response({:data, _request_ref, data}, acc) do
    Map.update(acc, :data, data, fn previous -> previous <> data end)
  end

  defp handle_response({:done, _request_ref}, acc) do
    {:done, acc}
  end

  defp handle_response({:error, _request_ref, reason}, _acc) do
    {:error, reason}
  end

  defp decompress_data(data, algorithms) do
    Enum.reduce(algorithms, data, &decompress_with_algorithm/2)
  end

  defp decompress_with_algorithm(gzip, data) when gzip in ["gzip", "x-gzip"],
    do: :zlib.gunzip(data)

  defp decompress_with_algorithm("deflate", data),
    do: :zlib.unzip(data)

  defp decompress_with_algorithm("identity", data),
    do: data

  defp decompress_with_algorithm(algorithm, _data),
    do: raise("unsupported decompression algorithm: #{inspect(algorithm)}")

  defp get_content_encoding_header(headers) do
    Enum.find_value(headers, [], fn {name, value} ->
      if String.downcase(name) == "content-encoding" do
        value
        |> String.downcase()
        |> String.split(",", trim: true)
        |> Stream.map(&String.trim/1)
        |> Enum.reverse()
      else
        nil
      end
    end)
  end
end
