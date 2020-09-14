defmodule Xomium.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add(:client, :string, null: false)
      add(:google_customer_id, :string, null: false)

      timestamps()
    end

    create(unique_index(:clients, [:client]))
    create(unique_index(:clients, [:google_customer_id]))
  end
end
