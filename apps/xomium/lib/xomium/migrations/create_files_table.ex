defmodule Xomium.Migrations.CreateFilesTable do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:files, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:name, :string, null: false)
      add(:web_view_link, :string, null: false)
      add(:shared, :boolean, null: false)
      add(:writers_can_share, :boolean, null: false)

      timestamps()
    end
  end

  def version() do
    20_200_915_164_317
  end
end
