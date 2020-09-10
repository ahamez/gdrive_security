defmodule Xomium.Worker.GetCustomerId do
  @moduledoc """
  This module defines a job to be scheduled by the Oban library. Its goal is
  to fetch the customer id of a GSuite domain.
  To do so, we have to fetch one user and get the customer id from this user.
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
            "domain" => domain,
            "next_worker" => next_worker,
            "next_args" => next_args,
            "prefix" => prefix
          }
      }) do
    alias Xomium.Google.{
      Directory,
      DirectoryApiError
    }

    with {:ok, users, _next_page_token} <-
           Directory.users(conf, {:domain, domain}, admin, max_results: 1, fields: ["customerId"]) do
      # TODO register this Google customer id in a client DB

      [%{"customerId" => customer_id}] = users
      Logger.debug("Got CustomerId #{customer_id} for #{domain}")

      module = String.to_atom(next_worker)

      next_args
      |> module.new()
      |> Oban.insert()
    end

    #   Enum.each(users, fn user ->
    #     user = %{
    #       google_id: user["id"],
    #       primary_email: user["primaryEmail"]
    #     }

    #     # TODO Bulk insert
    #     %Xomium.Google.User{}
    #     |> Xomium.Google.User.changeset(user)
    #     |> Xomium.Repo.insert(prefix: prefix)
    #   end)

    #   case next_page_token do
    #     nil ->
    #       Logger.debug("End of users pages for #{domain}")
    #       Logger.debug("End of users pages for #{domain}")
    #       Logger.debug("End of users pages for #{domain}")

    module = String.to_atom(next_worker)

    next_args
    |> module.new()
    |> Oban.insert()

    #     _ ->
    #       args
    #       |> Map.put(:page_token, next_page_token)
    #       |> Xomium.Worker.ListUsers.new()
    #       |> Oban.insert()
    #   end
    # else
    #   {:error, error = %DirectoryApiError{}} ->
    #     Logger.warn(Exception.message(error))
    #     {:error, error}

    #   {:error, error} ->
    #     Logger.warn("#{inspect(error)}")
    #     {:error, error}
    # end
  end
end
