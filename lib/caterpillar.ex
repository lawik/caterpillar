defmodule Caterpillar do
  require Logger

  @lock_table :url_locks
  @body_table :url_body

  # TODO: Add finches per domain
  # TODO: Add check for robots.txt and respect it

  # TODO: Set up more serious orchestration of fetching URL contents vs parsing links vs rechecking
  # TODO: Save data on linking and relationships (build the graphy thing)

  # TODO: Add a nice user agent
  # TODO: Find out which domains have been visited
  # TODO: Unleash on web when it can behave

  def crawl_url(url) do
    ensure_tables()

    if should_crawl?(url) and acquire_lock?(url) do
      Logger.info("URL: #{url}")

      case get_url(url) do
        :ok ->
          clear_lock(url)

          url
          |> parse_links()
          |> Enum.each(fn link_url ->
            Task.start_link(fn ->
              crawl_url(link_url)
            end)
          end)

        :skip ->
          clear_lock(url)
          :ok
      end
    end
  end

  def get_url(url) do
    :get
    |> Finch.build(url)
    |> Finch.request(DefaultFinch)
    |> case do
      {:ok, %{status: 200, body: body, headers: headers}} ->
        content_type =
          headers
          |> Map.new()
          |> Map.get("content-type", nil)

        if content_type == "text/html" do
          save_url(url, body)
          :ok
        else
          :skip
        end

      {:ok, %{status: status, headers: headers}} when status in [301, 302] ->
        location =
          headers
          |> Map.new()
          |> Map.get("location", nil)

        get_url(location)

      error ->
        Logger.error("URL failed: #{url}")
        raise "failed #{inspect(error)}"
    end
  end

  def save_url(url, body) do
    :ets.insert(@body_table, {url, body})
  end

  def parse_links(url) do
    case :ets.lookup(@body_table, url) do
      [{_, body}] ->
        body
        |> Floki.parse_document!()
        |> Floki.find("a")
        |> Enum.map(fn {_elem, attributes, _} ->
          attributes
          |> Map.new()
          |> Map.get("href", nil)
          |> to_absolute(url)
        end)
        |> Enum.reject(&is_nil/1)

      [] ->
        []
    end
  end

  def to_absolute(nil, _), do: nil

  def to_absolute(href, original_url) do
    original_url
    |> URI.merge(href)
    |> URI.to_string()
    |> String.split("#")
    |> hd()
    |> case do
      "http://" <> _ = url -> url
      "https://" <> _ = url -> url
      _ -> nil
    end
  end

  def url_to_hash(url) do
    :crypto.hash(:sha256, url) |> Base.encode16() |> String.downcase()
  end

  def should_crawl?(url) do
    case :ets.lookup(@body_table, url) do
      [_] -> false
      [] -> String.contains?(url, "underjord.io")
    end
  end

  defp ensure_tables do
    case :ets.whereis(@lock_table) do
      :undefined -> :ets.new(@lock_table, [:named_table, :public, :set])
      table_ref -> table_ref
    end

    case :ets.whereis(@body_table) do
      :undefined -> :ets.new(@body_table, [:named_table, :public, :set])
      table_ref -> table_ref
    end
  end

  def acquire_lock?(url) do
    :ets.insert_new(@lock_table, {url, self()})
  end

  def clear_lock(url) do
    :ets.delete(@lock_table, url)
  end
end
