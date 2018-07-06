defmodule Fcs.Searcher do
  def find(request, directory) do
    Agent.start(fn -> %{} end, [name: :search_results])

    {:ok, pid} = Task.start(fn -> receive_results() end)

    :ok = find(pid, request, directory)

    Agent.get(:search_results, fn state -> IO.inspect(state) end)
    send(pid, :stop)
    Agent.update(:search_results, fn _ -> %{} end)
  end

  defp find(pid, request, directory) do
    Path.wildcard("#{directory}/**/*")
    |> Enum.each(fn filename ->
      case get_filesearcher(filename) do
        :nothing -> :ok
        {:ext, module} ->
          task = async_find(pid, filename, request, module)
          Task.await(task)
      end
    end)
    # |> Stream.reduce([], fn filename, acc ->
    #   case get_filesearcher(filename) do
    #     :nothing -> acc
    #     {:ext, module} -> [{filename, module} | acc]
    #   end
    # end)
    # |> Stream.chunk_every(20)
    # |> Stream.each(fn files_chunk ->
    #   # IO.puts("chunk 20 files")
    #   # IO.inspect(files_chunk)
    #   search(pid, request, files_chunk)
    #   # IO.puts("done")
    # end)

    :ok
  end
  # defp search(pid, request, filenames) do
  #   # filenames = Path.wildcard("#{directory}/**/*");
  #   #
  #   # dirs = Enum.filter(filenames, fn f -> File.dir?(f) end)
  #   # filenames = Enum.filter(filenames, fn f -> ! Enum.member?(dirs, f) end)
  #   #
  #   # fils = 
  #   #
  #   # each dir async find
  #   # dir_tasks =
  #   # dirs
  #   # |> Enum.map(fn dir ->
  #   #   Task.async(fn -> find(pid, request, dir) end)
  #   # end)
  #
  #   # each file async search
  #   tasks = search_in(pid, filenames, request)
  #
  #   wait(tasks)
  #
  #   # wait(dir_tasks)
  #   :ok
  # end
  #
  # defp wait(tasks, delay \\ :infinity) when is_list(tasks) do
  #   Enum.each(tasks, fn t -> Task.await(t, delay) end);
  # end


  defp get_filesearcher(filename) do
    get_filesearcher(:ext, Path.extname(filename))
  end
  defp get_filesearcher(:ext, ".txt") do
    {:ext, UTFSearcherSync}
  end
  defp get_filesearcher(:ext, ".ex") do
    {:ext, UTFSearcherSync}
  end
  defp get_filesearcher(:ext, _) do
    :nothing
  end

  # defp search_in(pid, filenames, request) do
  #   # TODO: https://elixir-lang.bg/archive/posts/types_and_behaviours
  #
  #   filenames
  #   |> Enum.map(fn {filename, module} ->
  #     async_find(pid, filename, request, module)
  #   end)
  # end


  # defp run(pid, filename, request, module, n) when is_number(n) and n > 1 do
  #   run(pid, filename, request, module, Agent.get(:tasks_count, &(&1)))
  # end
  #
  # defp run(pid, filename, request, module, n) when is_number(n) do
  #   async_find(pid, filename, request, module)
  # end


  defp async_find(pid, filename, request, module) when is_bitstring(filename) do
    Task.async(fn ->
      send(pid,
           {self(), module.find(filename, request), filename})
    end)
  end

  defp receive_results do
    receive do
      {_pid, :not_found, _filename} ->
        receive_results()
      {_pid, {:found, count}, filename} ->
        Agent.update(:search_results, fn state -> Map.update(state, filename, count, fn _ -> count end) end)
        receive_results()
      :stop -> :ok_stopped
      other -> IO.inspect(other)
    end
  end

end
