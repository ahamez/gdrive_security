defmodule Xomium.Google.HttpStatus do
  @moduledoc """
  https://developers.google.com/drive/api/v3/handle-errors
  """

  def status(400, json) do
    {:bad_request, reason(json)}
  end

  def status(403, json) do
    {:forbidden, reason(json)}
  end

  def status(404, "Not Found") do
    {:not_found, "Not Found"}
  end

  def status(429, json) do
    {:too_many_requests, reason(json)}
  end

  defp reason(json) do
    [%{"reason" => reason}] = json["error"]["errors"]

    case reason do
      "dailyLimitExceeded" -> :daily_limit_exceeded
      "dailyLimitExceededUnreg" -> :daily_limit_exceeded_unreg
      "userRateLimitExceeded" -> :user_rate_limit_exceeded
      "rateLimitExceeded" -> :rate_limit_exceeded
      "invalidParameter" -> :invalid_parameter
    end
  end
end
