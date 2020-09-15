defmodule Xomium.Google.File do
  @moduledoc """
  https://developers.google.com/drive/api/v3/reference/files#resource
  """

  use Ecto.Schema

  @primary_key {:id, :string, autogenerate: false}
  schema "files" do
    field(:name, :string)
    field(:web_view_link, :string)
    field(:shared, :boolean)
    field(:writers_can_share, :boolean)

    timestamps()
  end

  def changeset(file = %__MODULE__{}, params \\ %{}) do
    import Ecto.Changeset

    file
    |> cast(params, [:id, :name, :web_view_link, :shared, :writers_can_share])
    |> unique_constraint(:id)
    |> validate_required(:name)
    |> validate_required(:web_view_link)
    |> validate_required(:shared)
    |> validate_required(:writers_can_share)
  end

  @spec create_file(binary(), map()) :: {:ok, struct()} | {:error, struct()}
  def create_file(tenant, attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Xomium.Repo.insert(prefix: tenant, on_conflict: :nothing)
  end

  @spec list_files(binary()) :: [struct()]
  def list_files(tenant) when is_binary(tenant) do
    Xomium.Repo.all(__MODULE__, prefix: tenant)
  end
end
