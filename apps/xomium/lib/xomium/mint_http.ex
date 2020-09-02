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
  def get(url, path, headers, timeout) do
    request("GET", url, path, headers, "", timeout)
  end

  @impl true
  def post(url, path, headers, body, timeout) do
    request("POST", url, path, headers, body, timeout)
  end

  defp request(method, url, path, headers, body, timeout) do
    with {:ok, conn} <- Mint.HTTP.connect(:https, url, 443, mode: :passive),
         {:ok, conn, _request_ref} <- Mint.HTTP.request(conn, method, path, headers, body) do
      recv(%{}, conn, timeout)
    end
  end

  defp recv(acc, conn, timeout) do
    with {:ok, conn, responses} <- Mint.HTTP.recv(conn, 0, timeout) do
      case Enum.reduce(responses, acc, &handle_response/2) do
        {:done, acc} -> {:ok, acc}
        {:error, reason} -> {:error, reason}
        acc -> recv(acc, conn, timeout)
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
end
