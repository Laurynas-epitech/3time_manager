defmodule TimeManagerWeb.AuthCookie do
  @moduledoc "Name and options of the HTTP-only cookie that carries the JWT."

  import Plug.Conn

  @name "tm_jwt"

  def name, do: @name

  def put(conn, jwt) do
    put_resp_cookie(conn, @name, jwt,
      http_only: true,
      same_site: "Lax",
      secure: secure?(),
      max_age: TimeManager.Auth.Token.ttl()
    )
  end

  def delete(conn) do
    delete_resp_cookie(conn, @name, http_only: true, same_site: "Lax", secure: secure?())
  end

  # Only send the cookie over HTTPS when the app is served over HTTPS.
  defp secure?, do: Application.get_env(:time_manager, :secure_cookies, false)
end
