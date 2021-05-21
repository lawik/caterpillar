defmodule Caterpillar do
  @dir "files"

  require Logger

  # TODO: Add check for robots.txt and respect it
  # TODO: Add finches per domain
  # TODO: Improve prevention of duplicate crawls? Not super important

  # TODO: Set up more serious orchestration of fetching URL contents vs parsing links vs rechecking
  # TODO: Save data on linking and relationships (build the graphy thing)

  # TODO: Add a nice user agent
  # TODO: Find out which domains have been visited
  # TODO: Unleash on web when it can behave

  def crawl_url(url) do
    case get_url(url) do
      :ok ->
        url
        |> parse_links()
        |> Enum.each(fn link_url ->
          Task.start(fn ->
            if should_crawl?(link_url) do
              Logger.info("URL: #{url}")
              crawl_url(link_url)
            end
          end)
        end)

      :skip ->
        :ok
    end
  end

  @spec get_url(binary | URI.t()) :: :ok | :skip
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

      error ->
        raise "failed #{inspect(error)}"
    end
  end

  def save_url(url, body) do
    File.mkdir_p!(@dir)
    File.write!(get_url_filepath(url), body)
  end

  def parse_links(url) do
    url
    |> get_url_filepath()
    |> File.read!()
    |> Floki.parse_document!()
    |> Floki.find("a")
    |> Enum.map(fn {_elem, attributes, _} ->
      attributes
      |> Map.new()
      |> Map.get("href", nil)
      |> to_absolute(url)
    end)
    |> Enum.reject(&is_nil/1)
  end

  def to_absolute(nil, _), do: nil

  def to_absolute(href, original_url) do
    original_url
    |> URI.merge(href)
    |> URI.to_string()
    |> case do
      "http://" <> _ = url -> url
      "https://" <> _ = url -> url
      _ -> nil
    end
  end

  def get_url_filepath(url) do
    hash = url_to_hash(url)
    Path.join(@dir, hash)
  end

  def url_to_hash(url) do
    :crypto.hash(:sha256, url) |> Base.encode16() |> String.downcase()
  end

  def should_crawl?(url) do
    filepath = get_url_filepath(url)
    not File.exists?(filepath) and String.contains?(url, "underjord.io")
  end
end
