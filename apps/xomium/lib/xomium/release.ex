defmodule Xomium.Release do
  @moduledoc """
  Will apply all migrations in priv/repo/migrations.

  See https://hexdocs.pm/phoenix/releases.html#ecto-migrations-and-custom-commands.

  More info for migrations with prefixes:
  https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html#migration-prefixes.
  """

  def migrate() do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos() do
    Application.fetch_env!(:xomium, :ecto_repos)
  end

  defp load_app() do
    Application.load(:xomium)
  end
end
