defmodule UTFSearcher do
  @behaviour FileSearcher

  def find(filename, request) do
    {:ok, pid} = Agent.start(fn -> 0 end)

    stream = File.stream!(filename, [:read], :line)
    # IO.inspect(stream)
    stream
    |> Stream.each(fn line ->
      cond do
        String.contains?(line, request) ->
          # send(pid, {self(), line, filename})
          :ok = Agent.update(pid, fn state -> state + 1 end)
        true ->
          :ok = Agent.update(pid, fn state -> state + jaro_in_string(line, request, 0.9) end)
          # continue
          # send(pid, {self(), :not_found, filename})
      end
    end)
    |> Stream.run()

    Agent.get(pid, fn state -> respond(state) end)
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
end
