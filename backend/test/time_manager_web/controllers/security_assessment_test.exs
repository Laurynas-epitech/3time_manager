defmodule TimeManagerWeb.SecurityAssessmentTest do
  use TimeManagerWeb.ConnCase, async: false

  import TimeManager.AccountsFixtures
  import TimeManager.TimeTrackingFixtures

  alias TimeManager.{Accounts, Repo, Teams}

  setup do
    admin = user_fixture(%{}, "admin")
    manager = user_fixture(%{}, "manager")
    employee = user_fixture()
    outsider = user_fixture()
    {:ok, team} = Teams.create_team(%{"name" => "Assessment", "manager_id" => manager.id})
    {:ok, _} = Teams.add_member(team, employee)
    %{admin: admin, manager: manager, employee: employee, outsider: outsider, team: team}
  end

  test "public registration cannot assign privileged fields", %{conn: conn} do
    response =
      post(conn, "/api/auth/register", %{
        user: %{
          username: "Assessment",
          email: unique_email(),
          password: valid_password(),
          role: "admin",
          role_id: 1,
          id: 999_999
        }
      })

    user = json_response(response, 201)["data"]
    assert user["role"] == "employee"
    refute user["id"] == 999_999
    refute Map.has_key?(user, "password_hash")
  end

  test "invalid nested mutation shapes return 400 without a crash", ctx do
    for shape <- [nil, "text", ["list"], 123] do
      for {path, field} <- [
            {"/api/users", :user},
            {"/api/teams", :team},
            {"/api/workingtime/#{ctx.employee.id}", :working_time},
            {"/api/clock/#{ctx.admin.id}", :clock}
          ] do
        response = build_conn() |> log_in(ctx.admin) |> post(path, %{field => shape})
        assert json_response(response, 400)
      end

      assert build_conn()
             |> log_in(ctx.admin)
             |> put("/api/users/#{ctx.employee.id}", %{user: shape})
             |> json_response(400)

      assert build_conn()
             |> log_in(ctx.admin)
             |> put("/api/teams/#{ctx.team.id}", %{team: shape})
             |> json_response(400)
    end
  end

  test "SQL-style parameters cannot broaden scoped lists", ctx do
    for payload <- [
          "' OR 1=1 --",
          "'; DROP TABLE users;--",
          "1 UNION SELECT 1",
          "' AND pg_sleep(1)--"
        ] do
      for actor <- [ctx.admin, ctx.manager, ctx.employee] do
        for field <- ["email", "username"] do
          response = build_conn() |> log_in(actor) |> get("/api/users", %{field => payload})
          assert json_response(response, 200)["data"] == []
        end
      end
    end

    assert Repo.aggregate(TimeManager.Accounts.User, :count) == 4
  end

  test "hostile integer offsets cannot overflow database parameters", ctx do
    response =
      build_conn()
      |> log_in(ctx.admin)
      |> get("/api/users", %{offset: String.duplicate("9", 100), limit: "5000"})

    assert json_response(response, 200)["data"] == []
  end

  test "SQL-style credentials and unusual password bytes do not authenticate or crash", ctx do
    for email <- ["' OR 1=1 --", "x' UNION SELECT 1--", ctx.employee.email] do
      for password <- ["' OR 1=1 --", String.duplicate("x", 1000), "invalid\0password"] do
        response = post(build_conn(), "/api/auth/login", %{email: email, password: password})
        assert json_response(response, 401)
      end
    end
  end

  test "invalid or incomplete time filters are rejected rather than returning all rows", ctx do
    working_time_fixture(%{user_id: ctx.employee.id})

    for params <- [
          %{"start" => "invalid", "end" => "invalid"},
          %{"start" => [], "end" => "2026-10-01T00:00:00"},
          %{"start" => "2026-10-01T00:00:00"},
          %{"start" => "2026-10-02T00:00:00", "end" => "2026-10-01T00:00:00"}
        ] do
      assert build_conn()
             |> log_in(ctx.employee)
             |> get("/api/workingtime/#{ctx.employee.id}", params)
             |> json_response(400)
    end
  end

  test "working-time route aliases cannot bypass object ownership", ctx do
    record = working_time_fixture(%{user_id: ctx.outsider.id})

    for path <- [
          "/api/workingtime/#{record.id}",
          "/api/workingTime/#{ctx.employee.id}/#{record.id}"
        ] do
      assert build_conn()
             |> log_in(ctx.manager)
             |> put(path, %{working_time: %{user_id: ctx.employee.id}})
             |> json_response(403)

      assert build_conn() |> log_in(ctx.employee) |> delete(path) |> json_response(403)
    end
  end

  test "unauthenticated protected endpoints and missing CSRF fail", ctx do
    for path <- [
          "/api/users",
          "/api/users/#{ctx.employee.id}",
          "/api/roles",
          "/api/teams",
          "/api/teams/#{ctx.team.id}/members",
          "/api/clock/#{ctx.employee.id}",
          "/api/workingtime/#{ctx.employee.id}",
          "/api/chartManager/#{ctx.employee.id}"
        ] do
      assert get(build_conn(), path) |> json_response(401)

      assert build_conn()
             |> log_in(ctx.employee)
             |> delete_req_header("x-csrf-token")
             |> get(path)
             |> json_response(401)
    end
  end

  test "role and owner changes in profile bodies are ignored", ctx do
    response =
      build_conn()
      |> log_in(ctx.employee)
      |> put("/api/users/#{ctx.employee.id}", %{
        user: %{
          username: "Changed",
          role: "admin",
          role_id: ctx.admin.role_id,
          id: ctx.outsider.id
        }
      })

    data = json_response(response, 200)["data"]
    assert data["id"] == ctx.employee.id
    assert data["role"] == "employee"
    assert Accounts.get_user!(ctx.outsider.id).username == ctx.outsider.username
  end

  test "diagnostic, credential and source paths are not served" do
    for path <- [
          "/.env",
          "/.env.local",
          "/.git/config",
          "/.secrets/jwt_secret",
          "/config/runtime.exs",
          "/mix.lock",
          "/dev/dashboard",
          "/dev/mailbox",
          "/backend/config/dev.exs",
          "/time"
        ] do
      status =
        try do
          get(build_conn(), path).status
        rescue
          error in Phoenix.Router.NoRouteError -> Plug.Exception.status(error)
        end

      assert status == 404
    end
  end
end
