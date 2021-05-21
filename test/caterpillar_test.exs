defmodule CaterpillarTest do
  use ExUnit.Case
  doctest Caterpillar

  test "crawl" do
    Caterpillar.crawl_url("https://underjord.io")
    assert true
  end
end
