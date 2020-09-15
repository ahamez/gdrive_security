defmodule Xomium.Google.User do
  @moduledoc """
  https://developers.google.com/admin-sdk/directory/v1/reference/users
  """

  use Ecto.Schema

  schema "users" do
    field(:google_id, :string)
    field(:primary_email, :string)
    field(:deleted, :boolean)

    timestamps()
  end

  def changeset(user = %__MODULE__{}, params \\ %{}) do
    import Ecto.Changeset

    user
    |> cast(params, [:google_id, :primary_email])
    |> validate_required(:google_id)
    |> unique_constraint(:google_id)
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
end
