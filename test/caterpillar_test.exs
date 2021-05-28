defmodule CaterpillarTest do
  use ExUnit.Case
  doctest Caterpillar

  test "crawl" do
    Caterpillar.crawl_url("https://underjord.io")
    :timer.sleep(30000)
    assert true
  end
end
