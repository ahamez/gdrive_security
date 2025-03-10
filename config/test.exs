# Loaded at compile time.

import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :xomium, Xomium.Repo,
  username: "postgres",
  password: "postgres",
  database: "xomium_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :xomium_web, XomiumWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :xomium,
  google_secret_pem_path: Path.expand("../apps/xomium/test/test_secret_pem.txt", __DIR__)
