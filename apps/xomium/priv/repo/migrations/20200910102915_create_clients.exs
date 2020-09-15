defmodule Xomium.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add(:client_name, :string, null: false)
      add(:platform, :map, null: false)
      add(:tenant, :string)

      timestamps()
    end

    create(unique_index(:clients, [:client_name]))
  end
end
