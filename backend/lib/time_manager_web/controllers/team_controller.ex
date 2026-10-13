defmodule TimeManagerWeb.TeamController do
  use TimeManagerWeb, :controller

  alias TimeManager.{Accounts, Teams}
  alias TimeManagerWeb.Authorization

  action_fallback TimeManagerWeb.FallbackController

  # admin: all teams / others: teams they manage or belong to
  def index(conn, params) do
    current = conn.assigns.current_user

    teams =
      if Authorization.admin?(current),
        do: Teams.list_teams(params),
        else: Teams.list_teams_for_user(current.id, params)

    render(conn, :index, teams: teams)
  end

  def show(conn, %{"id" => id}) do
    current = conn.assigns.current_user
    team = Teams.get_team!(id)

    visible? =
      Authorization.admin?(current) or team.manager_id == current.id or
        Teams.member?(team.id, current.id)

    if visible?, do: render(conn, :show, team: team), else: {:error, :forbidden}
  end

  def members(conn, %{"id" => id} = params) do
    current = conn.assigns.current_user
    team = Teams.get_team!(id)

    if Authorization.admin?(current) or team.manager_id == current.id or
         Teams.member?(team.id, current.id) do
      users = Teams.list_members(team.id, params)
      json(conn, %{data: Enum.map(users, &TimeManagerWeb.UserJSON.data/1)})
    else
      {:error, :forbidden}
    end
  end

  # Admin only (see router)
  def create(conn, %{"team" => team_params}) do
    with :ok <- validate_manager(team_params),
         {:ok, team} <- Teams.create_team(team_params) do
      conn
      |> put_status(:created)
      |> render(:show, team: team)
    end
  end

  # Admin only (see router)
  def update(conn, %{"id" => id, "team" => team_params}) do
    team = Teams.get_team!(id)

    with :ok <- validate_manager(team_params),
         {:ok, team} <- Teams.update_team(team, team_params) do
      render(conn, :show, team: team)
    end
  end

  # Admin only (see router)
  def delete(conn, %{"id" => id}) do
    with {:ok, _} <- Teams.delete_team(Teams.get_team!(id)) do
      send_resp(conn, :no_content, "")
    end
  end

  # Admin or the team's manager
  def add_member(conn, %{"team_id" => team_id, "user_id" => user_id}) do
    team = Teams.get_team!(team_id)

    with :ok <- authorize(Authorization.can_manage_team?(conn.assigns.current_user, team)),
         user when not is_nil(user) <- Accounts.get_user(Authorization.to_int(user_id)),
         :ok <- authorize(Authorization.can_assign_team_member?(conn.assigns.current_user, user)),
         {:ok, team} <- Teams.add_member(team, user) do
      render(conn, :show, team: team)
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  # Admin or the team's manager
  def remove_member(conn, %{"team_id" => team_id, "user_id" => user_id}) do
    team = Teams.get_team!(team_id)

    with :ok <- authorize(Authorization.can_manage_team?(conn.assigns.current_user, team)),
         id when is_integer(id) <- Authorization.to_int(user_id),
         {:ok, team} <- Teams.remove_member(team, id) do
      render(conn, :show, team: team)
    else
      nil -> {:error, :bad_request}
      error -> error
    end
  end

  # The manager of a team must have the manager (or admin) role.
  defp validate_manager(%{"manager_id" => manager_id}) when manager_id not in [nil, ""] do
    case Accounts.get_user(Authorization.to_int(manager_id)) do
      nil ->
        {:error, :not_found}

      user ->
        if Accounts.role_name(user) in ["manager", "admin"],
          do: :ok,
          else: {:error, :invalid_role}
    end
  end

  defp validate_manager(_), do: :ok

  defp authorize(true), do: :ok
  defp authorize(_), do: {:error, :forbidden}
end
