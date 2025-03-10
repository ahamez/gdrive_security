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
    |> validate_required(:id)
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
  def list_files(tenant) do
    Xomium.Repo.all(__MODULE__, prefix: tenant)
  end

  @spec count_files(binary()) :: non_neg_integer()
  def count_files(tenant) do
    import Ecto.Query
    Xomium.Repo.aggregate(from(f in "files"), :count, prefix: tenant)
  end

  # TODO def update_file(), implemented as an upsert where the new value is always kept.
  # Will be used by webhooks.
end
