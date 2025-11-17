defmodule TestRepo do
  @moduledoc false

  use Ecto.Repo, otp_app: Mix.Project.config()[:app], adapter: EctoElk.Adapter
end

defmodule EctoElk.Model do
  @moduledoc false

  defmacro __using__(_) do
    parent = __MODULE__

    quote do
      use Ecto.Schema
      import Ecto.Changeset
      alias unquote(parent)
    end
  end
end

defmodule EctoElk.Model.User do
  @moduledoc false

  use EctoElk.Model
  @primary_key false

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:age, :integer, default: 0)
  end

  def changeset(%__MODULE__{} = rec, attrs \\ %{}) do
    cast(rec, attrs, [:name, :email, :age])
  end
end
