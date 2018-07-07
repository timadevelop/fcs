defmodule Fcs do
  @moduledoc """
  Fcs states for File Content Searcher.
  Fcs Application provides searching in each file of given directory recursively.
  Fcs ingores files with filetypes not defined in Config :filesearchers.

  ## Examples
      > mix escript.build
      > ./fcs find "Application" .
      ./lib/fcs.ex  ::   use Application
  """

  use Application

  @doc """
  Just starts main global supervisor
  """
  @impl true
  def start(_type, _args) do
    Fcs.Supervisor.start_link
  end

  @doc """
  Main function
  """
  def main(args) do
    parse_args(args)
  end

  # parsing arguments
  defp parse_args([arg | tail]) do
    case arg do
      "find" -> find(tail)
      "bench" -> bench(tail)
      _ -> IO.puts("Sorry")
    end
  end

  defp find([]) do
    IO.puts("Agrument error")
  end

  defp find([arg | tail]) do
    Fcs.API.find(arg, get_folder(tail))
  end

  defp bench([]) do
    IO.puts("Agrument error")
  end

  defp bench([arg | tail]) do
    Fcs.API.bench(arg, get_folder(tail))
  end

  defp get_folder([]) do
    "."
  end
  defp get_folder([h | _]) do
    h
  end
end
