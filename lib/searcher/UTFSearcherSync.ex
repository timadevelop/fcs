defmodule UTFSearcherSync do
  @behaviour FileSearcher

  def find(filename, request) do
    {:ok, pid} = Agent.start(fn -> 0 end)

    case find_in(filename, request) do
      :not_found -> respond(0)
      val -> respond(1)
    end
    #     res = Agent.get(pid, fn state -> respond(state) end)
    # res
  end

  defp jaro_in_string(str, request, minaccuracy) do
    String.split(str, " ")
    |> Enum.filter(fn word -> String.jaro_distance(word, request) > minaccuracy end)
    |> length
  end

  defp respond(0) do
    :not_found
  end

  defp respond(n) when is_number(n) do
    {:found, n}
  end
  defp find_in(filename, request) when is_bitstring(filename) do
    # IO.puts("Processing -> #{filename} ... ")
    # %{type: type} = File.stat!(filename)
    # IO.inspect(type)
    case File.open(filename, [:read]) do
      {:ok, file} -> fnd(filename, file, request)
      _ -> :not_found
    end
  end

  defp fnd(filename, file, request) do
    result =
    case IO.binread(file, :all) do
      {:error, reason} ->
        :not_found
        # File.close(file)
      data ->
        srch(data, request)
      # :eof ->
      #   IO.puts("eof")
        # File.close(file)
    end

    :ok = File.close(file)
    case result do
      {:ok, line} ->
        ln = line |> String.slice(0..50) |> String.replace(~r{-[^-]*$}, "")
        IO.puts("#{filename} :: #{ln}")
        line
      :not_found -> :not_found
      _ -> IO.puts("wat")
    end
  end
  defp srch(data, request) do
    data
    |> String.split("\n")
    |> Enum.sort(&(&1 < &2))
    |> divide_and_conquer_for(request)
  end


  defp divide_and_conquer_for(list, request) when is_list(list) do
    highest_boundry = length(list) - 1
    lowest_boundry = 0;
    reduce_search(list, request, lowest_boundry, highest_boundry)
  end


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
