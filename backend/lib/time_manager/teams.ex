defmodule TimeManager.Teams do
  @moduledoc """
  The Teams context. A team has one manager and many members;
  an employee can belong to several teams.
  """

  import Ecto.Query, warn: false
  alias TimeManager.{Pagination, Repo}

  alias TimeManager.Accounts.User
  alias TimeManager.Teams.Team

  @max_teams 50
  @max_members 100

  @doc "All teams, at most #{@max_teams} per page (`\"limit\"` / `\"offset\"` params)."
  def list_teams(params \\ %{}) do
    Team
    |> order_by(:id)
    |> Pagination.paginate(params, @max_teams)
    |> Repo.all()
    |> Enum.map(&preload_team/1)
  end

  @doc "Teams a user manages or belongs to."
  def list_teams_for_user(user_id, params \\ %{}) do
    from(t in Team,
      left_join: m in assoc(t, :members),
      where: t.manager_id == ^user_id or m.id == ^user_id,
      distinct: true,
      order_by: t.id
    )
    |> Pagination.paginate(params, @max_teams)
    |> Repo.all()
    |> Enum.map(&preload_team/1)
  end

  def get_team!(id), do: Team |> Repo.get!(id) |> preload_team()

  def list_members(team_id, params \\ %{}) do
    member_query(team_id)
    |> Pagination.paginate(params, @max_members)
    |> Repo.all()
    |> Repo.preload(:role)
  end

  def member?(team_id, user_id) do
    from(tu in "team_users", where: tu.team_id == ^team_id and tu.user_id == ^user_id)
    |> Repo.exists?()
  end

  def managed_user_query(manager_id) do
    from(t in Team,
      join: m in assoc(t, :members),
      where: t.manager_id == ^manager_id,
      select: m.id
    )
  end

  def create_team(attrs) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
    |> preload()
  end

  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
    |> preload()
  end

  def delete_team(%Team{} = team), do: Repo.delete(team)

  # Atomic: the unique (team_id, user_id) index turns a repeated add into a
  # no-op, whatever state the `team` struct passed in is in (stale struct,
  # double click, two requests at once).
  def add_member(%Team{} = team, %User{} = user) do
    Repo.insert_all(
      "team_users",
      [%{team_id: team.id, user_id: user.id}],
      on_conflict: :nothing,
      conflict_target: [:team_id, :user_id]
    )

    {:ok, get_team!(team.id)}
  end

  def remove_member(%Team{} = team, user_id) do
    from(tu in "team_users", where: tu.team_id == ^team.id and tu.user_id == ^user_id)
    |> Repo.delete_all()

    {:ok, get_team!(team.id)}
  end

  @doc "True if `manager_id` manages a team that `user_id` is a member of."
  def manages_user?(manager_id, user_id) do
    from(t in Team,
      join: m in assoc(t, :members),
      where: t.manager_id == ^manager_id and m.id == ^user_id
    )
    |> Repo.exists?()
  end

  def manages_team?(manager_id, %Team{manager_id: manager_id}), do: true
  def manages_team?(_, _), do: false

  @doc "Ids of every member of the teams `manager_id` manages."
  def managed_user_ids(manager_id) do
    from(t in Team,
      join: m in assoc(t, :members),
      where: t.manager_id == ^manager_id,
      select: m.id,
      distinct: true
    )
    |> Repo.all()
  end

  defp member_query(team_id) do
    from(u in User,
      join: tu in "team_users",
      on: tu.user_id == u.id,
      where: tu.team_id == ^team_id,
      order_by: u.id
    )
  end

  defp preload_team(team) do
    members = member_query(team.id) |> limit(^(@max_members + 1)) |> Repo.all()
    team = Repo.preload(team, manager: :role)

    %{
      team
      | members: members |> Enum.take(@max_members) |> Repo.preload(:role),
        members_has_more: length(members) > @max_members
    }
  end

  defp preload({:ok, team}), do: {:ok, preload_team(team)}
  defp preload(error), do: error
end
