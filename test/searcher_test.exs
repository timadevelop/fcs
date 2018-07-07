defmodule FcsTest do
  use ExUnit.Case
  doctest Fcs

  test "greets the world" do
    assert Fcs.hello() == :world
  end
end
