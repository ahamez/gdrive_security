defmodule Xomium.Worker.Plugin.QueueLength do
  @moduledoc """
  https://blog.softwarecurmudgeon.com/oban-plugins
  https://github.com/sorentwo/oban/blob/master/guides/writing_plugins.md
  """

  use GenServer

  require Ecto.Query

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    repo =
      opts[:conf]
      |> Map.get(:repo)

    queues =
      opts[:conf]
      |> Map.get(:queues)
      |> Keyword.keys()
      |> Enum.map(&Atom.to_string/1)

    state = %{repo: repo, queues: queues, interval: opts[:interval]}
    schedule_poll(state)
    {:ok, state}
  end

  defp schedule_poll(%{interval: interval}) do
    Process.send_after(self(), :poll, interval)
  end

  @impl GenServer
  def handle_info(:poll, state = %{repo: repo, queues: queues}) do
    Enum.each(queues, &emit_for_queue(repo, &1))

    schedule_poll(state)
    {:noreply, state}
  end

  defp emit_for_queue(repo, queue_name) do
    queue_counts =
      Oban.Job
      |> Ecto.Query.where(queue: ^queue_name)
      |> Ecto.Query.group_by([j], j.state)
      |> Ecto.Query.select([j], {j.state, count(j.id)})
      |> repo.all(prefix: "jobs")
      |> Enum.into(%{})

    :telemetry.execute(
      [:oban, :queue_stats, String.to_existing_atom(queue_name)],
      %{
        executing: queue_counts["executing"],
        completed: queue_counts["completed"]
      }
    )
  end
end
