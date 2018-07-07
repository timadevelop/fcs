defmodule Fcs.Searcher do
  @moduledoc """
  This module provides main functionality of Fcs:
    Searching in each file of given directory recursively.
  """

  @doc """
  Finds all files with at least one occurrence of `request` in `directory` folder.

  Returns {:ok, `results`}
    where `results` is a map %{ filename => line }

  ## Examples

      iex(1)> Fcs.Searcher.find("def f", ".")
      "./lib/api/api.ex  ::   def find(request, folder, opts) when is_binary(request) and is_binary(folder) and is_list(opts) do""
      {:ok,
       %{
         "./lib/api/api.ex" => "  def find(request, folder, opts) when is_binary(request) and is_binary(folder) and is_list(opts) do"
       }}

  """
  def find(request, directory) do
    Agent.start(fn -> %{} end, name: :search_results)
    Agent.start(fn -> [] end, name: :tasks)

    {:ok, pid} = Task.start(fn -> receive_results() end)

    :ok = process_directory(pid, request, directory)

    # wait tasks
    s = Agent.get(:tasks, fn s -> s end, :infinity)
    Enum.each(s, fn task ->
      Task.await(task, :infinity)
      # IO.puts("awaited")
    end)
    # Agent.get(:search_results, fn state -> IO.inspect(state) end)
    results = Agent.get(:search_results, fn state -> {:ok, state} end)
    send(pid, :stop)
    Agent.update(:search_results, fn _ -> %{} end)
    results
  end

  # recursively traverses `directory`, runs tasks processing of found file
  defp process_directory(pid, request, directory) do
    path = directory

    cond do
      File.regular?(path) ->
        case process_regular_file(pid, request, path) do
          :nothing -> :nothing
          task ->
            # IO.puts("NEW TASK")
            Agent.update(:tasks, fn s -> [task | s] end, :infinity)
        end

      File.dir?(path) ->
        File.ls!(path)
        |> Enum.map(fn p ->
          Path.join(path, p)
        end)
        |> Enum.map(fn p ->
          # IO.puts("run find")
          # t = Task.async(fn -> process_directory(pid, request, p) end)
          # Task.await(t, :infinity)
          process_directory(pid, request, p)
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

  # processes file `path` if there is a FileSearcher for file extension in Config
  defp process_regular_file(pid, request, path) do
    case get_filesearcher(path) do
      # Task.async(fn -> :ok end)
      :nothing ->
        # IO.puts("Nothign #{path}")
        :nothing

      {:ext, module} ->
        # IO.puts("started")
        async_find(pid, path, request, module)
        # Task.await(t, :infinity)
    end
  end

  # finds FileSearcher in config for `filepath`
  defp get_filesearcher(filepath) do
    get_filesearcher(:ext, Path.extname(filepath))
  end

  # finds FileSearcher in config for `ext`
  defp get_filesearcher(:ext, ext) do
    filesearchers = Application.get_env(:fcs, :filesearchers)

    case Map.get(filesearchers, ext) do
      nil -> :nothing
      module -> {:ext, module} # TODO: check if implements FileSearcher behaviour
    end
  end

  # runs task which will send to `pid` msg of `module.find` execution
  defp async_find(pid, filename, request, module) when is_bitstring(filename) do
    Task.async(fn ->
      send(
        pid,
        {self(), module.find(filename, request), filename}
      )
    end)
  end

  # receive results from `FileSearcher.find/2`
  # receives result, prints it to console and updates global agent
  defp receive_results do
    receive do
      {_pid, :not_found, _filename} ->
        receive_results()

      {_pid, {:ok, line, request}, filename} ->
        ln = line
             |> String.replace(request, IO.ANSI.green() <> request <> IO.ANSI.default_color())

        IO.puts("#{IO.ANSI.blue()}#{filename} #{IO.ANSI.default_color()} :: #{ln}")
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

  # this is old find function, just for
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
