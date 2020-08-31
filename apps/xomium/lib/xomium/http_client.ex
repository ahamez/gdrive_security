defmodule Xomium.HttpClient do
  @moduledoc """
  Contract for a blocking HTTP client.
  """

  @callback get(
              url :: binary(),
              path :: binary(),
              headers :: [{binary(), binary()}],
              timeout :: non_neg_integer()
            ) :: {:ok, map()} | {:error, any()}

  @callback post(
              url :: binary(),
              path :: binary(),
              headers :: [{binary(), binary()}],
              body :: binary(),
              timeout :: non_neg_integer()
            ) :: {:ok, map()} | {:error, any()}
end
