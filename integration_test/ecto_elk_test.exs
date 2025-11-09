defmodule EctoElkTest do
  use ExUnit.Case
  doctest EctoElk

  defmodule TestRepo do
    use Ecto.Repo, otp_app: Mix.Project.config()[:app], adapter: EctoElk.Adapter
  end

  test "greets the world" do
    assert {:ok, _} = TestRepo.start_link()
  end
end
