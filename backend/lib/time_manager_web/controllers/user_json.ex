defmodule TimeManagerWeb.UserJSON do
  alias TimeManager.Accounts.{Role, User}

  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  def show(%{user: user}) do
    %{data: data(user)}
  end

  @doc "Never exposes the password hash. The role name comes from the association."
  def data(%User{} = user) do
    %{
      id: user.id,
      username: user.username,
      email: user.email,
      role: role_name(user.role)
    }
  end

  defp role_name(%Role{name: name}), do: name
  defp role_name(_), do: nil
end
