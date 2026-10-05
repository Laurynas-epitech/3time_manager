defmodule TimeManager.AccountsFixtures do
  @moduledoc "Test helpers for users."

  def unique_email, do: "user#{System.unique_integer([:positive])}@example.com"

  def valid_password, do: "secret123"

  @doc "Creates a user with the given role (employee by default)."
  def user_fixture(attrs \\ %{}, role \\ "employee") do
    attrs =
      attrs
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Enum.into(%{
        "username" => "some username",
        "email" => unique_email(),
        "password" => valid_password()
      })

    {:ok, user} = TimeManager.Accounts.create_user(attrs, role)
    user
  end
end
