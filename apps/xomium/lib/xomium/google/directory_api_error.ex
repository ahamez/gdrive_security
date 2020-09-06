defmodule Xomium.Google.DirectoryApiError do
  @moduledoc false

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
    # TODO One-line output
    "#{inspect(error.reason)} #{inspect(error.json)}"
  end

  defp status_to_atom(400), do: :bad_request
  defp status_to_atom(401), do: :unauthorized
  defp status_to_atom(403), do: :forbidden
  defp status_to_atom(404), do: :not_found
  defp status_to_atom(429), do: :too_many_requests
  defp status_to_atom(500), do: :internal_server_error

  defp reason_text_to_atom(%{"error" => %{"errors" => [%{"reason" => reason}]}}) do
    case reason do
      "forbidden" -> :forbidden
      "dailyLimitExceeded" -> :daily_limit_exceeded
      "userRateLimitExceeded" -> :user_rate_limit_exceeded
      "quotaExceeded" -> :quota_exceeded
      "rateLimitExceeded" -> :rate_limit_exceeded
      _ -> :unknown
    end
  end
end
