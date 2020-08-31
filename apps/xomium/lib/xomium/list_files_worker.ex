defmodule Xomium.ListFilesWorker do
  @moduledoc false

  use Oban.Worker,
    queue: :http_requests,
    max_attempts: 10

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"account" => account, "page_token" => page_token}}) do
    alias Xomium.Google.DriveApiError

    # TODO Rate limiting

    with {:ok, _files, next_page_token} <- Xomium.Google.Files.list(account, page_token) do
      # TODO Save files in db
      case next_page_token do
        nil ->
          Logger.debug("End of pages for #{account}")
          :ok

        _ ->
          %{account: account, page_token: next_page_token}
          |> Xomium.ListFilesWorker.new()
          |> Oban.insert()
      end
    else
      {:error, error = %DriveApiError{reason: {status, _}}}
      when status in [:not_found, :bad_request] ->
        Logger.error(Exception.message(error))
        {:discard, error}

      {:error, error = %DriveApiError{reason: {:unauthorized, :aut_error}}} ->
        Logger.warn("Authentication error for #{account}. Resetting access token.")
        :ok = Xomium.Google.AccessToken.delete(account)
        {:error, error}

      {:error, :invalid_email_or_user_id} ->
        {:discard, :invalid_email_or_user_id}

      {:error, error} ->
        Logger.warn("#{inspect(error)}")
        {:error, error}
    end
  end

  @impl Oban.Worker
  def perform(job) do
    perform(put_in(job.args["page_token"], nil))
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
