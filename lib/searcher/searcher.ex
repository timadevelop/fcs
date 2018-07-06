defmodule Fcs.Searcher do
  def find(request, directory) do
    Agent.start(fn -> %{} end, [name: :search_results])
    Agent.start(fn -> 0 end, [name: :tasks_count])

    {:ok, pid} = Task.start(fn -> receive_results() end)

    :ok = find(pid, request, directory)

    Agent.get(:search_results, fn state -> IO.inspect(state) end)
    send(pid, :stop)
    Agent.update(:search_results, fn _ -> %{} end)
  end

  defp find(pid, request, directory) do
    filenames = Path.wildcard("#{directory}/**/*");

    dirs = Enum.filter(filenames, fn f -> File.dir?(f) end)
    filenames = Enum.filter(filenames, fn f -> ! Enum.member?(dirs, f) end)

    dir_tasks =
    dirs
    |> Enum.map(fn dir ->
      Task.async(fn -> find(pid, request, dir) end)
    end)


    tasks = search_in(pid, filenames, request)
    Enum.each(tasks, fn t -> Task.await(t, :infinity) end)
    Enum.each(dir_tasks, fn t ->
      Task.await(t, :infinity)
      IO.puts("End dir task")
    end)
    :ok
  end


  defp search_in(pid, filenames, request) when is_list(filenames) do
    # TODO: https://elixir-lang.bg/archive/posts/types_and_behaviours
    filenames
    # |> Enum.filter(fn f -> ! File.dir?(f) end)
    |> Enum.with_index()
    |> Enum.map(fn {filename, index} ->
      # Agent.update(:tasks_count, fn state -> state + 1 end)
      # run(pid, filename, request, UTFSearcher, Agent.get(:tasks_count, fn n -> n end))
    # IO.puts("Run task #{Agent.get(:tasks_count, &(&1))}")
      async_find(pid, filename, request, UTFSearcher)
    end)
  end


  defp run(pid, filename, request, module, n) when is_number(n) and n > 1 do
    # IO.puts("yo #{Agent.get(:tasks_count, &(&1))}")
    run(pid, filename, request, module, Agent.get(:tasks_count, fn n -> n end))
  end

  defp run(pid, filename, request, module, n) when is_number(n) do
    # IO.puts("Run task #{Agent.get(:tasks_count, &(&1))}")
    async_find(pid, filename, request, module)
  end


  defp async_find(pid, filename, request, module) when is_bitstring(filename) do
    Task.async(fn ->
      send(pid,
           {self(), module.find(filename, request), filename})
    end)
  end
  #
  # defp aasync_find(pid, filename, request) when is_bitstring(filename) do
  #   Task.async(fn ->
  #     # module.find(filename, request)
  #
  #     stream = File.stream!(filename, [:read], :line)
  #     # IO.inspect(stream)
  #     len = stream
  #     |> Stream.each(fn line ->
  #       cond do
  #         String.contains?(line, request) ->
  #           send(pid, {self(), line, filename})
  #         true ->
  #           send(pid, {self(), :not_found, filename})
  #       end
  #     end)
  #     |> Enum.to_list()
  #     |> length()
  #     # IO.puts("Length is #{len}")
  #   end)
  # end

  def receive_results do
    receive do
      {_pid, :not_found, _filename} ->
        # response = "#{"\u274C"} No such request in #{filename}"
        # IO.puts(response)
        Agent.update(:tasks_count, fn state -> state - 1 end)
        receive_results()
      {_pid, {:found, count}, filename} ->
        Agent.update(:search_results, fn state -> Map.update(state, filename, count, fn _ -> count end) end)
        Agent.update(:tasks_count, fn state -> state - 1 end)
        # IO.puts("Agent updated")
        receive_results()
      # {_pid, _rsp, filename} ->
      #   # response = "#{"\u2705"} Yep, Request is in #{filename}"
      #   Agent.update(:search_results, fn state -> Map.update(state, filename, 1, &(&1 + 1)) end)
      #   # IO.puts("Agent updated")
        # receive_results()
      :stop -> :ok_stopped
      other -> IO.inspect(other)
    end
  end

end
