defmodule Xomium.GoogleJwtTest do
  use ExUnit.Case, async: true

  # Generated with `openssl genrsa -out private.pem 2048`
  @sk_dem """
  -----BEGIN RSA PRIVATE KEY-----
  MIIEowIBAAKCAQEA0YM0ZNUcRCfPVMuCSD/XAL2txPN1sd5E9xpw/V7R+hF2WpAM
  rDrZPcp30tezty/ZhXmH2rAGNCYw57jYw4M45Z8Djf12XjgkIjTahyD+28LqQ2R6
  eB13HaWc9rG8lG/ztL/V/W5j47oXT5NL6t9kWrG9ZJPl2ZOeKTVUrYd6tqIxcfAE
  oEavsITydu7vNCsf/sls4096I5JP/QCdb/SxM3IfyU1sq3xxk3jOPbJEydyEmxBm
  ry2FiOgseBePee/llOKPJHJPZZW8fj71g7kuk9Ii5twRlkn7Jnx/XXN+gQYaNjv1
  bDrsvhrzHb7vgt6gqYI4chfgsbmT2rmiaQga2QIDAQABAoIBAC+065pGOJCAbCKH
  0Ju5BbEif84IDfW5ggSuXaokDDYgAc4vXONe5xa94rj86uw8lhBhkwDF8jOvupUZ
  Lyqd17fZlIqhe3GK4Rd054m7hqzt3kAIQibVtsjmbC50XFeEgn7W69gwachyGFrD
  VJcf1Q8dx91+G+mGRo5lmWmGHvg03wlEK0JzzJkm5OtqqE4lCRW27yIKrWpTNImq
  ZCvPLIqhWKmzqh/GaNGSvyGcXt+RG/ZvS9z8tgY3CmWsCfvZ+yJtc8pdPyxqJuGe
  IdpH0QhKkVBu1GdqQSetY+n6d7C9ZJoTZUl62iHrOJYnaagLsl7sLF8rV1WPMNJn
  7ozyHgECgYEA6jWHoAbQ03h0xk7I4Rl7qsebeDSk+ZcbPRI3y4gmuIcIYf5CTXoj
  jy7ucykrUvxyrfryRc0JVMXTyD2+TgCli5W69B3lFBCBhvcfeLz9rxvLLcnFaQL5
  QHrTD+8Bb+URgogEcARNCnGlHHw60eE+O6ODwE85rbWHodsHyQqWk8ECgYEA5QFx
  hwSxjszwy5ZoyrCGrVmgOd4i66VHAjpQowBC5Fk27I5cju5dsdP3xhFuQCYsG0lY
  OfVuOubYnStddu4Haf67oUXnSOy4nWu6Bro/28JqvHOY6snbKHZEWXeQt98QNKws
  7jBuafHtwiitncTxK0mBdS4BnXL3JkazzjQK7RkCgYEAtSaGKk5bQtWObLwPP5w4
  PNV6+LSvTaWEme33XeOHH37CCxlgKxDnZB4GrOgQ7HT6Nns83KRELV99+QlYonh5
  ksdS/PIKd0R1CvElVHvJM6Gpu1au7BQyuZ7GlTJlyChDLNULqaCJ/iP8c1XbIO64
  9eP5Sct9b1BTAeupz+Pyp4ECgYAhVeh0wxYlt2eF+0sd1jyEl3tfcRqcOt7vUBXU
  5IDYRLReEwseM0yoSjbTOk5WQDhDcJXLOhLluBzoJBvi6BtkLpSZkVdtoiftonTd
  7dbF4rMu45Tq+J9ScITakTEb0vjE8htIQPyRp4n4rXs4cCa7KmQR7rSFeurHQ5uA
  9MpyYQKBgAVsZYvoIZwjuWo3KDYEx1ZNgVTg8yVTTM+cMfhXLaVquFBX0dN557Mb
  l7rXIHYih9a9ZA/Id3m4vfDncaT58OCSksu14Wcx3DM0DMlQN6QmgW2rWI8WmFMk
  zvJUNDtH8LPoatJqjaWJfDu+Bto4QtdXK1A5szVsrd/nMfZIMg/V
  -----END RSA PRIVATE KEY-----
  """

  # Generated with `openssl rsa -in private.pem -out public.pem -outform PEM -pubout`
  @pk_dem """
  -----BEGIN PUBLIC KEY-----
  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0YM0ZNUcRCfPVMuCSD/X
  AL2txPN1sd5E9xpw/V7R+hF2WpAMrDrZPcp30tezty/ZhXmH2rAGNCYw57jYw4M4
  5Z8Djf12XjgkIjTahyD+28LqQ2R6eB13HaWc9rG8lG/ztL/V/W5j47oXT5NL6t9k
  WrG9ZJPl2ZOeKTVUrYd6tqIxcfAEoEavsITydu7vNCsf/sls4096I5JP/QCdb/Sx
  M3IfyU1sq3xxk3jOPbJEydyEmxBmry2FiOgseBePee/llOKPJHJPZZW8fj71g7ku
  k9Ii5twRlkn7Jnx/XXN+gQYaNjv1bDrsvhrzHb7vgt6gqYI4chfgsbmT2rmiaQga
  2QIDAQAB
  -----END PUBLIC KEY-----
  """

  test "make/5 generates a valid JWT" do
    iss = "foo@example.iam.gserviceaccount.com"

    scopes = [
      "https://www.googleapis.com/auth/drive.metadata",
      "https://www.googleapis.com/auth/drive.readonly",
      "https://www.googleapis.com/auth/admin.directory.user.readonly"
    ]

    ttl = 1800

    sub = "bar@example.com"

    jwt = Xomium.GoogleJwt.make(@sk_dem, iss, scopes, ttl, sub)
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
    [enc_pkey] = :public_key.pem_decode(@pk_dem)
    pkey = :public_key.pem_entry_decode(enc_pkey)
    assert :public_key.verify("#{header64}.#{claim64}", :sha256, sig, pkey)
  end
end
