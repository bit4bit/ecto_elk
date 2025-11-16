# EctoElk

Since Elasticsearch has support for a subset of SQL, I will do a small exercise implementing an adapter for Ecto.


**config.exs**
```elixir
config :ecto_elk, MyRepo,
  hostname: "localhost"
  port: 9200,
  secure: false #true to enable https
```

use adapter.

```elixir
defmodule MyRepo do
  use Ecto.Repo, otp_app: :my_app, adapter: EctoElk.Adapter
end
```


## Guides

- https://github.com/evadne/etso/
- https://hexdocs.pm/ecto/3.11.2/Ecto.Adapter.html

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_elk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_elk, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ecto_elk>.

