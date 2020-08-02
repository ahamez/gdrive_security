defmodule Xomium.GoogleJwt do
  @moduledoc """
  See https://developers.google.com/identity/protocols/oauth2/service-account#httprest.
  """

  @header64 %{"alg" => "RS256", "typ" => "JWT"} |> Jason.encode!() |> Base.url_encode64()

  @doc """
  ## Parameters
  - pk_dem: private key in DEM format (provided by Google)
  - iss: issuer (provided by Google)
  - scope: list of Google scopes (https://developers.google.com/identity/protocols/oauth2/scopes)
  - ttl: time to live given in seconds, O <= ttl <= 3600
  - sub: the Google email address of the account to impersonate
  """
  @spec make(binary(), binary(), [binary()], non_neg_integer(), binary()) :: binary()
  def make(pk_dem, iss, scopes, ttl, sub) when ttl <= 3600 do
    claim64 = make_claim(iss, scopes, ttl, sub) |> Jason.encode!() |> Base.url_encode64()

    [encoded_pk] = :public_key.pem_decode(pk_dem)
    pk = :public_key.pem_entry_decode(encoded_pk)

    content = "#{@header64}.#{claim64}"

    sig64 =
      content
      |> :public_key.sign(:sha256, pk)
      |> Base.url_encode64()

    "#{content}.#{sig64}"
  end

  defp make_claim(iss, scopes, ttl, sub) do
    now = DateTime.utc_now()

    %{
      "iss" => iss,
      "scope" => Enum.join(scopes, " "),
      "aud" => "https://oauth2.googleapis.com/token",
      "iat" => DateTime.to_unix(now),
      "exp" => now |> DateTime.add(ttl, :second) |> DateTime.to_unix(),
      "sub" => sub
    }
  end
end
