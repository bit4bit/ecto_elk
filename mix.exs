defmodule EctoElk.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_elk,
      version: "0.1.0",
      elixir: "~> 1.14",
      compilers: [:private_module] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      test_paths: test_paths(System.get_env("INTEGRATION")),
      config_path: "./config/config.exs",
      deps: deps(),
      elixirc_options: [
        warnings_as_errors: true
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  defp aliases do
    [compile: "compile --force --warnings-as-errors"]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(nil), do: ["test"]
  defp test_paths(_), do: ["integration_test"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.11.0"},
      {:elastix, ">= 0.0.0"},
      {:req, "~> 0.5.15"},
      {:private_module, ">= 0.0.0"},
      {:testcontainers, "~> 1.13", only: [:test, :dev]},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false}
    ]
  end
end
