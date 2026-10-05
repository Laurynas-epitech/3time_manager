defmodule TimeManagerWeb.UserController do
  use TimeManagerWeb, :controller

  alias TimeManager.{Accounts, Teams}
  alias TimeManager.Accounts.User
  alias TimeManagerWeb.Authorization

  action_fallback TimeManagerWeb.FallbackController

  # admin: everybody / manager: self + team members / employee: self
  # `?scope=all` lets managers see the whole directory (to add people to a team);
  # it does not give access to anyone's clocks or working times.
  def index(conn, params) do
    current = conn.assigns.current_user

    users =
      cond do
        Authorization.admin?(current) ->
          Accounts.list_users()

        Authorization.manager?(current) and params["scope"] == "all" ->
          Accounts.list_users()

        Authorization.manager?(current) ->
          Accounts.list_users_by_ids([current.id | Teams.managed_user_ids(current.id)])

        true ->
          [current]
      end
      |> Enum.filter(fn user ->
        (is_nil(params["email"]) or user.email == params["email"]) and
          (is_nil(params["username"]) or user.username == params["username"])
      end)

    render(conn, :index, users: users)
  end

  # Admin only (see router): create a user with any role.
  def create(conn, %{"user" => user_params}) do
    role = user_params["role"] || "employee"

    with {:ok, %User{} = user} <- Accounts.create_user(user_params, role) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/users/#{user}")
      |> render(:show, user: user)
    end
  end

  def show(conn, %{"id" => id}) do
    with :ok <- authorize(Authorization.can_view_user?(conn.assigns.current_user, id)) do
      render(conn, :show, user: Accounts.get_user!(id))
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    with :ok <- authorize(Authorization.can_edit_user?(conn.assigns.current_user, id)),
         user = Accounts.get_user!(id),
         {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, :show, user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    with :ok <- authorize(Authorization.can_edit_user?(conn.assigns.current_user, id)),
         user = Accounts.get_user!(id),
         {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  # Admin only (see router): promote / demote. Body: {"role": "manager"}
  def update_role(conn, %{"id" => id, "role" => role}) do
    current = conn.assigns.current_user
    user = Accounts.get_user!(id)

    cond do
      # Avoid an admin locking everybody out by demoting themselves.
      user.id == current.id and role != "admin" ->
        {:error, :forbidden}

      true ->
        with {:ok, user} <- Accounts.update_user_role(user, role) do
          render(conn, :show, user: user)
        end
    end
  end

  def update_role(_conn, _params), do: {:error, :bad_request}

  defp authorize(true), do: :ok
  defp authorize(_), do: {:error, :forbidden}
end
