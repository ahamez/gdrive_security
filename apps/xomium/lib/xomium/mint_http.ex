defmodule Xomium.MintHttp do
  @moduledoc false

  @behaviour Xomium.HttpClient

  use GenServer
  require Logger

  defstruct host: nil,
            conn: nil,
            requests: %{}

  def start_link(host) do
    GenServer.start_link(__MODULE__, host, name: via_tuple(host))
  end

  defp via_tuple(host) do
    Xomium.ProcessRegistry.via_tuple({__MODULE__, host})
  end

  @impl true
  def get(url, path, headers) do
    request("GET", url, path, headers, "")
  end

  @impl true
  def post(url, path, headers, body) do
    request("POST", url, path, headers, body)
  end

  @impl true
  def init(host) do
    {:ok, %__MODULE__{host: host}}
  end

  defp request(method, url, path, headers, body) do
    url
    |> Xomium.MintHttpCache.server_process()
    |> GenServer.call({:request, method, path, headers, body}, :timer.seconds(60 * 3))
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
        Logger.error("#{__MODULE__} received unknown message #{inspect(msg)}")
        {:noreply, state}

      {:ok, conn, responses} ->
        state = put_in(state.conn, conn)
        state = Enum.reduce(responses, state, &process_response/2)
        {:noreply, state}

      {:error, _conn, reason, _resp} ->
        Logger.warn("Connection closed while streaming: #{inspect(reason)}")

        Enum.each(state.requests, fn {_request_ref, %{from: from}} ->
          GenServer.reply(from, {:error, reason})
        end)

        {:noreply, state}
    end
  end

  defp connect(state = %__MODULE__{conn: nil}) do
    case Mint.HTTP.connect(:https, state.host, 443) do
      {:ok, conn} ->
        state = put_in(state.conn, conn)
        {:ok, state}

      {:error, reason} ->
        Logger.warn("Cannot connect: #{Exception.message(reason)}")
        {:error, reason}
    end
  end

  defp connect(state) do
    case Mint.HTTP.open?(state.conn) do
      true ->
        {:ok, state}

      false ->
        Logger.warn("#{state.host} disconnected. Reset connection")
        connect(%{state | conn: nil})
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

  defp process_response({:error, request_ref, reason}, state) do
    {%{from: from}, state} = pop_in(state.requests[request_ref])
    GenServer.reply(from, {:error, reason})

    state
  end

  defp process_response({:done, request_ref}, state) do
    {%{response: response, from: from}, state} = pop_in(state.requests[request_ref])
    GenServer.reply(from, {:ok, response})

    state
  end
end
