defmodule Xomium.Migrations.CreateUserTable do
  @moduledoc false

  use Ecto.Migration

  def change() do
    create table(:users, primary_key: false, prefix: prefix()) do
      add(:id, :string, primary_key: true)
      add(:primary_email, :string, null: false)
      add(:deleted, :boolean, null: false, default: false)

      timestamps()
    end

    create(unique_index(:users, [:primary_email]))
  end

  def version() do
    20_200_907_130_459
  end
end
