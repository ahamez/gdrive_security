defmodule XomiumWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      XomiumWeb.Telemetry,
      # Start the Endpoint (http/https)
      # XomiumWeb.Endpoint
      {SiteEncrypt.Phoenix, XomiumWeb.Endpoint}
      # Start a worker by calling: XomiumWeb.Worker.start_link(arg)
      # {XomiumWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: XomiumWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    XomiumWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
