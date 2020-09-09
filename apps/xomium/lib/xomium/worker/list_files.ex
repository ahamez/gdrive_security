defmodule Xomium.Worker.ListFiles do
  @moduledoc false

  use Oban.Worker,
    queue: :client_management

  @impl true
  def perform(%Oban.Job{args: %{"conf" => conf, "prefix" => prefix}}) do
    prefix
    |> Xomium.Google.User.list_users()
    |> Enum.each(fn user ->
      %{
        "account" => user.primary_email,
        "conf" => conf
      }
      |> Xomium.Worker.ListUserFiles.new()
      |> Oban.insert()
    end)

    :ok
  end
end
