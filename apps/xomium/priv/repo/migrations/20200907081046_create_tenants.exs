defmodule Xomium.Repo.Migrations.CreateTenants do
  use Ecto.Migration

  def change do
    create table(:tenants) do
      add(:tenant, :string, null: false)
      add(:prefix, :string, null: false)
      add(:customer_id, :string, null: false)

      timestamps()
    end

    create unique_index(:tenants, :tenant)
    create unique_index(:customer_id, :customer_id)
  end
end
