defmodule TimeManagerWeb.Plugs.RateLimit do
  @moduledoc """
  Limits how often one client can call the routes of a pipeline:

      plug TimeManagerWeb.Plugs.RateLimit, :auth

  Limits are read from `config :time_manager, :rate_limits` (so tests can
  relax them). Over the limit -> 429 with a `Retry-After` header.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias TimeManager.RateLimiter

  def init(name) when is_atom(name), do: name

  def call(conn, name) do
    if name == :writes and
         (conn.method in ["GET", "HEAD", "OPTIONS"] or conn.request_path == "/api/auth/logout") do
      conn
    else
      limit(conn, name)
    end
  end

  defp limit(conn, name) do
    config = Application.fetch_env!(:time_manager, :rate_limits) |> Keyword.fetch!(name)

    key =
      if name == :writes,
        do: {name, conn.assigns.current_user.id},
        else: {name, client_ip(conn)}

    case RateLimiter.hit(key, config[:limit], config[:window_ms]) do
      :ok ->
        conn

      {:error, retry_after} ->
        conn
        |> put_resp_header("retry-after", Integer.to_string(retry_after))
        |> put_status(:too_many_requests)
        |> json(%{errors: %{detail: "Too many requests, try again later"}})
        |> halt()
    end
  end

  # The trusted proxy must overwrite X-Real-IP. Untrusted peers cannot choose keys.
  defp client_ip(conn) do
    if conn.remote_ip in Application.get_env(:time_manager, :trusted_proxy_ips, []) do
      case get_req_header(conn, "x-real-ip") do
        [ip] ->
          case :inet.parse_address(String.to_charlist(ip)) do
            {:ok, address} -> address
            _ -> conn.remote_ip
          end

        _ ->
          conn.remote_ip
      end
    else
      conn.remote_ip
    end
  end
end
