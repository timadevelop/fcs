defmodule Fcs.Searcher do
  def find(request, directory) do
    Agent.start(fn -> %{} end, [name: :search_results])
    {:ok, pid} = Task.start(fn -> receive_results() end)

    find(pid, request, directory)

    Agent.get(:search_results, fn state -> IO.inspect(state) end)

    send(pid, :stop)
    Agent.update(:search_results, fn _ -> %{} end)
  end

  defp find(pid, request, directory) do
    filenames = Path.wildcard("#{directory}/**/*");

    IO.inspect(filenames)
    dirs = Enum.filter(filenames, fn f ->
      IO.puts(File.dir?(f))
      File.dir?(f)
    end)
    filenames = Enum.filter(filenames, fn f -> ! Enum.member?(dirs, f) end)

    IO.inspect(dirs)
    IO.inspect(filenames)
    # dirs
    # # |> Enum.filter(fn f -> ! File.dir?(f) end)
    # |> Enum.map(fn dir ->
    #   find(pid, request, dir)
    # end)

    tasks = search_in(pid, filenames, request)
    Enum.each(tasks, fn t -> Task.await(t) end)
  end


  defp search_in(pid, filenames, request) when is_list(filenames) do

    filenames
    # |> Enum.filter(fn f -> ! File.dir?(f) end)
    |> Enum.map(fn filename ->
      async_find(pid, filename, request)
    end)


  end


  defp async_find(pid, filename, request) when is_bitstring(filename) do
    Task.async(fn ->
      stream = File.stream!(filename, [:read], :line)
      # IO.inspect(stream)
      len = stream
      |> Stream.each(fn line ->
        cond do
          String.contains?(line, request) ->
            send(pid, {self(), line, filename})
          true ->
            send(pid, {self(), :not_found, filename})
        end
      end)
      |> Enum.to_list()
      |> length()
      # IO.puts("Length is #{len}")
    end)
  end

  def receive_results do
    receive do
      {_pid, :not_found, _filename} ->
        # response = "#{"\u274C"} No such request in #{filename}"
        # IO.puts(response)
        receive_results()
      {_pid, _rsp, filename} ->
        # response = "#{"\u2705"} Yep, Request is in #{filename}"
        Agent.update(:search_results, fn state -> Map.update(state, filename, 1, &(&1 + 1)) end)
        # IO.puts("Agent updated")
        receive_results()
      :stop -> :ok_stopped
      other -> IO.inspect(other)
    end
  end

end
