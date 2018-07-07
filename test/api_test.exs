defmodule Fcs.APITest do
  use ExUnit.Case
  doctest Fcs.API

  test "find test" do
    Fcs.API.find("find test", ".")
    # assert Fcs.API.find("some", ".") == :world
  end
end
