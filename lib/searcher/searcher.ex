defmodule Fcs.Searcher do
  def find(request, directory) do
    Agent.start(fn -> %{} end, name: :search_results)

    {:ok, pid} = Task.start(fn -> receive_results() end)

    :ok = find(pid, request, directory)

    # Agent.get(:search_results, fn state -> IO.inspect(state) end)
    send(pid, :stop)
    Agent.update(:search_results, fn _ -> %{} end)
  end

  defp find(pid, request, directory) do
    path = Path.expand(directory)
    cond do
      File.regular?(path) ->
        process_regular_file(pid, request, path)

      File.dir?(path) ->
        # str =
        File.ls!(path)
        |> Enum.map(fn p ->
          Path.join(path, p)
        end)
        |> Enum.map(fn p ->
          # IO.puts("run find")
          t = Task.async(fn -> find(pid, request, p) end)
          Task.await(t, :infinity)
        end)
      true ->
        []
    end


    # cond do
    #   File.regular?(path) ->
    #     process_regular_file(pid, request, path)
    #
    #   File.dir?(path) ->
    #     File.ls!(path)
    #     |> Stream.map(fn p ->
    #       Path.join(path, p)
    #     end)
    #     |> Stream.map(fn p -> Task.async(fn -> find(pid, request, p) end) end)
    #     |> Stream.each(fn t -> Task.await(t, :infinity) end)
    #     |> Stream.run()
    #
    #   true ->
    #     []
    # end

    :ok
  end

  defp process_regular_file(pid, request, path) do
    case get_filesearcher(path) do
      # Task.async(fn -> :ok end)
      :nothing ->
        # IO.puts("Nothign #{path}")
        :nothing

      {:ext, module} ->
        # IO.puts("started")
        t = async_find(pid, path, request, module)
        Task.await(t, :infinity)
    end
  end

  ##
  defp get_filesearcher(filename) do
    get_filesearcher(:ext, Path.extname(filename))
  end

  defp get_filesearcher(:ext, ext) do
    filesearchers = Application.get_env(:fcs, :filesearchers)

    case Map.get(filesearchers, ext) do
      nil -> :nothing
      module -> {:ext, module}
    end
  end

  ##
  defp async_find(pid, filename, request, module) when is_bitstring(filename) do
    Task.async(fn ->
      send(
        pid,
        {self(), module.find(filename, request), filename}
      )
    end)
  end

  ##
  defp receive_results do
    receive do
      {_pid, :not_found, _filename} ->
        receive_results()

      {_pid, {:ok, line}, filename} ->
        ln = line |> String.slice(0..50) |> String.replace(~r{-[^-]*$}, "")
        IO.puts("#{filename} :: #{ln}")
        Agent.update(:search_results, fn state ->
          Map.update(state, filename, line, fn _ -> line end)
        end)

        receive_results()

      :stop ->
        :ok_stopped

      other ->
        IO.inspect(other)
    end
  end

  defp find_old(pid, request, directory) do
    wild = Path.wildcard("#{directory}/**/*")
    IO.puts("got wild")

    wild
    |> Stream.map(fn filename ->
      case get_filesearcher(filename) do
        # Task.async(fn -> :ok end)
        :nothing ->
          :nothing

        {:ext, module} ->
          # IO.puts("Processing #{filename}")
          async_find(pid, filename, request, module)
          # Task.await(task)
      end
    end)
    |> Stream.each(fn x ->
      case x do
        :nothing ->
          :nothing

        task ->
          # IO.puts(">")
          # IO.inspect(task)
          Task.await(task, :infinity)
      end
    end)
    |> Stream.run()

    tasks
    |> Enum.each(fn t -> Task.await(t, :infinity) end)

    :ok
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
  #
  #
  #
  # in find
  #
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
end
