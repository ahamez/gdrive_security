defmodule Xomium.Repo.Migrations.CreateClientsTable do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add(:tenant, :string, null: false)
      add(:google_customer_id, :string, null: false)

      timestamps()
    end

    create(unique_index(:clients, [:tenant]))
    create(unique_index(:clients, [:google_customer_id]))
  end
end
