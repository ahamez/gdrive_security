defmodule Xomium.Secrets do
  @moduledoc """
  Store all the secrets of the application.
  """

  use Agent

  def start_link(opts) do
    {google_secret_pem_path, opts} = Keyword.pop!(opts, :google_secret_pem_path)
    google_secret = load_pem(google_secret_pem_path)

    Agent.start_link(fn -> %{google: google_secret} end, opts)
  end

  def get(server, secret) do
    Agent.get(server, &Map.get(&1, secret))
  end

  defp load_pem(path) do
    pem = File.read!(path)
    [encoded_pem] = :public_key.pem_decode(pem)
    :public_key.pem_entry_decode(encoded_pem)
  end
end
