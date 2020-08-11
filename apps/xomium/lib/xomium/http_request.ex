defmodule Xomium.HttpRequest do
  @moduledoc false

  use GenServer
  require Logger

  defstruct host: nil,
            conn: nil,
            requests: %{}

  def start_link(opts) do
    {name, opts} = Keyword.pop!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def start(opts) do
    # {host, opts} = Keyword.pop!(opts, :host)
    GenServer.start(__MODULE__, opts)
  end

  def post(pid, path, headers, body) do
    GenServer.call(pid, {:request, "POST", path, headers, body})
  end

  # tmp
  def mk_body(jwt) do
    [
      "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=",
      jwt
    ]
  end

  @impl true
  # @spec init(String.t()) :: {:ok, struct()}
  def init(host: host) do
    {:ok, %__MODULE__{host: host}}
  end

  @impl true
  def handle_call({:request, method, path, headers, body}, from, state) do
    {:ok, state} = connect(state)

    case Mint.HTTP.request(state.conn, method, path, headers, body) do
      {:ok, conn, request_ref} ->
        state = put_in(state.conn, conn)
        state = put_in(state.requests[request_ref], %{from: from, response: %{}})
        {:noreply, state}

      {:error, conn, reason} ->
        state = put_in(state.conn, conn)
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(msg, state) do
    case Mint.HTTP.stream(state.conn, msg) do
      :unknown ->
        Logger.error("Received unknown message #{inspect(msg)}")
        {:noreply, state}

      {:ok, conn, responses} ->
        state = put_in(state.conn, conn)
        state = Enum.reduce(responses, state, &process_response/2)
        {:noreply, state}
    end
  end

  defp connect(state, nb_tries \\ 5)

  defp connect(_state, 0) do
    Logger.error("Cannot connect, bailing out")
    {:error, :too_many_connection_attempts}
  end

  defp connect(state = %__MODULE__{conn: nil}, nb_tries) do
    case Mint.HTTP.connect(:https, state.host, 443) do
      {:ok, conn} ->
        state = put_in(state.conn, conn)
        {:ok, state}

      {:error, reason} ->
        Logger.error("Cannot connect: #{Exception.message(reason)}")
        Process.sleep(100)
        connect(state, nb_tries - 1)
    end
  end

  defp connect(state, nb_tries) do
    case Mint.HTTP.open?(state.conn) do
      true ->
        {:ok, state}

      false ->
        # reset connection
        connect(%{state | conn: nil}, nb_tries)
    end
  end

  defp process_response({:status, request_ref, status}, state) do
    put_in(state.requests[request_ref].response[:status], status)
  end

  defp process_response({:headers, request_ref, headers}, state) do
    put_in(state.requests[request_ref].response[:headers], headers)
  end

  defp process_response({:data, request_ref, new_data}, state) do
    update_in(
      state.requests[request_ref].response[:data],
      fn data -> (data || "") <> new_data end
    )
  end

  defp process_response({:done, request_ref}, state) do
    {%{response: response, from: from}, state} = pop_in(state.requests[request_ref])
    GenServer.reply(from, {:ok, response})

    state
  end
end
