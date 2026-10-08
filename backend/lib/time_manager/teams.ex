defmodule TimeManager.Teams do
  @moduledoc """
  The Teams context. A team has one manager and many members;
  an employee can belong to several teams.
  """

  import Ecto.Query, warn: false
  alias TimeManager.Repo

  alias TimeManager.Accounts.User
  alias TimeManager.Teams.Team

  @preloads [manager: :role, members: :role]

  def list_teams do
    Team |> order_by(:id) |> Repo.all() |> Repo.preload(@preloads)
  end

  @doc "Teams a user manages or belongs to."
  def list_teams_for_user(user_id) do
    from(t in Team,
      left_join: m in assoc(t, :members),
      where: t.manager_id == ^user_id or m.id == ^user_id,
      distinct: true,
      order_by: t.id
    )
    |> Repo.all()
    |> Repo.preload(@preloads)
  end

  def get_team!(id), do: Team |> Repo.get!(id) |> Repo.preload(@preloads)

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

  defp preload({:ok, team}), do: {:ok, Repo.preload(team, @preloads, force: true)}
  defp preload(error), do: error
end
