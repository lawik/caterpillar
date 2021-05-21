defmodule CaterpillarTest do
  use ExUnit.Case
  doctest Caterpillar

  test "greets the world" do
    assert Caterpillar.hello() == :world
  end
end
