defmodule Xomium.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Xomium.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Xomium.PubSub}
      # Start a worker by calling: Xomium.Worker.start_link(arg)
      # {Xomium.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Xomium.Supervisor)
  end
end
