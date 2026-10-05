defmodule TimeManagerWeb.TeamJSON do
  alias TimeManager.Teams.Team
  alias TimeManagerWeb.UserJSON

  def index(%{teams: teams}), do: %{data: for(team <- teams, do: data(team))}

  def show(%{team: team}), do: %{data: data(team)}

  defp data(%Team{} = team) do
    %{
      id: team.id,
      name: team.name,
      manager: user(team.manager),
      members: Enum.map(team.members, &UserJSON.data/1)
    }
  end

  defp user(nil), do: nil
  defp user(%Ecto.Association.NotLoaded{}), do: nil
  defp user(user), do: UserJSON.data(user)
end
