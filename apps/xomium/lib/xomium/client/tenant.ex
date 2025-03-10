defmodule Xomium.Client.Tenant do
  @moduledoc """
  This modules manages the creation and deletion of tenants.
  """

  require Logger

  @spec list_tenants() :: [binary()]
  def list_tenants() do
    import Ecto.Query

    query =
      from t in "clients",
        select: t.tenant

    Xomium.Repo.all(query)
  end

  @spec get_tenant(non_neg_integer()) :: binary() | nil
  def get_tenant(client_id) when is_integer(client_id) do
    import Ecto.Query

    query =
      from t in "clients",
        where: t.client_id == ^client_id,
        select: t.tenant

    case Xomium.Repo.all(query) do
      [] -> nil
      [prefix] -> prefix
    end
  end

  @spec create_tenant(struct()) :: {:ok, binary()} | {:error, any()}
  def create_tenant(client) when is_struct(client) do
    prefix = make_prefix(client.id)

    with {:ok, _} <- create_schema(prefix),
         :ok <- create_users_table(prefix),
         :ok <- create_files_table(prefix) do
      Logger.info("Created tenant \"#{prefix}\"")
      {:ok, prefix}
    end
  end

  @spec delete_tenant(struct()) :: :ok | {:error, any()}
  def delete_tenant(client) when is_struct(client) do
    Ecto.Adapters.SQL.query(
      Xomium.Repo,
      "DROP SCHEMA \"#{make_prefix(client.id)}\" CASCADE"
    )
  end

  defp create_schema(prefix) do
    Ecto.Adapters.SQL.query(
      Xomium.Repo,
      "CREATE SCHEMA \"#{prefix}\""
    )
  end

  defp create_users_table(prefix) do
    Ecto.Migrator.up(
      Xomium.Repo,
      Xomium.Migrations.CreateUserTable.version(),
      Xomium.Migrations.CreateUserTable,
      prefix: prefix,
      all: true
    )
  end

  defp create_files_table(prefix) do
    Ecto.Migrator.up(
      Xomium.Repo,
      Xomium.Migrations.CreateFilesTable.version(),
      Xomium.Migrations.CreateFilesTable,
      prefix: prefix,
      all: true
    )
  end

  defp make_prefix(client_id) do
    "tenant_#{client_id}"
  end
end
