defmodule Fcs do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Fcs.Supervisor.start_link
  end

  def main(args) do
    IO.puts("me here")
    parse_args(args)
  end

  defp parse_args([arg | tail]) do
    case arg do
      "find" -> find(tail)
      _ -> IO.puts("Sorry")
    end
  end

  defp find([arg | tail]) do
    Fcs.API.bench(arg, get_folder(tail))
  end

  defp get_folder([]) do
    "."
  end
  defp get_folder([h | _]) do
    h
  end
end
