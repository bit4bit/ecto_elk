defmodule EctoElk.Adapter.Connection do
  @moduledoc false

  use PrivateModule

  def sql_call(conn_meta, sql, returning_columns) do
    resp =
      Req.post!(elk_url(conn_meta, "_sql?format=json"),
        json: %{
          "query" => sql
        }
      )

    %{status: 200} = resp
    columns = Enum.map(resp.body["columns"], &Map.fetch!(&1, "name"))

    records =
      Enum.map(resp.body["rows"], fn row ->
        record = Enum.zip(columns, row) |> Map.new()

        Enum.map(returning_columns, fn {returning_column, _type} ->
          Map.fetch!(record, to_string(returning_column))
        end)
      end)

    {:ok, records}
  end

  def create_doc(conn_meta, source, doc) do
    case Req.post!(elk_url(conn_meta, "#{source}/_doc/?refresh=true"), json: doc) do
      %{status: 201} ->
        :ok

      resp ->
        {:error, format_error(resp)}
    end
  end

  def create_index(conn_meta, name) do
    case Req.put!(elk_url(conn_meta, name)) do
      %{status: 200} -> :ok
      resp -> {:error, format_error(resp)}
    end
  end

  def indexes(conn_meta) do
    case Req.get!(elk_url(conn_meta, "_aliases")) do
      %{status: 200} -> :ok
      resp -> {:error, format_error(resp)}
    end
  end

  defp format_error(%Req.Response{body: body} = resp) do
    %EctoElk.Error{message: get_in(body, ["error", "reason"]), root_cause: resp}
  end

  defp elk_url(opts, endpoint) do
    "http://#{opts[:hostname]}:#{opts[:port]}/#{endpoint}"
  end
end
