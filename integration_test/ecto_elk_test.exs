defmodule EctoElkTest do
  use ExUnit.Case, async: false

  alias EctoElk.Model
  alias EctoElk.Adapter

  describe "EctoElk.Adapter" do
    setup do
      delete_index("users")

      {:ok, _} = start_supervised(%{id: __MODULE__, start: {TestRepo, :start_link, []}})
      :ok
    end

    test "insert" do
      name = a_name()

      Model.User.changeset(%Model.User{}, %{name: name, email: "mero"})
      |> TestRepo.insert!()
    end

    test "list all" do
      name = a_name()
      
      Model.User.changeset(%Model.User{}, %{name: name, email: "mero"})
      |> TestRepo.insert!()


      assert [%Model.User{name: ^name}] = TestRepo.all(Model.User)
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
    %{} = Req.get!(elk_url("/_aliases")).body
  end

  defp delete_index(name) do
    Req.delete!(elk_url("/#{name}"))
  end
  
  defp elk_url(endpoint) do
    elastic_host = System.fetch_env!("ELASTICSEARCH_HOST")
    "http://#{elastic_host}:9200#{endpoint}"
  end
end
