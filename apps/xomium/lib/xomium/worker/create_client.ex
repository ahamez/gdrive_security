defmodule Xomium.Worker.CreateClient do
  @moduledoc false

  require Logger

  use Oban.Worker,
    queue: :client_management

  alias Xomium.Worker

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
    with {:ok, prefix} <- Xomium.Tenant.create_tenant(args["domain"]) do
      next_args =
        args
        |> Map.put("state", "list_users")
        |> Map.put("prefix", prefix)

      %{
        "admin_account" => admin,
        "conf" => conf,
        "domain" => domain,
        "next_worker" => __MODULE__,
        "next_args" => next_args,
        "prefix" => prefix
      }
      |> Worker.GetCustomerId.new()
      |> Oban.insert()
    end
  end

  defp list_users(
         args = %{
           "admin_account" => admin,
           "conf" => conf,
           "customer_id" => customer_id,
           "prefix" => prefix
         }
       ) do
    next_args =
      args
      |> Map.put("state", "list_files")
      |> Map.put("prefix", prefix)

    %{
      "admin_account" => admin,
      "conf" => conf,
      "customer_id" => customer_id,
      "next_worker" => __MODULE__,
      "next_args" => next_args,
      "prefix" => prefix
    }
    |> Worker.ListUsers.new()
    |> Oban.insert()
  end

  defp list_files(%{"conf" => conf, "prefix" => prefix}) do
    %{"conf" => conf, "prefix" => prefix}
    |> Worker.ListFiles.new()
    |> Oban.insert()

    # TODO launch worker to register webhooks
    # - for files update per user
    # https://developers.google.com/drive/api/v3/reference/changes/watch
    # - for user addition/deletion
    # https://developers.google.com/admin-sdk/directory/v1/reference/users/watch
  end
end
