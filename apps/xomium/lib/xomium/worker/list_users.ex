defmodule Xomium.Worker.ListUsers do
  @moduledoc """
  This module defines a job to be scheduled by the Oban library. Its goal is
  to fetch users from the Google Admin Directory API.

  Note that the default setting of Oban is an infinite timeout. However,
  some tasks launched by this worker might timeout (HTTP client) and thus interrupt
  this job.
  """

  use Oban.Worker,
    queue: :http_requests,
    max_attempts: 10

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          args = %{
            "admin_account" => admin,
            "conf" => conf,
            "customer_id" => customer_id,
            "next_worker" => next_worker,
            "next_args" => next_args,
            "tenant" => tenant
          }
      }) do
    page_token = args["pageToken"]

    alias Xomium.Google.{
      Directory,
      DirectoryApiError
    }

    with {:ok, users, next_page_token} <-
           Directory.users(conf, {:customer_id, customer_id}, admin, page_token: page_token) do
      insert_users(tenant, users)

      case next_page_token do
        nil ->
          Logger.debug("End of users pages for #{customer_id}")

          module = String.to_atom(next_worker)

          next_args
          |> module.new()
          |> Oban.insert()

        _ ->
          args
          |> Map.put(:page_token, next_page_token)
          |> Xomium.Worker.ListUsers.new()
          |> Oban.insert()
      end
    else
      {:error, error = %DirectoryApiError{}} ->
        Logger.warn(Exception.message(error))
        {:error, error}

      {:error, error} ->
        Logger.warn("#{inspect(error)}")
        {:error, error}
    end
  end

  defp insert_users(tenant, users) do
    Enum.each(users, fn user ->
      Xomium.Google.User.create_user(tenant, %{
        google_id: user["id"],
        primary_email: user["primaryEmail"]
      })
    end)
  end
end
