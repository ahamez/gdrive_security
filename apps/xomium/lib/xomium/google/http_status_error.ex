defmodule Xomium.Google.HttpStatus do
  @moduledoc """
  https://developers.google.com/drive/api/v3/handle-errors
  """

  def reason(400, json) do
    {:bad_request, reason_text_to_atom(json)}
  end

  def reason(401, json) do
    {:forbidden, reason_text_to_atom(json)}
  end

  def reason(403, json) do
    {:forbidden, reason_text_to_atom(json)}
  end

  def reason(404, "Not Found") do
    {:not_found, "Not Found"}
  end

  def reason(429, json) do
    {:too_many_requests, reason_text_to_atom(json)}
  end

  def reason(500, json) do
    {:internal_server_error, reason_text_to_atom(json)}
  end

  def reason(status_code, json) do
    {status_code, reason_text_to_atom(json)}
  end

  defp reason_text_to_atom(json) do
    [%{"reason" => reason}] = json["error"]["errors"]

    case reason do
      "dailyLimitExceeded" -> :daily_limit_exceeded
      "dailyLimitExceededUnreg" -> :daily_limit_exceeded_unreg
      "userRateLimitExceeded" -> :user_rate_limit_exceeded
      "rateLimitExceeded" -> :rate_limit_exceeded
      "invalidParameter" -> :invalid_parameter
      "authError" -> :auth_error
      "internalError" -> :internal_error
      _ -> :unknown
    end
  end
end
