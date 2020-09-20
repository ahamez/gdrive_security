defmodule Xomium.Google.User do
  @moduledoc """
  https://developers.google.com/admin-sdk/directory/v1/reference/users
  """

  use Ecto.Schema

  @primary_key {:id, :string, autogenerate: false}
  schema "users" do
    field(:primary_email, :string)
    field(:deleted, :boolean)

    timestamps()
  end

  def changeset(user = %__MODULE__{}, params \\ %{}) do
    import Ecto.Changeset

    user
    |> cast(params, [:id, :primary_email])
    |> validate_required(:id)
    |> unique_constraint(:id)
    |> validate_required(:primary_email)
    |> unique_constraint(:primary_email)
  end

  @spec create_user(binary(), map()) :: {:ok, struct()} | {:error, struct()}
  def create_user(tenant, attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Xomium.Repo.insert(prefix: tenant, on_conflict: :nothing)
  end

  @spec list_users(binary()) :: [struct()]
  def list_users(tenant) when is_binary(tenant) do
    Xomium.Repo.all(__MODULE__, prefix: tenant)
  end

  @spec get_user(binary(), binary()) :: struct() | nil
  def get_user(tenant, id) do
    Xomium.Repo.get(__MODULE__, id, prefix: tenant)
  end

  @spec get_user_by(binary(), map()) :: struct() | nil
  def get_user_by(tenant, params) do
    Xomium.Repo.get_by(__MODULE__, params, prefix: tenant)
  end

  # TODO def update_user(), implemented as an upsert where the new value is always kept.
  # Will be used by webhooks.
end
