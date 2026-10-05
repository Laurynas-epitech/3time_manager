defmodule TimeManager.TeamsTest do
  use TimeManager.DataCase

  alias TimeManager.Teams

  import TimeManager.AccountsFixtures

  test "an employee can be in several teams" do
    manager = user_fixture(%{}, "manager")
    employee = user_fixture()

    {:ok, t1} = Teams.create_team(%{"name" => "Day", "manager_id" => manager.id})
    {:ok, t2} = Teams.create_team(%{"name" => "Night"})

    {:ok, _} = Teams.add_member(t1, employee)
    {:ok, _} = Teams.add_member(t2, employee)
    # adding twice is a no-op
    {:ok, t1} = Teams.add_member(t1, employee)

    assert length(t1.members) == 1
    assert length(Teams.list_teams_for_user(employee.id)) == 2
    assert Teams.manages_user?(manager.id, employee.id)
    assert Teams.managed_user_ids(manager.id) == [employee.id]

    {:ok, t1} = Teams.remove_member(t1, employee.id)
    assert t1.members == []
    refute Teams.manages_user?(manager.id, employee.id)
  end
end
