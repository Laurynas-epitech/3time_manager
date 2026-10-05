defmodule TimeManager.Accounts.Role do
  use Ecto.Schema

  @names ~w(employee manager admin)

  schema "roles" do
    field :name, :string

    has_many :users, TimeManager.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def names, do: @names
end
