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
        args: %{
          "admin_account" => admin,
          "client_id" => client_id,
          "conf" => conf,
          "domain" => domain,
          "next_worker" => next_worker,
          "next_args" => next_args
        }
      }) do
    with {:ok, user} <- fetch_one_user(conf, domain, admin),
         {:ok, customer_id} <- get_customer_id(user),
         {:ok, _client} <- update_customer_id(client_id, customer_id) do
      Logger.debug("Got CustomerId #{customer_id} for domain #{domain}")

      module = String.to_atom(next_worker)

      next_args
      |> module.new()
      |> Oban.insert()
    end
  end

  defp fetch_one_user(conf, domain, admin) do
    alias Xomium.Google.Directory

    with {:ok, [user], _next_page_token} <-
           Directory.users(conf, {:domain, domain}, admin, max_results: 1, fields: ["customerId"]) do
      {:ok, user}
    end
  end

  defp get_customer_id(%{"customerId" => customer_id}) do
    {:ok, customer_id}
  end

  defp get_customer_id(_) do
    {:error, :no_customer_id}
  end

  def update_customer_id(client_id, customer_id) do
    alias Xomium.Client

    client = Client.get_client(client_id)
    Client.update_client(client, %{platform: %{"customer_id" => customer_id}})
  end
end
