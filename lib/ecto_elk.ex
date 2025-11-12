defmodule EctoElk do
  defmodule Error do
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
    use PrivateModule
    defstruct stacktrace: false
  end

  defmodule Adapter do
    @behaviour Ecto.Adapter
    @behaviour Ecto.Adapter.Queryable
    @behaviour Ecto.Adapter.Storage

    @impl Ecto.Adapter
    defmacro __before_compile__(_opts), do: :ok

    @impl Ecto.Adapter
    def ensure_all_started(_config, _type), do: {:ok, []}

    @impl Ecto.Adapter
    def init(config) do
      {:ok, repo} = Keyword.fetch(config, :repo)
      child_spec = __MODULE__.Supervisor.child_spec(repo)
      meta = %__MODULE__.Meta{}
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

      Req.get!(elk_url(opts, "_aliases"))
      |> storage_response()
    end

    @impl Ecto.Adapter.Storage
    def storage_up(opts) do
      opts = Keyword.validate!(opts, [:hostname, :port, :index_name])
      index_name = Keyword.fetch!(opts, :index_name)

      Req.put!(elk_url(opts, index_name))
      |> storage_response()
    end

    defp storage_response(%Req.Response{} = resp) do
      if(resp.status == 200, do: :ok, else: {:error, format_error(resp)})
    end

    defp elk_url(opts, endpoint) do
      hostname = Keyword.fetch!(opts, :hostname)
      port = Keyword.fetch!(opts, :port)

      "http://#{hostname}:#{port}/#{endpoint}"
    end

    defp format_error(%Req.Response{body: body} = resp) do
      %EctoElk.Error{message: get_in(body, ["error", "reason"]), root_cause: resp}
    end
  end
end
