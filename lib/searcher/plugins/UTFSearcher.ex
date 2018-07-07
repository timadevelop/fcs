defmodule UTFSearcher do
  @behaviour FileSearcher

  @doc """
  Finds using jaro distance for each word in string
  """
  def find(filename, request) do
    {:ok, pid} = Agent.start(fn -> [] end)

    min_jaro_distance = Application.get_env(:fcs, :min_jaro_distance)
    stream = File.stream!(filename, [:read], :line)
    # IO.inspect(stream)
    stream
    |> Stream.each(fn line ->
      cond do
        String.contains?(line, request) ->
          # send(pid, {self(), line, filename})
          :ok = Agent.update(pid, fn state -> [line | state] end)
        jaro_in_string(line, request, min_jaro_distance) > 0 ->
          :ok = Agent.update(pid, fn state -> [line | state] end)
        true ->
          :ok = Agent.update(pid, fn state -> state end)
          # continue
          # send(pid, {self(), :not_found, filename})
      end
    end)
    |> Stream.run()

    Agent.get(pid, fn state ->
      case length(state) do
        0 -> :not_found
        _ -> {:ok, Enum.at(state, 0), request}
      end
    end)
  end

  defp jaro_in_string(str, request, minaccuracy) do
    String.split(str, " ")
    |> Enum.filter(fn word -> String.jaro_distance(word, request) > minaccuracy end)
    |> length
  end

end
