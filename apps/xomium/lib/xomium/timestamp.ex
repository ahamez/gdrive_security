defmodule Xomium.Timestamp do
  @moduledoc """
  Generate a timestamp as an integer using current time.
  """

  @spec make() :: integer()
  def make() do
    %{year: y, month: m, day: d, hour: hh, minute: mm, second: ss, microsecond: {_us, _}} =
      NaiveDateTime.utc_now()

    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
    |> String.to_integer()
  end

  defp pad(value, padding \\ 2) do
    value
    |> Integer.to_string()
    |> String.pad_leading(padding, "0")
  end
end
