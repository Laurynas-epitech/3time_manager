defmodule TimeManagerWeb.AuthController do
  @moduledoc """
  POST /api/auth/register  -> creates an employee and logs them in
  POST /api/auth/login     -> sets the JWT cookie (HTTP only), returns the csrf token
  POST /api/auth/logout    -> clears the cookie
  GET  /api/auth/me        -> current user (needs cookie + x-csrf-token)
  """
  use TimeManagerWeb, :controller

  alias TimeManager.Accounts
  alias TimeManager.Auth.Token
  alias TimeManagerWeb.{AuthCookie, UserJSON}

  action_fallback TimeManagerWeb.FallbackController

  def register(conn, %{"user" => user_params}) do
    # Public registration always creates an employee, whatever the body says.
    params = Map.take(user_params, ["username", "email", "password"])

    with {:ok, user} <- Accounts.create_user(params) do
      conn
      |> put_status(:created)
      |> sign_in(user)
    end
  end

  def register(_conn, _params), do: {:error, :bad_request}

  def login(conn, %{"email" => email, "password" => password}) do
    with {:ok, user} <- Accounts.authenticate(email, password) do
      sign_in(conn, user)
    end
  end

  def login(_conn, _params), do: {:error, :bad_request}

  def logout(conn, _params) do
    conn
    |> AuthCookie.delete()
    |> send_resp(:no_content, "")
  end

  def me(conn, _params) do
    json(conn, %{data: UserJSON.data(conn.assigns.current_user)})
  end

  defp sign_in(conn, user) do
    with {:ok, jwt, csrf} <- Token.issue(user.id, Accounts.role_name(user)) do
      conn
      |> AuthCookie.put(jwt)
      |> json(%{data: UserJSON.data(user), csrf_token: csrf})
    end
  end
end
