defmodule TimeManagerWeb.Plugs.Authenticate do
  @moduledoc """
  1. Reads the JWT from the HTTP-only cookie and verifies it.
  2. Compares the `x-csrf-token` header with the `csrf` claim.
  3. Loads the user (with role) into `conn.assigns.current_user`.

  Any failure -> 401.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias TimeManager.Accounts
  alias TimeManager.Auth.Token
  alias TimeManagerWeb.AuthCookie

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_cookies(conn)

    with jwt when is_binary(jwt) <- conn.req_cookies[AuthCookie.name()],
         {:ok, claims} <- Token.verify_and_validate(jwt),
         [header_csrf] <- get_req_header(conn, "x-csrf-token"),
         true <- Plug.Crypto.secure_compare(header_csrf, claims["csrf"] || ""),
         %{} = user <- Accounts.get_user(claims["user_id"]) do
      conn
      |> assign(:current_user, user)
      |> assign(:jwt_claims, claims)
    else
      _ -> unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: %{detail: "Unauthorized"}})
    |> halt()
  end
end
