defmodule EctoElk do
  @moduledoc false

  defmodule Error do
    @moduledoc false

    defexception [:message, :root_cause]
  end

  defmodule Adapter.Supervisor do
    @moduledoc false

    use PrivateModule
    use Supervisor

    def start_link(repo) do
      Supervisor.start_link(__MODULE__, repo)
    end

    @impl Supervisor
    def init(_repo) do
      children = []
      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  defmodule Adapter.Meta do
    @moduledoc false

    use PrivateModule
    defstruct [:hostname, :port, stacktrace: false]

    @behaviour Access
    defdelegate get(v, key, default), to: Map
    defdelegate fetch(v, key), to: Map
    defdelegate get_and_update(v, key, func), to: Map
    defdelegate pop(v, key), to: Map
  end

  defmodule Adapter do
    @moduledoc false

    @behaviour Ecto.Adapter
    @behaviour Ecto.Adapter.Schema
    @behaviour Ecto.Adapter.Queryable
    @behaviour Ecto.Adapter.Storage

    @impl Ecto.Adapter
    defmacro __before_compile__(_opts), do: :ok

    @impl Ecto.Adapter
    def ensure_all_started(_config, _type), do: {:ok, []}

    @impl Ecto.Adapter
    def init(config) do
      {:ok, repo} = Keyword.fetch(config, :repo)
      hostname = Keyword.fetch!(config, :hostname)
      port = Keyword.fetch!(config, :port)
      child_spec = __MODULE__.Supervisor.child_spec(repo)
      meta = %__MODULE__.Meta{hostname: hostname, port: port}
      {:ok, child_spec, meta}
    end

    @impl Ecto.Adapter
    def checkout(_, _, fun), do: fun.()

    @impl Ecto.Adapter
    def checked_out?(_), do: false

    @impl Ecto.Adapter
    def loaders(_, type), do: [type]

    @impl Ecto.Adapter
    def dumpers(_, type), do: [type]

    @impl Ecto.Adapter.Queryable
    def prepare(operation, %Ecto.Query{} = query) do
      {:nocache, {operation, query}}
    end

    @impl Ecto.Adapter.Queryable
    def execute(adapter_meta, query_meta, {:nocache, {:all, query}}, params, options) do
      timeout = Keyword.get(options, :timeout, 15_000)
      sql_from = from(query)
      {sql_select, returning_columns} = select(query_meta, query)
      sql_where = where(query, params)
      sql_limit = limit(query)

      sql_result =
        EctoElk.Adapter.Connection.sql_call(
          adapter_meta,
          "SELECT #{sql_select} FROM #{sql_from} #{sql_where} #{sql_limit}",
          returning_columns,
          timeout: timeout
        )

      case sql_result do
        {:ok, records} ->
          {Enum.count(records), records}

        {:error, error} ->
          raise error
      end
    end

    def execute(%{repo: _repo}, _query_meta, _query_cache, _params, _opts) do
      {0, []}
    end

    @impl Ecto.Adapter.Queryable
    def stream(_adapter_meta, _query_meta, _query_cache, _params, _opts) do
      []
    end

    @impl Ecto.Adapter.Storage
    def storage_down(_opts) do
      :ok
    end

    @impl Ecto.Adapter.Storage
    def storage_status(opts) do
      opts = Keyword.validate!(opts, [:hostname, :port])

      EctoElk.Adapter.Connection.indexes(opts)
    end

    @impl Ecto.Adapter.Storage
    def storage_up(opts) do
      opts = Keyword.validate!(opts, [:hostname, :port, :index_name])
      index_name = Keyword.fetch!(opts, :index_name)

      EctoElk.Adapter.Connection.create_index(opts, index_name)
    end

    @impl Ecto.Adapter.Schema
    def autogenerate(field_type), do: raise("not implemented #{inspect(field_type)}")

    @impl Ecto.Adapter.Schema
    def delete(_adapter_meta, _schema_meta, _filters, _returning_, _options),
      do: raise("not implemented")

    @impl Ecto.Adapter.Schema
    def insert(adapter_meta, schema_meta, fields, _on_conflict, _returning, _options) do
      %{source: source} = schema_meta

      :ok = EctoElk.Adapter.Connection.create_doc(adapter_meta, source, Map.new(fields))
      {:ok, []}
    end

    @impl Ecto.Adapter.Schema
    def insert_all(
          _adapter_meta,
          _schema_meta,
          _header,
          _list,
          _on_conflict,
          _returning_,
          _placeholders,
          _options
        ),
        do: raise("not implemented")

    @impl Ecto.Adapter.Schema
    def update(_adapter_meta, _schema_meta, _fields, _filters, _returning, _options),
      do: raise("not implemented")

    defp limit(%{limit: %Ecto.Query.LimitExpr{expr: limit}}) when is_integer(limit) do
      "LIMIT #{limit}"
    end

    defp limit(_query), do: ""

    defp where(%{wheres: [%Ecto.Query.BooleanExpr{} = expr]}, params) do
      "WHERE #{build_conditions(expr.expr, params)}"
    end

    defp where(_query, _params) do
      ""
    end

    defp build_conditions({op, [], [lhs, rhs]}, params) do
      lhs_condition = build_conditions(lhs, params)
      rhs_condition = build_conditions(rhs, params)
      "#{lhs_condition} #{sql_op(op)} #{rhs_condition}"
    end

    defp build_conditions(
           # what means?
           {{:., [], [{:&, [], [0]}, field_name]}, [], []},
           _params
         ) do
      field_name
    end

    defp build_conditions({:^, [], [field_index]}, params) do
      "'#{Enum.at(params, field_index) |> escape_string()}'"
    end

    defp build_conditions(value, _params) when is_integer(value) do
      value
    end

    defp build_conditions(value, _params) when is_binary(value) do
      "'#{escape_string(value)}'"
    end

    defp build_conditions(values, params) when is_list(values) do
      sql =
        Enum.map_join(values, ",", fn value ->
          build_conditions(value, params)
        end)

      "(#{sql})"
    end

    defp build_select({:count, [], []}, _params) do
      "COUNT(1)"
    end

    defp build_select({:sum, [], [{{:., _, [{:&, [], [0]}, field_name]}, [], []}]}, _params) do
      ~s[SUM("#{field_name}")]
    end

    defp build_select({:max, [], [{{:., _, [{:&, [], [0]}, field_name]}, [], []}]}, _params) do
      ~s[MAX("#{field_name}")]
    end

    defp build_select({:min, [], [{{:., _, [{:&, [], [0]}, field_name]}, [], []}]}, _params) do
      ~s[MIN("#{field_name}")]
    end

    defp build_select({:avg, [], [{{:., _, [{:&, [], [0]}, field_name]}, [], []}]}, _params) do
      ~s[AVG("#{field_name}")]
    end

    defp from(query) do
      {index_name, _schema} = query.from.source
      index_name
    end

    defp select(%{select: %{from: :none}} = _query_meta, query) do
      {build_select(query.select.expr, []), []}
    end

    defp select(query_meta, _query) do
      {_, {:source, _, _, returning_columns}} = query_meta[:select][:from]

      sql_columns = Enum.map_join(returning_columns, ",", &elem(&1, 0))
      {sql_columns, returning_columns}
    end

    # https://www.elastic.co/docs/reference/query-languages/sql/sql-functions
    defp sql_op(:and), do: "AND"
    defp sql_op(:or), do: "OR"
    defp sql_op(:in), do: "IN"
    defp sql_op(:!=), do: "!="
    defp sql_op(:==), do: "="
    defp sql_op(:>), do: ">"
    defp sql_op(:<), do: "<"
    defp sql_op(:>=), do: ">="
    defp sql_op(:<=), do: "<="
    defp sql_op(:+), do: "+"
    defp sql_op(:-), do: "-"

    # TAKEN_FROM: https://github.com/elixir-ecto/ecto_sql/blob/a703c2edb90d3b85ca55767e12877da4f221faa9/lib/ecto/adapters/tds/connection.ex#L1815
    defp escape_string(value) when is_binary(value) do
      value |> :binary.replace("'", "\'", [:global])
    end

    defp escape_string(value), do: value
  end
end
