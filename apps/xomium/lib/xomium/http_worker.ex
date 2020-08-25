defmodule Xomium.HttpWorker do
  @moduledoc false

  use Oban.Worker, queue: :http_requests

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"account" => account, "page_token" => page_token}}) do
    case Xomium.Google.Files.list(account, page_token) do
      {:ok, _files} ->
        # TODO Save file in db
        :ok

      {:error, {:not_found, _}} ->
        {:discard, :not_found}

      {:error, {:bad_request, reason}} ->
        {:discard, {:bad_request, reason}}

      # TODO snooze when daily limit or other limits are reached
      # {:error, {:forbidden, :daily_limit_exceeded}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl Oban.Worker
  def perform(job) do
    perform(put_in(job.args["page_token"], nil))
  end

  @impl Oban.Worker
  def timeout(_job) do
    :timer.seconds(120)
  end

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    trunc(:math.pow(attempt, 2) + 15 + :rand.uniform(30) * attempt)
  end
end
