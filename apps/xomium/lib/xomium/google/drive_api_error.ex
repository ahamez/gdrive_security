defmodule Xomium.Google.DriveApiError do
  @moduledoc """
  https://developers.google.com/drive/api/v3/handle-errors
  """

  @type t() :: %__MODULE__{
          reason: any(),
          json: map()
        }

  defexception [:reason, :json]

  @spec new(binary()) :: t()
  def new(data) do
    json = Jason.decode!(data)

    status = status_to_atom(json["error"]["code"])
    detail = reason_text_to_atom(json)

    %__MODULE__{reason: {status, detail}, json: json}
  end

  @spec message(t()) :: binary()
  def message(error) do
    "#{inspect(error.reason)}"
  end

  defp status_to_atom(400), do: :bad_request
  defp status_to_atom(401), do: :unauthorized
  defp status_to_atom(403), do: :forbidden
  defp status_to_atom(404), do: :not_found
  defp status_to_atom(429), do: :too_many_requests
  defp status_to_atom(500), do: :internal_server_error

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def reason_text_to_atom(%{"error" => %{"errors" => [%{"reason" => reason}]}}) do
    case reason do
      "authError" -> :auth_error
      "backendError" -> :backend_error
      "dailyLimitExceeded" -> :daily_limit_exceeded
      "dailyLimitExceededUnreg" -> :daily_limit_exceeded_unreg
      "internalError" -> :internal_error
      "invalid" -> :invalid
      "invalidParameter" -> :invalid_parameter
      "rateLimitExceeded" -> :rate_limit_exceeded
      "userRateLimitExceeded" -> :user_rate_limit_exceeded
      _ -> :unknown
    end
  end

  def reason_text_to_atom(_) do
    :unknown
  end
end
