defmodule EctoElkTest do
  use ExUnit.Case

  alias EctoElk.Model
  alias EctoElk.Adapter

  defmodule TestRepo do
    use Ecto.Repo, otp_app: Mix.Project.config()[:app], adapter: EctoElk.Adapter
  end

  describe "EctoElk.Adapter" do
    setup do
      {:ok, _} = start_supervised(%{id: __MODULE__, start: {TestRepo, :start_link, []}})
      :ok
    end

    test "list empty" do
      assert TestRepo.all(Model.User) == []
    end

    test "storage_status" do
      :ok = Adapter.storage_status(
              [hostname: System.fetch_env!("ELASTICSEARCH_HOST"),
               port: 9200])
    end

    test "storage_up" do
      index_name = a_name()

      :ok = Adapter.storage_up([hostname: System.fetch_env!("ELASTICSEARCH_HOST"), port: 9200, index_name: index_name])

      assert exists_elk_index?(index_name)
    end
  end

  defp a_name() do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp exists_elk_index?(name) do
    Map.has_key?(elk_indexes(), name)
  end

  defp elk_indexes() do
    elastic_host = System.fetch_env!("ELASTICSEARCH_HOST")
    Req.get!("http://#{elastic_host}:9200/_aliases").body
  end
end
