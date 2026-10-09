defmodule TimeManagerWeb.ClockControllerTest do
  use TimeManagerWeb.ConnCase

  import TimeManager.AccountsFixtures

  setup do
    user = user_fixture()
    %{user: user, conn: build_conn() |> log_in(user)}
  end

  test "clock out records exactly one completed session in employee history", %{
    conn: conn,
    user: user
  } do
    path = ~p"/api/clock/#{user.id}"
    start = "2026-10-08T08:00:00Z"
    finish = "2026-10-08T09:30:00Z"

    assert conn |> post(path, clock: %{time: start, status: true}) |> json_response(201)

    assert conn
           |> get(~p"/api/workingtime/#{user.id}")
           |> json_response(200)
           |> Map.fetch!("data") == []

    assert conn |> post(path, clock: %{time: finish, status: false}) |> json_response(201)

    assert [%{"start" => ^start, "end" => ^finish}] =
             conn
             |> get(~p"/api/workingtime/#{user.id}")
             |> json_response(200)
             |> Map.fetch!("data")

    assert conn |> post(path, clock: %{time: finish, status: false}) |> json_response(422)
    assert length(TimeManager.TimeTracking.list_workingtime()) == 1
    assert length(TimeManager.TimeTracking.list_clocks()) == 2
  end

  test "invalid transitions leave clocks and history unchanged", %{conn: conn, user: user} do
    path = ~p"/api/clock/#{user.id}"

    assert conn
           |> post(path, clock: %{time: "2026-10-08T08:00:00Z", status: false})
           |> json_response(422)

    assert conn
           |> post(path, clock: %{time: "2026-10-08T08:00:00Z", status: true})
           |> json_response(201)

    assert conn
           |> post(path, clock: %{time: "2026-10-08T09:00:00Z", status: true})
           |> json_response(422)

    assert conn
           |> post(path, clock: %{time: "2026-10-08T07:00:00Z", status: false})
           |> json_response(422)

    assert conn |> post(path, clock: %{time: "invalid", status: false}) |> json_response(422)
    assert length(TimeManager.TimeTracking.list_clocks()) == 1
    assert TimeManager.TimeTracking.list_workingtime() == []
  end

  test "queued retries remain idempotent after later transitions", %{conn: conn, user: user} do
    path = ~p"/api/clock/#{user.id}"
    start = %{time: "2026-10-09T08:00:00Z", status: true, client_action_id: Ecto.UUID.generate()}

    finish = %{
      time: "2026-10-09T09:00:00Z",
      status: false,
      client_action_id: Ecto.UUID.generate()
    }

    first = conn |> post(path, clock: start) |> json_response(201)
    last = conn |> post(path, clock: finish) |> json_response(201)
    assert conn |> post(path, clock: start) |> json_response(201) == first
    assert conn |> post(path, clock: finish) |> json_response(201) == last
    assert length(TimeManager.TimeTracking.list_clocks()) == 2
    assert length(TimeManager.TimeTracking.list_workingtime()) == 1
  end

  test "action IDs cannot change payloads or bypass another user's permissions", %{
    conn: conn,
    user: user
  } do
    path = ~p"/api/clock/#{user.id}"
    attrs = %{time: "2026-10-09T08:00:00Z", status: true, client_action_id: Ecto.UUID.generate()}
    assert conn |> post(path, clock: attrs) |> json_response(201)

    assert conn
           |> post(path, clock: %{attrs | time: "2026-10-09T09:00:00Z", status: false})
           |> json_response(422)

    other = user_fixture()

    assert conn
           |> post(path, clock: Map.put(attrs, :client_owner_id, other.id))
           |> json_response(403)

    assert build_conn() |> log_in(other) |> post(path, clock: attrs) |> json_response(403)
    assert conn |> post(path, clock: %{attrs | client_action_id: "invalid"}) |> json_response(422)
    assert length(TimeManager.TimeTracking.list_clocks()) == 1
    assert TimeManager.TimeTracking.list_workingtime() == []
  end

  test "same-second transitions retain the latest status and subsequent sessions", %{
    conn: conn,
    user: user
  } do
    path = ~p"/api/clock/#{user.id}"
    time = "2026-10-08T08:00:00Z"

    for status <- [true, false, true, false] do
      assert conn |> post(path, clock: %{time: time, status: status}) |> json_response(201)
    end

    clocks = conn |> get(path) |> json_response(200) |> Map.fetch!("data")
    assert List.last(clocks)["status"] == false
    assert length(TimeManager.TimeTracking.list_workingtime()) == 2
  end
end
