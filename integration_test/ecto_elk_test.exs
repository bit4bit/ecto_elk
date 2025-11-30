defmodule EctoElkTest do
  use ExUnit.Case, async: false

  require Ecto.Query
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

    test "list all with timeout" do
      name = a_name()

      for _ <- [1..10000] do
        a_user(a_name(), a_email())
      end

      assert_raise EctoElk.Error, fn ->
        assert [%Model.User{name: ^name}] = TestRepo.all(Model.User, timeout: 0)
      end
    end

    test "aggregate count" do
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 11)
      a_user(a_name(), a_email(), age: 22)

      assert TestRepo.aggregate(Model.User, :count) == 3
    end

    test "aggregate count using query" do
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 11)
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 22)

      query = Ecto.Query.from(u in Model.User, where: u.age == 33)

      assert TestRepo.aggregate(query, :count) == 2
    end

    test "aggregate sum" do
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 11)
      a_user(a_name(), a_email(), age: 22)

      assert TestRepo.aggregate(Model.User, :sum, :age) == 33 + 11 + 22
    end

    test "aggregate sum using query" do
      a_user(a_name(), a_email(), [age: 33])
      a_user(a_name(), a_email(), [age: 11])
      a_user(a_name(), a_email(), [age: 33])
      a_user(a_name(), a_email(), [age: 22])

      query = Ecto.Query.from(u in Model.User, where: u.age == 33)

      assert TestRepo.aggregate(query, :sum, :age) == 33 + 33
    end

    test "aggregate max" do
      a_user(a_name(), a_email(), age: 11)
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 22)

      assert TestRepo.aggregate(Model.User, :max, :age) == 33
    end

    test "aggregate max using query" do
      a_user(a_name(), a_email(), age: 11)
      a_user(a_name(), a_email(), age: 5)
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 22)

      query = Ecto.Query.from(u in Model.User, where: u.age < 15)

      assert TestRepo.aggregate(query, :max, :age) == 11
    end

    test "aggregate min" do
      a_user(a_name(), a_email(), age: 11)
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 22)

      assert TestRepo.aggregate(Model.User, :min, :age) == 11
    end

    test "aggregate min using query" do
      a_user(a_name(), a_email(), age: 11)
      a_user(a_name(), a_email(), age: 5)
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 22)

      query = Ecto.Query.from(u in Model.User, where: u.age < 15)

      assert TestRepo.aggregate(query, :min, :age) == 5
    end

    test "aggregate avg" do
      a_user(a_name(), a_email(), age: 5)
      a_user(a_name(), a_email(), age: 5)
      a_user(a_name(), a_email(), age: 5)
      a_user(a_name(), a_email(), age: 5)

      assert TestRepo.aggregate(Model.User, :avg, :age) == 5.0
    end

    test "aggregate avg using query" do
      a_user(a_name(), a_email(), age: 5)
      a_user(a_name(), a_email(), age: 5)
      a_user(a_name(), a_email(), age: 5)
      a_user(a_name(), a_email(), age: 5)


      query = Ecto.Query.from(u in Model.User, where: u.age == 5)

      assert TestRepo.aggregate(query, :avg, :age) == 5.0
    end

    test "query using custom select one column" do
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 11)

      query =
        Ecto.Query.from(u in Model.User, select: {u.age})

      assert [{33}, {11}] = TestRepo.all(query)
    end

    test "query using custom select multi column" do
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 11)

      query =
        Ecto.Query.from(u in Model.User, select: {u.name, u.age})

      assert [{_, 33}, {_, 11}] = TestRepo.all(query)
    end

    test "query where AND one column" do
      name = a_name()
      a_user(name, "mero")
      a_user(a_name(), "mero2")

      query =
        Ecto.Query.from(u in Model.User, where: u.name == ^name and u.email == "mero" and 1 == 1)

      assert [%Model.User{name: ^name}] = TestRepo.all(query)
    end

    test "query where IN one column" do
      name = a_name()
      name2 = "demo"
      a_user(name, "mero")
      a_user(a_name(), "mero2")

      query = Ecto.Query.from(u in Model.User, where: u.name in [^name, "demo", ^name2])

      assert [%Model.User{name: ^name}] = TestRepo.all(query)
    end

    test "query where = one column" do
      name = a_name()
      a_user(name, "mero")
      a_user(a_name(), "mero2")

      query = Ecto.Query.from(u in Model.User, where: u.name == ^name)

      assert [%Model.User{name: ^name}] = TestRepo.all(query)
    end

    test "query where = one column escapes string" do
      name = a_name()
      a_user(name, "mero")
      a_user(a_name(), "mero2")

      name_query = "#{name}'"
      query = Ecto.Query.from(u in Model.User, where: u.name == ^name_query)

      assert_raise EctoElk.Error, fn ->
        assert [%Model.User{name: ^name}] = TestRepo.all(query)
      end
    end

    test "query where > one column" do
      name = a_name()
      a_user(name, "mero", age: 33)
      a_user(a_name(), "mero2", age: 10)

      query = Ecto.Query.from(u in Model.User, where: u.age > 20)

      assert [%Model.User{name: ^name}] = TestRepo.all(query)
    end

    test "query where >= one column" do
      name = a_name()
      a_user(name, "mero", age: 33)
      a_user(a_name(), "mero2", age: 10)

      query = Ecto.Query.from(u in Model.User, where: u.age >= 20)

      assert [%Model.User{name: ^name}] = TestRepo.all(query)
    end

    test "query where < one column" do
      name = a_name()
      a_user(name, "mero", age: 33)
      a_user(a_name(), "mero2", age: 10)

      query = Ecto.Query.from(u in Model.User, where: u.age < 20)

      assert [%Model.User{email: "mero2"}] = TestRepo.all(query)
    end

    test "query where <= one column" do
      name = a_name()
      a_user(name, "mero", age: 33)
      a_user(a_name(), "mero2", age: 10)

      query = Ecto.Query.from(u in Model.User, where: u.age <= 20)

      assert [%Model.User{email: "mero2"}] = TestRepo.all(query)
    end

    test "query where != one column" do
      name = a_name()
      a_user(name, "mero", age: 33)
      a_user(a_name(), "mero2", age: 10)

      query = Ecto.Query.from(u in Model.User, where: u.age != 10)

      assert [%Model.User{email: "mero", age: 33}] = TestRepo.all(query)
    end

    test "query with limit" do
      a_user(a_name(), a_email())
      a_user(a_name(), a_email())
      a_user(a_name(), a_email())

      query = Ecto.Query.from(u in Model.User, limit: 1)

      assert [%Model.User{}] = TestRepo.all(query)

      query = Ecto.Query.from(u in Model.User, limit: 2)

      assert [%Model.User{}, %Model.User{}] = TestRepo.all(query)

      query = Ecto.Query.from(u in Model.User, limit: 0)

      assert [] = TestRepo.all(query)
    end

    test "query +" do
      name = a_name()
      a_user(name, "mero", age: 33)
      a_user(a_name(), "mero2", age: 10)

      query = Ecto.Query.from(u in Model.User, where: u.age + 1 == 34)

      assert [%Model.User{email: "mero", age: 33}] = TestRepo.all(query)
    end

    test "query where two columns interpolate variable" do
      name = a_name()
      email = "mero2"
      a_user(name, email)
      a_user(a_name(), "mero2")

      query = Ecto.Query.from(u in Model.User, where: u.name == ^name and u.email == ^email)

      assert [%Model.User{name: ^name, email: "mero2"}] = TestRepo.all(query)
    end

    test "query where two columns interpolate constant" do
      name = a_name()
      email = "mero2"
      a_user(name, email)
      a_user(a_name(), "mero2")

      query = Ecto.Query.from(u in Model.User, where: u.name == ^name and u.email == "mero2")

      assert [%Model.User{name: ^name, email: "mero2"}] = TestRepo.all(query)
    end

    test "query OR where two columns interpolate constant" do
      name = a_name()
      email = "mero22"
      a_user(name, email)
      a_user(a_name(), "mero2")

      query = Ecto.Query.from(u in Model.User, where: u.name == ^name or u.email == "mero22")

      assert [%Model.User{name: ^name, email: "mero22"}] = TestRepo.all(query)
    end

    test "order by asc" do
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 11)

      query = Ecto.Query.from(u in Model.User, order_by: [asc: u.age])

      assert [%Model.User{age: 11}, %Model.User{age: 33}] = TestRepo.all(query)

      query = Ecto.Query.from(u in Model.User, order_by: [asc: :age])

      assert [%Model.User{age: 11}, %Model.User{age: 33}] = TestRepo.all(query)
    end

    test "order by desc" do
      a_user(a_name(), a_email(), age: 11)
      a_user(a_name(), a_email(), age: 33)

      query = Ecto.Query.from(u in Model.User, order_by: [desc: u.age])

      assert [%Model.User{age: 33}, %Model.User{age: 11}] = TestRepo.all(query)
    end

    test "order by multi column" do
      a_user(a_name(), a_email(), age: 11)
      a_user(a_name(), a_email(), age: 33)

      query = Ecto.Query.from(u in Model.User, order_by: [desc: u.age, asc: u.name])

      assert [%Model.User{age: 33}, %Model.User{age: 11}] = TestRepo.all(query)
    end

    test "group by one column" do
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 33)
      a_user(a_name(), a_email(), age: 11)

      query =
        Ecto.Query.from(u in Model.User, group_by: u.age, select: {u.age, count(u.age)})

      assert [{11, 1}, {33, 2}] = TestRepo.all(query)
    end


    test "storage_status" do
      :ok =
        Adapter.storage_status(
          hostname: System.fetch_env!("ELASTICSEARCH_HOST"),
          port: 9200
        )
    end

    test "storage_up" do
      index_name = a_name()

      :ok =
        Adapter.storage_up(
          hostname: System.fetch_env!("ELASTICSEARCH_HOST"),
          port: 9200,
          index_name: index_name
        )

      assert exists_elk_index?(index_name)
    end
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

  defp a_name() do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp a_email() do
    a_name()
  end

  defp a_user(name, email, attrs \\ []) do
    Model.User.changeset(%Model.User{}, %{name: name, email: email} |> Map.merge(Map.new(attrs)))
    |> TestRepo.insert!()
  end

  defp elk_url(endpoint) do
    elastic_host = System.fetch_env!("ELASTICSEARCH_HOST")
    "http://#{elastic_host}:9200#{endpoint}"
  end
end
