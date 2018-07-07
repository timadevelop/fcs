defmodule UTFSearcherSync do
  @moduledoc """
  This module implements FileSearcher and allows to search text in basic text files as html / cpp / ex
  """
  @behaviour FileSearcher

  @doc """
  Searches `request` in `filename`

  Returns `:not_found` if there are no occurrences of `request`
          `{:ok, file_line, request}`
  """
  def find(filename, request) do
    {:ok, pid} = Agent.start(fn -> 0 end)

    case find_in(filename, request) do
      :not_found -> :not_found
      {:ok, line} -> {:ok, line, request}
    end
  end

  # opens file and runs search process
  defp find_in(filename, request) when is_bitstring(filename) do
    # IO.puts("Processing -> #{filename} ... ")
    # %{type: type} = File.stat!(filename)
    # IO.inspect(type)
    case File.open(filename, [:read]) do
      {:ok, file} -> find_in_iodevice(filename, file, request)
      _ -> :not_found
    end
  end

  # reads the whole file, processes and closes iodevice `file`
  defp find_in_iodevice(filename, file, request) do
    result =
    case IO.binread(file, :all) do
      {:error, reason} ->
        :not_found
      data ->
        process(data, request)
    end

    :ok = File.close(file)
    result
  end

  # prepairs data and runs binary search algorithm
  defp process(data, request) do
    data
    |> String.split("\n")
    |> Enum.sort(&(&1 < &2))
    |> divide_and_conquer_for(request)
  end

  # inits binary search
  defp divide_and_conquer_for(list, request) when is_list(list) do
    highest_boundry = length(list) - 1
    lowest_boundry = 0;
    reduce_search(list, request, lowest_boundry, highest_boundry)
  end


  # recursive binary search
  defp reduce_search(list, request, lowest_boundry, highest_boundry) do
    middleIndex = div(highest_boundry + lowest_boundry, 2)
    middleValue = Enum.at(list, middleIndex, :shit)

    # IO.puts("reduce_search #{middleIndex} #{middleValue}")
    cond do
      highest_boundry < lowest_boundry -> :not_found
      String.contains? middleValue, request -> {:ok , middleValue }
      request < middleValue -> reduce_search(list, request, lowest_boundry, middleIndex - 1)
      request > middleValue -> reduce_search(list, request, middleIndex + 1, highest_boundry)
    end
  end

end
