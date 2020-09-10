defmodule Xomium.Google.File do
  @moduledoc """
  https://developers.google.com/drive/api/v3/reference/files#resource
  """

  use Ecto.Schema

  @primary_key {:id, :string, autogenerate: false}
  schema "files" do
    # "id",
    # "name",
    # "owners(emailAddress)",
    # "permissions(type,emailAddress)",
    # "parents",
    # "webViewLink",
    # "shared",
    # "writersCanShare"

    field(:name, :string)
    field(:web_view_link, :string)
    field(:shared, :boolean)
    field(:writers_can_share, :boolean)

    timestamps()
  end

  def changeset(user = %__MODULE__{}, params \\ %{}) do
    import Ecto.Changeset

    # user
    # |> cast(params, [:google_id, :primary_email])
    # |> validate_required(:google_id)
    # |> unique_constraint(:google_id)
    # |> validate_required(:primary_email)
    # |> unique_constraint(:primary_email)
  end

  @spec list_files(binary()) :: [struct()]
  def list_files(prefix) when is_binary(prefix) do
    Xomium.Repo.all(__MODULE__, prefix: prefix)
  end
end
