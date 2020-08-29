defmodule Xomium.Google.JwtTest do
  use ExUnit.Case, async: true

  # Generated with `openssl genrsa -out private.pem 2048`
  @secret_key_pem File.read!(Path.join(__DIR__, "../test_secret_pem.txt"))

  # Generated with `openssl rsa -in private.pem -out public.pem -outform PEM -pubout`
  @public_key_pem File.read!(Path.join(__DIR__, "../test_public_pem.txt"))

  test "make_jwt/5 generates a valid JWT" do
    [encoded_secret_key] = :public_key.pem_decode(@secret_key_pem)
    secret_key = :public_key.pem_entry_decode(encoded_secret_key)

    [enc_public_key] = :public_key.pem_decode(@public_key_pem)
    public_key = :public_key.pem_entry_decode(enc_public_key)

    iss = "foo@example.iam.gserviceaccount.com"

    scopes = [
      "https://www.googleapis.com/auth/drive.metadata",
      "https://www.googleapis.com/auth/drive.readonly",
      "https://www.googleapis.com/auth/admin.directory.user.readonly"
    ]

    ttl = 1800

    sub = "bar@example.com"

    jwt = Xomium.Google.Jwt.make(secret_key, iss, scopes, ttl, sub)
    assert [header64, claim64, sig64] = String.split(jwt, ".")

    # Header never changes
    assert header64 |> Base.url_decode64!() |> Jason.decode!() == %{
             "alg" => "RS256",
             "typ" => "JWT"
           }

    # Test claim contents
    assert {:ok, claim_json} = Base.url_decode64(claim64)
    assert {:ok, claim} = Jason.decode(claim_json)
    assert claim["iss"] == iss
    assert claim["scope"] == Enum.join(scopes, " ")
    assert claim["sub"] == "bar@example.com"

    # Test signature validity
    {:ok, sig} = Base.url_decode64(sig64)

    assert :public_key.verify("#{header64}.#{claim64}", :sha256, sig, public_key)
  end
end
