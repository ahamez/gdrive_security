defmodule Xomium.Google.OauthApiError do
  @moduledoc """
  https://developers.google.com/identity/protocols/oauth2/service-account
  """

  @type t() :: %__MODULE__{
          reason: any(),
          json: map()
        }

  defexception [:reason, :json]

  @spec new(map()) :: t()
  def new(json) do
    error = json["error"]
    error_description = json["error_description"]

    reason =
      case {error, error_description} do
        {"invalid_grant", "Invalid email or User ID"} ->
          :invalid_email_or_user_id

        {"invalid_grant", "java.security.SignatureException: Invalid signature" <> _} ->
          :invalid_signature

        other ->
          other
      end

    %__MODULE__{reason: reason, json: json}
  end

  @spec message(t()) :: binary()
  def message(error) do
    # TODO One-line output
    "#{inspect(error.reason)} #{inspect(error.json)}"
  end
end
