defmodule XomiumWeb.PageController do
  use XomiumWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
