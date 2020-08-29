defmodule Xomium.Google.Jwt do
  @moduledoc """
  See https://developers.google.com/identity/protocols/oauth2/service-account#httprest.
  """

  @header64 %{"alg" => "RS256", "typ" => "JWT"} |> Jason.encode!() |> Base.url_encode64()

  @doc """
  ## Parameters
  - secret_key: private key (provided by Google)
  - issuer: issuer (provided by Google)
  - scope: list of Google scopes (https://developers.google.com/identity/protocols/oauth2/scopes)
  - ttl: time to live given in seconds, 0 <= ttl <= 3600
  - sub: the Google email address of the account to impersonate
  """
  @spec make(tuple(), binary(), [binary()], non_neg_integer(), binary()) :: binary()
  def make(secret_key, issuer, scopes, ttl, sub) when ttl <= 3600 do
    claim64 =
      make_claim(issuer, scopes, ttl, sub)
      |> Jason.encode!()
      |> Base.url_encode64()

    content = "#{@header64}.#{claim64}"

    sig64 =
      content
      |> :public_key.sign(:sha256, secret_key)
      |> Base.url_encode64()

    "#{content}.#{sig64}"
  end

  defp make_claim(issuer, scopes, ttl, sub) do
    now = DateTime.utc_now()

    %{
      "iss" => issuer,
      "scope" => Enum.join(scopes, " "),
      "aud" => "https://oauth2.googleapis.com/token",
      "iat" => DateTime.to_unix(now),
      "exp" => now |> DateTime.add(ttl, :second) |> DateTime.to_unix(),
      "sub" => sub
    }
  end
end
