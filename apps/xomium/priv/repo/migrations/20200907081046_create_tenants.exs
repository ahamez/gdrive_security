defmodule Xomium.Repo.Migrations.CreateTenants do
  use Ecto.Migration

  def change do
    create table(:tenants) do
      add(:client, :string, null: false)
      add(:prefix, :string, null: false)

      timestamps()
    end

    create unique_index(:tenants, :client)
  end
end
