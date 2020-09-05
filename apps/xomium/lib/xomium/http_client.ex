defmodule Xomium.HttpClient do
  @moduledoc """
  Contract for a blocking HTTP client.
  """

  @callback get(
              url :: binary(),
              path :: binary(),
              headers :: [{binary(), binary()}],
              opts :: keyword()
            ) :: {:ok, map()} | {:error, any()}

  @callback post(
              url :: binary(),
              path :: binary(),
              headers :: [{binary(), binary()}],
              body :: binary(),
              opts :: keyword()
            ) :: {:ok, map()} | {:error, any()}
end
