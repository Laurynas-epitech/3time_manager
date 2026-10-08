defmodule TimeManagerWeb.Authorization do
  @moduledoc """
  Who can see / change what.

    * admin    -> everything
    * manager  -> themselves + members of the teams they manage
    * employee -> only themselves
  """

  alias TimeManager.Accounts
  alias TimeManager.Accounts.User
  alias TimeManager.Teams

  def admin?(user), do: Accounts.role_name(user) == "admin"
  def manager?(user), do: Accounts.role_name(user) == "manager"

  @doc "Can `current` read data (profile, clocks, working times) of `user_id`?"
  def can_view_user?(%User{} = current, user_id) do
    user_id = to_int(user_id)

    cond do
      admin?(current) -> true
      is_nil(user_id) -> false
      current.id == user_id -> true
      manager?(current) -> Teams.manages_user?(current.id, user_id)
      true -> false
    end
  end

  @doc "Can `current` create/edit/delete working times of `user_id`?"
  def can_manage_working_times?(%User{} = current, user_id) do
    user_id = to_int(user_id)

    cond do
      admin?(current) -> true
      is_nil(user_id) -> false
      manager?(current) -> current.id == user_id or Teams.manages_user?(current.id, user_id)
      true -> false
    end
  end

  @doc "Clocking in/out: yourself, or any user if you are an admin."
  def can_clock?(%User{} = current, user_id) do
    admin?(current) or current.id == to_int(user_id)
  end

  @doc "Editing / deleting a user account: yourself or an admin."
  def can_edit_user?(%User{} = current, user_id) do
    admin?(current) or current.id == to_int(user_id)
  end

  def can_manage_team?(%User{} = current, team) do
    admin?(current) or (manager?(current) and Teams.manages_team?(current.id, team))
  end

  def to_int(value) when is_integer(value), do: value

  def to_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> nil
    end
  end

  def to_int(_), do: nil
end
