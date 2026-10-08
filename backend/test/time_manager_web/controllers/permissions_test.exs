defmodule TimeManagerWeb.PermissionsTest do
  use TimeManagerWeb.ConnCase

  import TimeManager.AccountsFixtures
  import TimeManager.TimeTrackingFixtures

  alias TimeManager.Teams

  setup do
    admin = user_fixture(%{username: "admin"}, "admin")
    manager = user_fixture(%{username: "manager"}, "manager")
    employee = user_fixture(%{username: "employee"})
    outsider = user_fixture(%{username: "outsider"})

    {:ok, team} = Teams.create_team(%{"name" => "Team A", "manager_id" => manager.id})
    {:ok, team} = Teams.add_member(team, employee)

    %{admin: admin, manager: manager, employee: employee, outsider: outsider, team: team}
  end

  describe "users" do
    test "each role sees a different list", ctx do
      ids = fn user ->
        build_conn()
        |> log_in(user)
        |> get(~p"/api/users")
        |> json_response(200)
        |> Map.fetch!("data")
        |> Enum.map(& &1["id"])
        |> Enum.sort()
      end

      assert length(ids.(ctx.admin)) == 4
      assert ids.(ctx.manager) == Enum.sort([ctx.manager.id, ctx.employee.id])
      assert ids.(ctx.employee) == [ctx.employee.id]

      directory = fn user ->
        build_conn()
        |> log_in(user)
        |> get(~p"/api/users?scope=all")
        |> json_response(200)
        |> Map.fetch!("data")
        |> length()
      end

      assert directory.(ctx.manager) == 4
      assert directory.(ctx.employee) == 1
    end

    test "only admins create users and change roles", ctx do
      params = %{
        user: %{username: "x", email: unique_email(), password: "secret123", role: "manager"}
      }

      assert build_conn()
             |> log_in(ctx.employee)
             |> post(~p"/api/users", params)
             |> json_response(403)

      conn = build_conn() |> log_in(ctx.admin) |> post(~p"/api/users", params)
      assert %{"role" => "manager"} = json_response(conn, 201)["data"]

      assert build_conn()
             |> log_in(ctx.manager)
             |> put(~p"/api/users/#{ctx.employee.id}/role", role: "admin")
             |> json_response(403)

      conn =
        build_conn()
        |> log_in(ctx.admin)
        |> put(~p"/api/users/#{ctx.employee.id}/role", role: "manager")

      assert %{"role" => "manager"} = json_response(conn, 200)["data"]
    end

    test "employees can only edit themselves", ctx do
      conn = build_conn() |> log_in(ctx.employee)

      assert conn
             |> put(~p"/api/users/#{ctx.employee.id}", user: %{username: "me"})
             |> json_response(200)

      assert conn
             |> put(~p"/api/users/#{ctx.outsider.id}", user: %{username: "hack"})
             |> json_response(403)

      assert conn |> get(~p"/api/users/#{ctx.outsider.id}") |> json_response(403)
    end
  end

  describe "working times and clocks" do
    test "manager reads and manages team members, not outsiders", ctx do
      wt = working_time_fixture(%{user_id: ctx.employee.id})
      conn = build_conn() |> log_in(ctx.manager)

      assert [%{"id" => id}] =
               conn
               |> get(~p"/api/workingtime/#{ctx.employee.id}")
               |> json_response(200)
               |> Map.fetch!("data")

      assert id == wt.id
      assert conn |> get(~p"/api/workingtime/#{ctx.outsider.id}") |> json_response(403)

      body = %{working_time: %{start: "2026-10-01T08:00:00Z", end: "2026-10-01T12:00:00Z"}}
      assert conn |> post(~p"/api/workingTime/#{ctx.employee.id}", body) |> json_response(201)
      assert conn |> post(~p"/api/workingTime/#{ctx.outsider.id}", body) |> json_response(403)
    end

    test "employee reads own working times but cannot edit them", ctx do
      wt = working_time_fixture(%{user_id: ctx.employee.id})
      conn = build_conn() |> log_in(ctx.employee)

      assert conn |> get(~p"/api/workingtime/#{ctx.employee.id}") |> json_response(200)
      assert conn |> delete(~p"/api/workingtime/#{wt.id}") |> json_response(403)
    end

    test "users clock only for themselves", ctx do
      body = %{clock: %{time: "2026-10-05T08:00:00Z", status: true}}
      conn = build_conn() |> log_in(ctx.employee)

      assert conn |> post(~p"/api/clock/#{ctx.employee.id}", body) |> json_response(201)
      assert conn |> post(~p"/api/clock/#{ctx.outsider.id}", body) |> json_response(403)

      assert [_] =
               conn
               |> get(~p"/api/clock/#{ctx.employee.id}")
               |> json_response(200)
               |> Map.fetch!("data")
    end
  end

  describe "teams" do
    test "admin creates teams, manager manages members of own team", ctx do
      assert build_conn()
             |> log_in(ctx.manager)
             |> post(~p"/api/teams", team: %{name: "B"})
             |> json_response(403)

      conn = build_conn() |> log_in(ctx.admin) |> post(~p"/api/teams", team: %{name: "B"})
      assert %{"id" => other_team_id} = json_response(conn, 201)["data"]

      manager = build_conn() |> log_in(ctx.manager)

      assert %{"members" => members} =
               manager
               |> post(~p"/api/teams/#{ctx.team.id}/members/#{ctx.outsider.id}")
               |> json_response(200)
               |> Map.fetch!("data")

      assert length(members) == 2

      assert manager
             |> post(~p"/api/teams/#{other_team_id}/members/#{ctx.outsider.id}")
             |> json_response(403)
    end

    test "a team manager must have the manager or admin role", ctx do
      conn =
        build_conn()
        |> log_in(ctx.admin)
        |> post(~p"/api/teams", team: %{name: "C", manager_id: ctx.employee.id})

      assert json_response(conn, 422)
    end
  end

  test "a demoted manager loses membership management even with an existing JWT", ctx do
    conn = build_conn() |> log_in(ctx.manager)
    {:ok, _} = TimeManager.Accounts.update_user_role(ctx.manager, "employee")

    assert conn
           |> post(~p"/api/teams/#{ctx.team.id}/members/#{ctx.outsider.id}")
           |> json_response(403)
  end
end
