defmodule Xomium.Worker.ListUserFiles do
  @moduledoc """
  This module defines a job to be scheduled by the Oban library. Its goal is
  to fetch files from the Google Drive API.

  Note that the default setting of Oban is an infinite timeout. However,
  some tasks launched by this worker might timeout (HTTP client) and thus interrupt
  this job.
  """

  use Oban.Worker,
    queue: :http_requests,
    max_attempts: 10

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args = %{"account" => account, "conf" => conf, "tenant" => tenant}}) do
    alias Xomium.Google.Api.{
      DriveError,
      Drive,
      OauthError
    }

    page_token = args["page_token"]

    # TODO Rate limiting

    with {:ok, files, next_page_token} <- Drive.files(conf, account, page_token) do
      Enum.each(files, fn file ->
        Xomium.Google.File.create_file(tenant, %{
          id: file["id"],
          name: file["name"],
          web_view_link: file["webViewLink"],
          shared: file["shared"],
          writers_can_share: file["writersCanShare"]
        })
      end)

      case next_page_token do
        nil ->
          Logger.debug("End of files pages for #{account}")
          :ok

        _ ->
          args
          |> Map.put(:page_token, next_page_token)
          |> Xomium.Worker.ListUserFiles.new()
          |> Oban.insert()
      end
    else
      {:error, error = %DriveError{reason: {status, _}}}
      when status in [:not_found, :bad_request] ->
        Logger.error(Exception.message(error))
        {:discard, error}

      {:error, error = %DriveError{reason: {:unauthorized, :auth_error}}} ->
        Logger.warn("Authentication error for #{account}. Resetting access token.")
        :ok = Xomium.Google.Api.AccessToken.delete(account)
        {:error, error}

      {:error, error = %OauthError{reason: :invalid_email_or_user_id}} ->
        Logger.error("Invalid account #{account}")
        {:discard, error}

      {:error, error = %OauthError{reason: :invalid_signature}} ->
        Logger.error("Invalid private key")
        {:discard, error}

      {:error, error} ->
        Logger.warn("#{inspect(error)}")
        {:error, error}
    end
  end

  # TODO: all http workers should have the same backoff function
  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    trunc(:math.pow(attempt, 2) + 15 + :rand.uniform(30) * attempt)
  end
end
