defmodule EctoElk.Model do
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
  use EctoElk.Model
  @primary_key {:user_id, :id, autogenerate: false}

  schema "users" do
    field(:name, :string)
    field(:email, :string)
  end
end
