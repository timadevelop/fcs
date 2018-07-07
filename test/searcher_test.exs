defmodule Fcs.SearcherTest do
  use ExUnit.Case
  # doctest Fcs.Searcher

  test "find test" do
    assert 0 < test_find("do", "./test")
    assert 0 < test_find("def", "./test")
    assert 0 < test_find("test", "./test")
    assert 0 < test_find("assert", "./test")
    assert 0 < test_find("end", "./test")
    # test_find("String", "./test")
  end

  defp test_find(request, dir) do
    {:ok, result_map} = Fcs.Searcher.find(request, dir)
    Map.values(result_map)
    |> Enum.filter(fn e -> String.contains?(e, request) end)
    |> length()
  end

end
