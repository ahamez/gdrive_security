defmodule Xomium.Repo.Migrations.CreateTenants do
  use Ecto.Migration

  def change do
    create table(:tenants) do
      add(:tenant, :string, null: false)
      add(:prefix, :string, null: false)

      timestamps()
    end

    create unique_index(:tenants, :tenant)
  end
end
