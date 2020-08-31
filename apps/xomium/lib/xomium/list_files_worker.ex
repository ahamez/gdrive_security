defmodule Xomium.ListFilesWorker do
  @moduledoc false

  use Oban.Worker,
    queue: :http_requests,
    max_attempts: 10

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args = %{"account" => account, "conf" => conf}}) do
    page_token = args["page_token"]

    alias Xomium.Google.{
      DriveApiError,
      OauthApiError
    }

    # TODO Rate limiting

    with {:ok, _files, next_page_token} <- Xomium.Google.Files.list(conf, account, page_token) do
      # TODO Save files in db
      case next_page_token do
        nil ->
          Logger.debug("End of pages for #{account}")
          :ok

        _ ->
          %{account: account, page_token: next_page_token, conf: conf}
          |> Xomium.ListFilesWorker.new()
          |> Oban.insert()
      end
    else
      {:error, error = %DriveApiError{reason: {status, _}}}
      when status in [:not_found, :bad_request] ->
        Logger.error(Exception.message(error))
        {:discard, error}

      {:error, error = %DriveApiError{reason: {:unauthorized, :auth_error}}} ->
        Logger.warn("Authentication error for #{account}. Resetting access token.")
        :ok = Xomium.Google.AccessToken.delete(account)
        {:error, error}

      {:error, error = %OauthApiError{reason: :invalid_email_or_user_id}} ->
        Logger.error("Invalid account #{account}")
        {:discard, error}

      {:error, error} ->
        Logger.warn("#{inspect(error)}")
        {:error, error}
    end
  end

  @impl Oban.Worker
  def timeout(_job) do
    :timer.minutes(5)
  end

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    trunc(:math.pow(attempt, 2) + 15 + :rand.uniform(30) * attempt)
  end
end
