# Loaded at compile time.

import Config

# Do not print debug messages in production
config :logger, level: :info

config :xomium_web, XomiumWeb.Endpoint, server: true
