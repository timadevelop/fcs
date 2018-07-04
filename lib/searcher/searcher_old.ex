defmodule Fcs.OPldSearcher do
  def find(request, directory) do
    {:ok, pid} = Task.start(fn -> get_results() end)

    init_results()
    filenames = fetch_files(directory)
    IO.puts("Searching for #{request} in files: #{IO.inspect(filenames)}")

    {time, _} = :timer.tc(fn -> search_in(pid, filenames, request) end)
    IO.puts("Search completed in #{IO.inspect(time)} microseconds")

    IO.inspect(Agent.get(:search_results, &(&1)))
    :ok = Agent.update(:search_results, fn l -> [] end)
    send(pid, :stop)
  end


  defp search_in(current_caller, filenames, request) do
    filenames
    |> Enum.map(fn file ->
      task = Task.async(fn ->
        send(current_caller,
             {self(), find_in(file, request), file})
      end)
      Task.await(task);
    end)
  end


  def get_results do
    receive do
      {pid, :not_found, filename} ->
        response = "#{"\u274C"} No such request in #{filename}"
        # IO.puts(response)
        Agent.update(:search_results, fn list -> [response | list] end)
        get_results()
      {pid, rsp, filename} ->
        response = "#{"\u2705"} Yep, Request is in #{filename}"
        # IO.puts(response)
        Agent.update(:search_results, fn list -> [response | list] end)
        get_results()
      :stop -> IO.inspect(:ok_stopped)
      other ->
        IO.puts("other: ")
        IO.inspect(other)
    end
  end

  defp find_in(filename, request) when is_bitstring(filename) do
    # IO.puts("Srch in #{filename}")
    case File.read(filename) do
      {:ok, data} -> srch(data, request)
      {:error, reason} -> {:error, reason}
    end
  end

  defp srch(data, request) do
    data
    |> prepare
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
    middleValue = Enum.at(list, middleIndex, "Shit")

    # IO.puts("reduce_search #{middleIndex} #{middleValue}")
    cond do
      highest_boundry < lowest_boundry -> :not_found
      String.contains? middleValue, request -> middleValue
      request < middleValue -> reduce_search(list, request, lowest_boundry, middleIndex - 1)
      request > middleValue -> reduce_search(list, request, middleIndex + 1, highest_boundry)
    end
  end

  defp prepare(data) do
    String.split(data, "\n")
  end

  defp fetch_files(dir) do
    Path.wildcard("#{dir}/**/**.ex");
  end


  defp init_results do
    Agent.start(fn -> [] end, [name: :search_results])
  end
end
