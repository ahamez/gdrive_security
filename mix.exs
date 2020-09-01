defmodule Xomium.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixir: "~> 1.10",
      test_coverage: [tool: ExCoveralls],
      releases: [
        xomium_umbrella: [
          version: "0.1.0",
          applications: [
            xomium: :permanent,
            xomium_web: :permanent
          ]
        ]
      ]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.4", only: [:test, :dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:test, :dev], runtime: false},
      {:excoveralls, "~> 0.13", only: [:test], runtime: false},
      {:git_hooks, "~> 0.5", only: [:test, :dev], runtime: false}
    ]
  end

  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["cmd mix setup"]
    ]
  end
end
