defmodule EctoElk.Adapter.Connection do
  @moduledoc false

  use PrivateModule

  def sql_call(conn_meta, sql, returning_columns, options) do
    timeout = Keyword.fetch!(options, :timeout)

    req =
      Req.new(
        url: elk_url(conn_meta, "_sql?format=json"),
        json: %{"query" => sql},
        receive_timeout: timeout
      )

    resp = Req.post(req)

    case resp do
      {:ok, %{status: 200} = resp} ->
        columns = Enum.map(resp.body["columns"], &Map.fetch!(&1, "name"))

        records =
          Enum.map(resp.body["rows"], fn row ->
            Enum.zip(columns, row)
            |> Map.new()
            |> record_ordered(returning_columns)
          end)

        {:ok, records}

      {:ok, resp} ->
        {:error, format_error(resp)}

      {:error, resp} ->
        {:error, format_error(resp)}
    end
  end

  def create_doc(conn_meta, source, doc) do
    req = Req.new(url: elk_url(conn_meta, "#{source}/_doc/?refresh=true"), json: doc)

    case Req.post!(req) do
      %{status: 201} ->
        :ok

      resp ->
        {:error, format_error(resp)}
    end
  end

  def create_index(conn_meta, name) do
    req = Req.new(url: elk_url(conn_meta, name))

    case Req.put!(req) do
      %{status: 200} -> :ok
      resp -> {:error, format_error(resp)}
    end
  end

  def indexes(conn_meta) do
    req = Req.new(url: elk_url(conn_meta, "_aliases"))

    case Req.get!(req) do
      %{status: 200} -> :ok
      resp -> {:error, format_error(resp)}
    end
  end

  defp format_error(%Req.TransportError{reason: reason} = error) do
    %EctoElk.Error{message: "Transport error: #{inspect(reason)}", root_cause: error}
  end

  defp format_error(%Req.Response{body: body} = resp) do
    %EctoElk.Error{message: get_in(body, ["error", "reason"]), root_cause: resp}
  end

  defp elk_url(opts, endpoint) do
    secure = if(opts[:secure], do: "s", else: "")
    "http#{secure}://#{opts[:hostname]}:#{opts[:port]}/#{endpoint}"
  end

  defp record_ordered(record, []) do
    Map.values(record)
  end

  defp record_ordered(record, returning_columns) do
    Enum.map(returning_columns, fn {returning_column, _type} ->
      Map.fetch!(record, to_string(returning_column))
    end)
  end
end
