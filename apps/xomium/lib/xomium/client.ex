defmodule Xomium.Client do
  @moduledoc false

  use Ecto.Schema

  @schema_prefix "public"
  schema "clients" do
    field(:client_name, :string)
    field(:platform, :map)
    field(:tenant, :string)

    timestamps()
  end

  def changeset(user = %__MODULE__{}, params \\ %{}) do
    import Ecto.Changeset

    user
    |> cast(params, [:client_name, :platform])
    |> validate_required(:client_name)
    |> unique_constraint(:client_name)
    |> validate_required(:platform)
  end

  @spec list_clients() :: [struct()]
  def list_clients() do
    Xomium.Repo.all(__MODULE__)
  end

  @spec get_client(non_neg_integer()) :: struct()
  def get_client(id) do
    Xomium.Repo.get(__MODULE__, id)
  end

  @spec create_client(map()) :: {:ok, struct()} | {:error, struct()}
  def create_client(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Xomium.Repo.insert()
  end

  def update_client(client = %__MODULE__{}, attrs) do
    client
    |> changeset(attrs)
    |> Xomium.Repo.update()
  end
end
