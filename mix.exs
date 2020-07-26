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
    []
  end

  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["cmd mix setup"]
    ]
  end
end
