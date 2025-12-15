# EctoElk

A working Ecto adapter for Elasticsearch that leverages Elasticsearch's SQL support to enable familiar Ecto query patterns for Elasticsearch indices.

## Supported Features

### Query Operations
- **SELECT queries** - Retrieve records from Elasticsearch indices
- **WHERE clauses** - Filter records with conditions
- **LIMIT** - Limit the number of results returned
- **ORDER BY** - Sort results (ASC/DESC, single and multiple columns)
- **GROUP BY** - Group results by columns

### Query Operators
- **Comparison operators**: `==`, `!=`, `>`, `<`, `>=`, `<=`
- **Logical operators**: `AND`, `OR`
- **Membership operator**: `IN`
- **Null checks**: `IS NULL`, `IS NOT NULL`
- **Arithmetic operators**: `+`, `-`, `*`, `/`

### Aggregate Functions
- `COUNT()` - Count records
- `SUM()` - Sum numeric values
- `AVG()` - Average of numeric values
- `MAX()` - Maximum value
- `MIN()` - Minimum value

### Schema Operations
- **INSERT** - Insert single documents into indices
- Custom SELECT projections (single and multiple columns)

### Storage Operations
- **storage_up** - Create Elasticsearch indices
- **storage_status** - Check index status
- **storage_down** - Remove indices

### Type Support
- String (VARCHAR)
- Integer (INT)

### Query Features
- Parameter interpolation with `^` operator
- String escaping for SQL injection prevention
- Custom timeout configuration
- Aggregate queries with WHERE conditions
- Complex SELECT expressions with type casting

## Limitations

The following Ecto features are **not yet implemented**:
- UPDATE operations
- DELETE operations
- INSERT_ALL (bulk inserts)
- JOINS
- Subqueries
- Transactions
- Locking
- Migrations
- Autogenerate for primary keys
- Streams


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

## Contributing

```bash
$ INTEGRATION=1 mix test
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

