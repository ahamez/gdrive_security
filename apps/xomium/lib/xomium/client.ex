defmodule Xomium.Client do
  @moduledoc false

  use Ecto.Schema

  @schema_prefix "public"
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "clients" do
    field(:name, :string)
    field(:platform, :map)
    field(:tenant, :string)

    timestamps()
  end

  def changeset(user = %__MODULE__{}, params \\ %{}) do
    import Ecto.Changeset

    user
    |> cast(params, [:name, :platform, :tenant])
    |> validate_required(:name)
    |> unique_constraint(:name)
    |> validate_required(:platform)
  end

  @spec list_clients() :: [struct()]
  def list_clients() do
    Xomium.Repo.all(__MODULE__)
  end

  @spec get_client(binary()) :: struct()
  def get_client(id) do
    Xomium.Repo.get(__MODULE__, id)
  end

  @spec get_client_by(map()) :: struct() | nil
  def get_client_by(params) do
    Xomium.Repo.get_by(__MODULE__, params)
  end

  @spec create_client(map()) :: {:ok, struct()} | {:error, struct()}
  def create_client(attrs \\ %{}) do
    {:ok, client} =
      %__MODULE__{}
      |> changeset(attrs)
      |> Xomium.Repo.insert()

    {:ok, tenant} = Xomium.Client.Tenant.create_tenant(client)

    update_client(client, %{tenant: tenant})
  end

  @spec delete_client(struct()) :: :ok | {:error, any()}
  def delete_client(client) do
    Xomium.Client.Tenant.delete_tenant(client)
    Xomium.Repo.delete(client)
  end

  def update_client(client = %__MODULE__{}, attrs) do
    client
    |> changeset(attrs)
    |> Xomium.Repo.update()
  end
end
