defmodule Xomium.Client do
  @moduledoc false

  use Ecto.Schema

  schema "clients" do
    field(:client, :string)
    field(:google_customer_id, :string)

    timestamps()
  end

  def changeset(user = %__MODULE__{}, params \\ %{}) do
    import Ecto.Changeset

    user
    |> cast(params, [:client, :google_customer_id])
    |> validate_required(:client)
    |> unique_constraint(:client)
    |> validate_required(:google_customer_id)
    |> unique_constraint(:google_customer_id)
  end

  @spec list_clients() :: [struct()]
  def list_clients() do
    Xomium.Repo.all(__MODULE__)
  end
end
