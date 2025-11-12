defmodule EctoElkTest do
  use ExUnit.Case

  alias EctoElk.Model

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
  end
end
