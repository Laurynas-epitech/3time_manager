defmodule TimeManagerWeb.SecurityTest do
  # Not async: the rate limit test changes application config.
  use TimeManagerWeb.ConnCase, async: false

  import TimeManager.AccountsFixtures

  alias TimeManager.{Accounts, RateLimiter, Teams}

  describe "rate limiting" do
    test "the limiter blocks a key after `limit` hits in one window" do
      key = {:test, System.unique_integer()}

      assert :ok = RateLimiter.hit(key, 2, 60_000)
      assert :ok = RateLimiter.hit(key, 2, 60_000)
      assert {:error, retry_after} = RateLimiter.hit(key, 2, 60_000)
      assert retry_after in 1..60
    end

    test "login answers 429 with Retry-After once the limit is reached", %{conn: conn} do
      previous = Application.fetch_env!(:time_manager, :rate_limits)
      Application.put_env(:time_manager, :rate_limits, auth: [limit: 2, window_ms: 60_000])
      on_exit(fn -> Application.put_env(:time_manager, :rate_limits, previous) end)

      # A unique client address so other tests do not share the counter.
      ip = {203, 0, 113, rem(System.unique_integer([:positive]), 250)}
      user = user_fixture()

      attempt = fn ->
        %{conn | remote_ip: ip}
        |> put_req_header("accept", "application/json")
        |> post(~p"/api/auth/login", email: user.email, password: "wrong-password")
      end

      assert json_response(attempt.(), 401)
      assert json_response(attempt.(), 401)

      blocked = attempt.()
      assert json_response(blocked, 429)
      assert [_seconds] = get_resp_header(blocked, "retry-after")
    end
  end

  test "rotating X-Real-IP cannot bypass an untrusted peer's limit", %{conn: conn} do
    previous = Application.fetch_env!(:time_manager, :rate_limits)
    proxies = Application.get_env(:time_manager, :trusted_proxy_ips, [])

    Application.put_env(
      :time_manager,
      :rate_limits,
      Keyword.put(previous, :auth, limit: 1, window_ms: 60_000)
    )

    Application.put_env(:time_manager, :trusted_proxy_ips, [])

    on_exit(fn ->
      Application.put_env(:time_manager, :rate_limits, previous)
      Application.put_env(:time_manager, :trusted_proxy_ips, proxies)
    end)

    peer = {198, 51, 100, rem(System.unique_integer([:positive]), 250)}

    request = fn header ->
      %{conn | remote_ip: peer}
      |> put_req_header("x-real-ip", header)
      |> TimeManagerWeb.Plugs.RateLimit.call(:auth)
    end

    refute request.("192.0.2.1").halted
    assert request.("192.0.2.2").status == 429
  end

  test "only a trusted proxy may supply a valid client IP", %{conn: conn} do
    previous = Application.fetch_env!(:time_manager, :rate_limits)
    proxies = Application.get_env(:time_manager, :trusted_proxy_ips, [])
    peer = {198, 51, 100, rem(System.unique_integer([:positive]), 250)}

    Application.put_env(
      :time_manager,
      :rate_limits,
      Keyword.put(previous, :auth, limit: 1, window_ms: 60_000)
    )

    Application.put_env(:time_manager, :trusted_proxy_ips, [peer])

    on_exit(fn ->
      Application.put_env(:time_manager, :rate_limits, previous)
      Application.put_env(:time_manager, :trusted_proxy_ips, proxies)
    end)

    request = fn header ->
      %{conn | remote_ip: peer}
      |> put_req_header("x-real-ip", header)
      |> TimeManagerWeb.Plugs.RateLimit.call(:auth)
    end

    token = rem(System.unique_integer([:positive]), 65_535)
    first = "2001:db8::#{Integer.to_string(token, 16)}"
    second = "2001:db8:1::#{Integer.to_string(token, 16)}"
    refute request.(first).halted
    refute request.(second).halted
    assert request.(first).status == 429
    refute request.("malformed-1").halted
    assert request.("malformed-2").status == 429
  end

  test "authenticated writes are limited by account while reads remain available", %{conn: conn} do
    previous = Application.fetch_env!(:time_manager, :rate_limits)

    Application.put_env(
      :time_manager,
      :rate_limits,
      Keyword.put(previous, :writes, limit: 1, window_ms: 60_000)
    )

    on_exit(fn -> Application.put_env(:time_manager, :rate_limits, previous) end)
    user = user_fixture()
    write = %{conn | method: "POST"} |> assign(:current_user, user)
    refute TimeManagerWeb.Plugs.RateLimit.call(write, :writes).halted
    assert TimeManagerWeb.Plugs.RateLimit.call(write, :writes).status == 429
    refute TimeManagerWeb.Plugs.RateLimit.call(%{write | method: "GET"}, :writes).halted

    refute TimeManagerWeb.Plugs.RateLimit.call(
             %{write | request_path: "/api/auth/logout"},
             :writes
           ).halted
  end

  test "non-admin teams and nested members are bounded with authorized member pages", %{
    conn: conn
  } do
    employee = user_fixture()
    outsider = user_fixture()
    {:ok, team} = Teams.create_team(%{"name" => "Large team"})
    {:ok, _} = Teams.add_member(team, employee)
    for _ <- 1..100, do: Teams.add_member(team, user_fixture())

    [result] = Teams.list_teams_for_user(employee.id, %{"limit" => "1"})
    assert length(result.members) == 100
    assert result.members_has_more
    assert length(Teams.list_members(team.id, %{"limit" => "5000"})) == 100
    assert length(Teams.list_members(team.id, %{"offset" => "100"})) == 1

    assert conn
           |> log_in(employee)
           |> get(~p"/api/teams/#{team.id}/members?offset=100")
           |> json_response(200)

    assert conn
           |> log_in(outsider)
           |> get(~p"/api/teams/#{team.id}/members")
           |> json_response(403)
  end

  describe "input limits" do
    test "multibyte passwords cannot exceed bcrypt's 72-byte input limit" do
      assert {:error, changeset} =
               Accounts.create_user(%{
                 "username" => "Unicode password",
                 "email" => unique_email(),
                 "password" => String.duplicate("é", 40)
               })

      assert %{password: [_]} = TimeManager.DataCase.errors_on(changeset)
    end

    test "invalid registration shapes return 400 instead of crashing", %{conn: conn} do
      for user <- ["unexpected string", ["unexpected list"], nil] do
        assert conn |> post(~p"/api/auth/register", %{user: user}) |> json_response(400)
      end
    end

    test "oversized and malformed JSON errors retain security headers" do
      for {body, status} <- [{String.duplicate(" ", 1_000_001), 413}, {"{invalid", 400}] do
        response =
          build_conn(:post, "/api/auth/login", body)
          |> put_req_header("content-type", "application/json")
          |> TimeManagerWeb.Endpoint.call(TimeManagerWeb.Endpoint.init([]))

        assert json_response(response, status)
        assert get_resp_header(response, "x-content-type-options") == ["nosniff"]
      end
    end

    test "username, team name and password lengths are validated" do
      long_name = String.duplicate("a", 51)

      assert {:error, changeset} =
               Accounts.create_user(%{
                 "username" => long_name,
                 "email" => unique_email(),
                 "password" => valid_password()
               })

      assert %{username: [_]} = TimeManager.DataCase.errors_on(changeset)

      assert {:error, changeset} =
               Accounts.create_user(%{
                 "username" => "short pw",
                 "email" => unique_email(),
                 "password" => "1234567"
               })

      assert %{password: ["should be at least 8 character(s)"]} =
               TimeManager.DataCase.errors_on(changeset)

      assert {:error, changeset} = Teams.create_team(%{"name" => String.duplicate("t", 101)})
      assert %{name: [_]} = TimeManager.DataCase.errors_on(changeset)
    end
  end

  describe "list limits" do
    test "users can be paged with limit/offset", %{conn: conn} do
      admin = user_fixture(%{}, "admin")
      for _ <- 1..3, do: user_fixture()

      page = fn query ->
        conn
        |> log_in(admin)
        |> get("/api/users?" <> query)
        |> json_response(200)
        |> Map.fetch!("data")
      end

      assert length(page.("")) == 4
      assert [first, second] = page.("limit=2")
      assert [third, fourth] = page.("limit=2&offset=2")
      assert Enum.uniq([first, second, third, fourth]) |> length() == 4
      # Nonsense values fall back to the defaults instead of crashing.
      assert length(page.("limit=abc&offset=-5")) == 4
    end

    test "clock lists keep the newest clocks and stay oldest first", %{conn: conn} do
      user = user_fixture()
      base = ~U[2026-01-01 08:00:00Z]

      for {status, minutes} <- [{true, 0}, {false, 60}, {true, 120}] do
        {:ok, _} =
          TimeManager.TimeTracking.record_clock(user.id, %{
            "status" => status,
            "time" => DateTime.add(base, minutes * 60)
          })
      end

      times =
        conn
        |> log_in(user)
        |> get(~p"/api/clocks/#{user.id}?limit=2")
        |> json_response(200)
        |> Map.fetch!("data")
        |> Enum.map(& &1["time"])

      assert times == ["2026-01-01T09:00:00Z", "2026-01-01T10:00:00Z"]
    end
  end

  test "API responses carry browser security headers", %{conn: conn} do
    conn = conn |> log_in(user_fixture()) |> get(~p"/api/auth/me")

    assert get_resp_header(conn, "x-content-type-options") == ["nosniff"]
    # Phoenix 1.8 blocks framing with CSP frame-ancestors instead of X-Frame-Options.
    assert [csp] = get_resp_header(conn, "content-security-policy")
    assert csp =~ "frame-ancestors"
  end
end
