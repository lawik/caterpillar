defmodule Caterpillar.MixProject do
  use Mix.Project

  def project do
    [
      app: :caterpillar,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Caterpillar.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~>  0.7"},
      {:floki, "~> 0.30"}
    ]
  end
end
