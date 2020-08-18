defmodule XomiumWeb.WebHookController do
  use XomiumWeb, :controller

  require Logger

  def handle(conn, params) do
    Logger.info("#{inspect(conn.req_headers)}", label: "headers")
    Logger.info("#{inspect(params)}", label: "params")

    json(conn, %{"status" => "ok"})
  end
end
