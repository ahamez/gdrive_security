defmodule Xomium.Worker.InitClient do
  @moduledoc false

  require Logger

  use Oban.Worker,
    queue: :client_management

  alias Xomium.{
    Client,
    Worker
  }

  @impl true
  def perform(%Oban.Job{args: args = %{"state" => state}}) do
    case state do
      "init" ->
        Logger.debug("Initial state")
        init(args)

      "list_users" ->
        Logger.debug("List users state")
        list_users(args)

      "list_files" ->
        Logger.debug("List files state")
        list_files(args)

      _ ->
        Logger.error("Unknown state #{inspect(state)}")
        {:error, :error}
    end
  end

  @impl true
  def perform(job = %Oban.Job{}) do
    perform(put_in(job.args["state"], "init"))
  end

  defp init(args = %{"admin_account" => admin, "conf" => conf, "domain" => domain}) do
    with {:ok, client = %Client{id: client_id}} <-
           Client.create_client(%{client_name: domain, platform: %{}}),
         {:ok, tenant} <- Client.Tenant.create_tenant(client) do
      next_args =
        args
        |> Map.put("state", "list_users")
        |> Map.put("client_id", client_id)
        |> Map.put("tenant", tenant)

      %{
        "admin_account" => admin,
        "client_id" => client_id,
        "conf" => conf,
        "domain" => domain,
        "next_worker" => __MODULE__,
        "next_args" => next_args
      }
      |> Worker.GetCustomerId.new()
      |> Oban.insert()
    end
  end

  defp list_users(
         args = %{
           "admin_account" => admin,
           "conf" => conf,
           "client_id" => client_id,
           "tenant" => tenant
         }
       ) do
    next_args =
      args
      |> Map.put("state", "list_files")
      |> Map.put("tenant", tenant)

    customer_id = Client.get_client(client_id).platform["customer_id"]

    %{
      "admin_account" => admin,
      "conf" => conf,
      "customer_id" => customer_id,
      "next_worker" => __MODULE__,
      "next_args" => next_args,
      "tenant" => tenant
    }
    |> Worker.ListUsers.new()
    |> Oban.insert()
  end

  defp list_files(%{"conf" => conf, "tenant" => tenant}) do
    %{"conf" => conf, "tenant" => tenant}
    |> Worker.ListFiles.new()
    |> Oban.insert()

    # TODO launch worker to register webhooks
    # - for files update per user
    # https://developers.google.com/drive/api/v3/reference/changes/watch
    # - for user addition/deletion/update
    # https://developers.google.com/admin-sdk/directory/v1/reference/users/watch
  end
end
