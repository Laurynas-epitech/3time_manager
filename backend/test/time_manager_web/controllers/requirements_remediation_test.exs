defmodule TimeManagerWeb.RequirementsRemediationTest do
  use TimeManagerWeb.ConnCase
  import TimeManager.AccountsFixtures
  import TimeManager.TimeTrackingFixtures
  alias TimeManager.{Repo, Teams, TimeTracking}

  setup do
    manager = user_fixture(%{}, "manager")
    admin = user_fixture(%{}, "admin")
    members = Enum.map(1..3, fn _ -> user_fixture() end)
    {:ok, team} = Teams.create_team(%{name: "Report fixtures", manager_id: manager.id})
    Enum.each(members, &Teams.add_member(team, &1))
    %{manager: manager, admin: admin, members: members, team: team}
  end

  defp report(user, team, first, last, zone \\ "UTC") do
    build_conn()
    |> log_in(user)
    |> get("/api/teams/#{team.id}/report", %{start: first, end: last, timezone: zone})
  end

  test "daily and partial-week averages include zero members and distinct membership", ctx do
    [one, two, _] = ctx.members

    working_time_fixture(%{
      user_id: one.id,
      start: ~U[2026-10-12 08:00:00Z],
      end: ~U[2026-10-12 16:00:00Z]
    })

    working_time_fixture(%{
      user_id: two.id,
      start: ~U[2026-10-12 08:00:00Z],
      end: ~U[2026-10-12 12:00:00Z]
    })

    working_time_fixture(%{
      user_id: one.id,
      start: ~U[2026-10-13 08:00:00Z],
      end: ~U[2026-10-13 14:00:00Z]
    })

    Teams.add_member(ctx.team, one)

    data =
      report(ctx.manager, ctx.team, "2026-10-12", "2026-10-13")
      |> json_response(200)
      |> Map.fetch!("data")

    assert data["member_count"] == 3
    assert Enum.map(data["daily"], & &1["average_hours"]) == [4.0, 2.0]
    assert [%{"average_hours" => 6.0, "total_hours" => 18.0, "partial" => true}] = data["weekly"]
    {:ok, other} = Teams.create_team(%{name: "Shared", manager_id: ctx.manager.id})
    Teams.add_member(other, one)
    shared = report(ctx.manager, other, "2026-10-12", "2026-10-13") |> json_response(200)
    assert shared["data"]["weekly"] |> hd() |> Map.fetch!("total_hours") == 14.0
  end

  test "DST elapsed time, midnight allocation and clipping", ctx do
    [one | _] = ctx.members

    for {first, last, day, hours} <- [
          {~U[2026-03-29 00:00:00Z], ~U[2026-03-29 02:00:00Z], "2026-03-29", 2.0},
          {~U[2026-10-24 23:00:00Z], ~U[2026-10-25 03:00:00Z], "2026-10-25", 4.0}
        ] do
      working_time_fixture(%{user_id: one.id, start: first, end: last})
      data = report(ctx.manager, ctx.team, day, day, "Europe/Paris") |> json_response(200)
      assert hd(data["data"]["daily"])["total_hours"] == hours
    end

    working_time_fixture(%{
      user_id: one.id,
      start: ~U[2026-10-12 23:00:00Z],
      end: ~U[2026-10-13 01:00:00Z]
    })

    data = report(ctx.manager, ctx.team, "2026-10-12", "2026-10-13") |> json_response(200)
    assert Enum.map(data["data"]["daily"], & &1["total_hours"]) == [1.0, 1.0]
    clipped = report(ctx.manager, ctx.team, "2026-10-13", "2026-10-13") |> json_response(200)
    assert hd(clipped["data"]["daily"])["total_hours"] == 1.0
  end

  test "authorization, empty teams and invalid report periods", ctx do
    employee = hd(ctx.members)
    outsider = user_fixture(%{}, "manager")
    assert report(employee, ctx.team, "2026-10-12", "2026-10-13") |> json_response(403)
    assert report(outsider, ctx.team, "2026-10-12", "2026-10-13") |> json_response(403)
    assert report(ctx.admin, ctx.team, "2026-10-12", "2026-10-13") |> json_response(200)

    for {first, last, zone} <- [
          {"2026-10-13", "2026-10-12", "UTC"},
          {"invalid", "2026-10-12", "UTC"},
          {"2024-01-01", "2026-10-12", "UTC"},
          {"2026-10-12", "2026-10-12", "unknown"}
        ] do
      assert report(ctx.manager, ctx.team, first, last, zone) |> json_response(400)
    end

    {:ok, empty} = Teams.create_team(%{name: "Empty", manager_id: ctx.manager.id})
    data = report(ctx.manager, empty, "2026-10-12", "2026-10-13") |> json_response(200)
    assert data["data"]["member_count"] == 0
    assert hd(data["data"]["daily"])["average_hours"] == nil
  end

  test "aggregation includes records beyond attendance page cap", ctx do
    one = hd(ctx.members)
    now = ~U[2026-10-12 00:00:00Z]

    rows =
      Enum.map(1..2001, fn _ ->
        %{
          user_id: one.id,
          start: now,
          end: DateTime.add(now, 3600),
          inserted_at: now,
          updated_at: now
        }
      end)

    Repo.insert_all(TimeTracking.WorkingTime, rows)
    data = report(ctx.manager, ctx.team, "2026-10-12", "2026-10-12") |> json_response(200)
    assert hd(data["data"]["daily"])["total_hours"] == 2001.0
    assert hd(data["data"]["daily"])["average_hours"] == 667.0
  end

  test "manual invalid create and partial updates leave data intact; overnight succeeds", ctx do
    one = hd(ctx.members)
    conn = build_conn() |> log_in(ctx.manager)

    for finish <- ["2026-10-12T07:00:00Z", "2026-10-12T08:00:00Z"] do
      assert conn
             |> post("/api/workingtime/#{one.id}",
               working_time: %{start: "2026-10-12T08:00:00Z", end: finish}
             )
             |> json_response(422)
    end

    assert Repo.aggregate(TimeTracking.WorkingTime, :count) == 0

    created =
      conn
      |> post("/api/workingtime/#{one.id}",
        working_time: %{start: "2026-10-12T23:00:00Z", end: "2026-10-13T01:00:00Z"}
      )
      |> json_response(201)

    id = created["data"]["id"]

    for attrs <- [%{start: "2026-10-13T02:00:00Z"}, %{end: "2026-10-12T22:00:00Z"}] do
      assert conn |> put("/api/workingtime/#{id}", working_time: attrs) |> json_response(422)
      assert Repo.get!(TimeTracking.WorkingTime, id).start == ~U[2026-10-12 23:00:00Z]
    end

    assert conn
           |> put("/api/workingtime/#{id}", working_time: %{user_id: ctx.manager.id})
           |> json_response(200)

    assert Repo.get!(TimeTracking.WorkingTime, id).user_id == one.id

    assert build_conn()
           |> log_in(hd(tl(ctx.members)))
           |> put("/api/workingtime/#{id}", working_time: %{end: "2026-10-13T02:00:00Z"})
           |> json_response(403)
  end

  test "same-second clock pair remains valid and UUID replay is idempotent", ctx do
    one = hd(ctx.members)

    attrs = %{
      "time" => "2026-10-12T08:00:00Z",
      "status" => true,
      "client_action_id" => Ecto.UUID.generate()
    }

    assert {:ok, _} = TimeTracking.record_clock(one.id, attrs)
    out = %{attrs | "status" => false, "client_action_id" => Ecto.UUID.generate()}
    assert {:ok, _} = TimeTracking.record_clock(one.id, out)
    assert {:ok, _} = TimeTracking.record_clock(one.id, out)
    assert Repo.aggregate(TimeTracking.WorkingTime, :count) == 1
  end

  test "all twelve specified API method/path combinations persist CRUD and space-formatted timestamps",
       ctx do
    conn = build_conn() |> log_in(ctx.admin)
    email = unique_email()

    created =
      conn
      |> post("/api/users",
        user: %{username: "Exact API", email: email, password: "Fixture-password-123"}
      )
      |> json_response(201)

    id = created["data"]["id"]
    assert conn |> get("/api/users/#{id}") |> json_response(200)

    found =
      conn |> get("/api/users", %{email: email, username: "Exact API"}) |> json_response(200)

    assert Enum.map(found["data"], & &1["id"]) == [id]
    assert conn |> put("/api/users/#{id}", user: %{username: "Updated API"}) |> json_response(200)

    assert conn
           |> post("/api/clocks/#{id}", clock: %{time: "2026-10-12 08:00:00", status: true})
           |> json_response(201)

    assert conn
           |> post("/api/clocks/#{id}", clock: %{time: "2026-10-12 09:00:00", status: false})
           |> json_response(201)

    assert length((conn |> get("/api/clocks/#{id}") |> json_response(200))["data"]) == 2

    wt =
      conn
      |> post("/api/workingtime/#{id}",
        working_time: %{start: "2026-10-12 10:00:00", end: "2026-10-12 11:00:00"}
      )
      |> json_response(201)

    record = wt["data"]["id"]
    assert conn |> get("/api/workingtime/#{id}/#{record}") |> json_response(200)

    assert conn
           |> put("/api/workingtime/#{record}", working_time: %{end: "2026-10-12 12:00:00"})
           |> json_response(200)

    filtered =
      conn
      |> get("/api/workingtime/#{id}", %{start: "2026-10-12 10:00:00", end: "2026-10-12 12:00:00"})
      |> json_response(200)

    assert Enum.map(filtered["data"], & &1["id"]) == [record]
    assert conn |> delete("/api/workingtime/#{record}") |> response(204)
    assert Repo.get(TimeTracking.WorkingTime, record) == nil
    assert conn |> delete("/api/users/#{id}") |> response(204)
    assert TimeManager.Accounts.get_user(id) == nil
  end

  test "email contract rejects missing/multiple at signs and whitespace without requiring a public domain" do
    for email <- [
          "missing.example",
          "a@@example.invalid",
          "a@b@example.invalid",
          "a b@example.invalid"
        ] do
      assert {:error, changeset} =
               TimeManager.Accounts.create_user(%{
                 username: "Email fixture",
                 email: email,
                 password: "Fixture-password-123"
               })

      assert Keyword.has_key?(changeset.errors, :email)
    end

    assert {:ok, _} =
             TimeManager.Accounts.create_user(%{
               username: "Internal domain",
               email: "fixture@localhost",
               password: "Fixture-password-123"
             })
  end

  test "every role edits/deletes own account and admin deletes every target role", ctx do
    for role <- ["employee", "manager", "admin"] do
      user = user_fixture(%{}, role)
      clock_fixture(%{user_id: user.id})
      working_time_fixture(%{user_id: user.id})
      conn = build_conn() |> log_in(user)

      assert conn
             |> put("/api/users/#{user.id}", user: %{username: "Self #{role}"})
             |> json_response(200)

      assert conn |> delete("/api/users/#{user.id}") |> response(204)
      assert TimeManager.Accounts.get_user(user.id) == nil
      target = user_fixture(%{}, role)

      assert build_conn()
             |> log_in(ctx.admin)
             |> delete("/api/users/#{target.id}")
             |> response(204)

      assert TimeManager.Accounts.get_user(target.id) == nil
    end
  end
end
