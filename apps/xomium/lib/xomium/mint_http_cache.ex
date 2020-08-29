defmodule Xomium.MintHttpCache do
  @moduledoc false

  use DynamicSupervisor
  require Logger

  def start_link(init_arg) do
    Logger.debug("Starting #{__MODULE__}")
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def server_process(host) do
    # TODO: lookup for existing process before launching a new one.
    case start_child(host) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  defp start_child(host) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Xomium.MintHttp, host}
    )
  end
end
