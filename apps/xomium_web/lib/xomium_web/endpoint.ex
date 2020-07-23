defmodule XomiumWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :xomium_web
  use SiteEncrypt.Phoenix

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_xomium_web_key",
    signing_salt: "RNplqVdP"
  ]

  socket "/socket", XomiumWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :xomium_web,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :xomium_web
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug XomiumWeb.Router

  @impl SiteEncrypt
  def certification() do
    SiteEncrypt.configure(
      # client: :native,
      client: :certbot,

      domains: ["xomium.com"],
      emails: ["contact@xomium.com"],

      db_folder: Application.app_dir(:xomium_web, Path.join(~w/priv site_encrypt/)),

      directory_url:
        case System.get_env("SERVER_MODE", "local") do
          "local" -> {:internal, port: 4002}
          "staging" -> "https://acme-staging-v02.api.letsencrypt.org/directory"
          "production" -> "https://acme-v02.api.letsencrypt.org/directory"
        end
    )
  end

  @impl Phoenix.Endpoint
  def init(_key, config) do
    {
      :ok,
      SiteEncrypt.Phoenix.configure_https(config, port: 443)
      # config
      # |> SiteEncrypt.Phoenix.configure_https(port: 4001)
      # |> Keyword.merge(http: [port: 80])
    }
  end
end
