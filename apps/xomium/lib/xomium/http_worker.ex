defmodule Xomium.HttpWorker do
  @moduledoc false

  use Oban.Worker, queue: :http_requests

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"account" => account}}) do
    Xomium.Google.Files.list(account, nil)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"account" => account, "page_token" => page_token}}) do
    Xomium.Google.Files.list(account, page_token)
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
