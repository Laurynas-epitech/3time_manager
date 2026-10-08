defmodule TimeManagerWeb.AuthControllerTest do
  use TimeManagerWeb.ConnCase

  import TimeManager.AccountsFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "register creates an employee, even if a role is sent", %{conn: conn} do
    conn =
      post(conn, ~p"/api/auth/register",
        user: %{username: "new", email: unique_email(), password: "secret123", role: "admin"}
      )

    assert %{"data" => %{"role" => "employee"}, "csrf_token" => csrf} = json_response(conn, 201)
    assert is_binary(csrf)
    assert conn.resp_cookies["tm_jwt"].http_only
  end

  test "login sets an http-only JWT cookie and returns the csrf token", %{conn: conn} do
    user = user_fixture()

    resp = post(conn, ~p"/api/auth/login", email: user.email, password: valid_password())
    assert %{"csrf_token" => csrf, "data" => %{"id" => id}} = json_response(resp, 200)
    assert id == user.id

    cookie = resp.resp_cookies["tm_jwt"]
    assert cookie.http_only

    me =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> put_req_cookie("tm_jwt", cookie.value)
      |> put_req_header("x-csrf-token", csrf)
      |> get(~p"/api/auth/me")

    assert %{"id" => ^id} = json_response(me, 200)["data"]
  end

  test "login with a wrong password is rejected", %{conn: conn} do
    user = user_fixture()
    conn = post(conn, ~p"/api/auth/login", email: user.email, password: "nope-nope")
    assert json_response(conn, 401)
  end

  test "requests without cookie, or with a wrong csrf token, get 401", %{conn: conn} do
    assert json_response(get(conn, ~p"/api/auth/me"), 401)

    user = user_fixture()
    {:ok, jwt, _csrf} = TimeManager.Auth.Token.issue(user.id, "employee")

    conn =
      conn
      |> put_req_cookie("tm_jwt", jwt)
      |> put_req_header("x-csrf-token", "forged")
      |> get(~p"/api/auth/me")

    assert json_response(conn, 401)
  end

  test "logout clears the cookie", %{conn: conn} do
    conn = conn |> log_in(user_fixture()) |> post(~p"/api/auth/logout")
    assert response(conn, 204)
    assert conn.resp_cookies["tm_jwt"].max_age == 0
  end

  test "logout without a valid session and CSRF header is rejected", %{conn: conn} do
    assert json_response(post(conn, ~p"/api/auth/logout"), 401)
  end

  test "tampered and expired JWTs are rejected", %{conn: conn} do
    user = user_fixture()
    csrf = TimeManager.Auth.Token.generate_csrf()

    {:ok, expired, _} =
      TimeManager.Auth.Token.generate_and_sign(%{
        "user_id" => user.id,
        "role" => "employee",
        "csrf" => csrf,
        "exp" => System.system_time(:second) - 3600
      })

    for token <- [expired, "invalid.jwt.value"] do
      request = conn |> put_req_cookie("tm_jwt", token) |> put_req_header("x-csrf-token", csrf)
      assert json_response(get(request, ~p"/api/auth/me"), 401)
    end
  end
end
