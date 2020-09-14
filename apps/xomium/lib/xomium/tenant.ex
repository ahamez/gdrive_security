defmodule Xomium.Tenant do
  @moduledoc """
  This modules manages the creation and deletion of tenants.
  """

  use Ecto.Schema

  require Logger

  @schema_prefix "public"
  schema "tenants" do
    field(:client, :string)
    field(:prefix, :string)

    timestamps()
  end

  @spec all_prefixes() :: [binary()]
  def all_prefixes() do
    import Ecto.Query
    query = from t in "tenants", select: t.prefix

    Xomium.Repo.all(query)
  end

  @spec get_prefix(binary()) :: binary() | nil
  def get_prefix(client) when is_binary(client) do
    import Ecto.Query

    query =
      from t in "tenants",
        where: t.client == ^client,
        select: t.prefix

    case Xomium.Repo.all(query) do
      [] -> nil
      [prefix] -> prefix
    end
  end

  @spec create_tenant(binary()) :: {:ok, binary()} | {:error, any}
  def create_tenant(client) when is_binary(client) do
    prefix = make_prefix(client)

    changeset = changeset(%__MODULE__{client: client, prefix: prefix})

    with true <- changeset.valid?(),
         {:ok, _} <- create_schema(prefix),
         {:ok, _} <- Xomium.Repo.insert(changeset),
         :ok <- create_users_table(prefix) do
      Logger.info("Created tenant \"#{client}\"")
      {:ok, prefix}
    end
  end

  @spec delete_tenant(binary()) :: :ok | {:error, any}
  def delete_tenant(client) when is_binary(client) do
    import Ecto.Query

    from(t in "tenants", where: t.client == ^client)
    |> Xomium.Repo.delete_all()

    Ecto.Adapters.SQL.query(
      Xomium.Repo,
      "DROP SCHEMA \"#{make_prefix(client)}\" CASCADE"
    )
  end

  defp create_schema(prefix) do
    Ecto.Adapters.SQL.query(
      Xomium.Repo,
      "CREATE SCHEMA \"#{prefix}\""
    )
  end

  defp changeset(client = %__MODULE__{}, params \\ %{}) do
    import Ecto.Changeset

    client
    |> cast(params, [:client, :prefix])
    |> validate_required(:client)
    |> validate_required(:prefix)
    |> unique_constraint(:client)
  end

  defp create_users_table(prefix) do
    Ecto.Migrator.up(
      Xomium.Repo,
      Xomium.Migrations.CreateTenantUserTable.version(),
      Xomium.Migrations.CreateTenantUserTable,
      prefix: prefix,
      all: true
    )
  end

  defp make_prefix(client) do
    "tenant_#{client}"
  end
end
