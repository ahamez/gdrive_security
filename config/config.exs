# Loaded at compile time.

import Config

# Configure Mix tasks and generators
config :xomium,
  ecto_repos: [Xomium.Repo]

config :xomium_web,
  ecto_repos: [Xomium.Repo],
  generators: [context_app: :xomium]

# Configures the endpoint
config :xomium_web, XomiumWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "cFBG29xu9M8Aw3MT8Bs//GjkRETcYcDtDFBlTG6LQEFA2l+KUFoRaZwWNFD/TEMJ",
  render_errors: [view: XomiumWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Xomium.PubSub,
  live_view: [signing_salt: "7jAhrSF7"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :xomium,
  google_secret_pem_path: {:env, "XOMIUM_GOOGLE_SECRET_PEM_PATH"}

# Configure git hooks
if Mix.env() != :prod do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    hooks: [
      pre_commit: [
        tasks: [
          {:cmd, "mix format"}
        ]
      ],
      pre_push: [
        verbose: false,
        tasks: [
          {:cmd, "mix credo"},
          {:cmd, "mix dialyzer"},
          {:cmd, "mix test"}
        ]
      ]
    ]
end

config :xomium, Oban,
  repo: Xomium.Repo,
  prefix: "jobs",
  plugins: [Oban.Plugins.Pruner],
  queues: [http_requests: 10]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
