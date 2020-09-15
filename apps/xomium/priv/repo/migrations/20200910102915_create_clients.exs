defmodule Xomium.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:platform, :map, null: false)
      add(:tenant, :string)

      timestamps()
    end

    create(unique_index(:clients, [:name]))
  end
end
