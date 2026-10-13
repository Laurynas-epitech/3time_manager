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
    config = Application.fetch_env!(:time_manager, :rate_limits) |> Keyword.fetch!(name)

    case RateLimiter.hit({name, client_ip(conn)}, config[:limit], config[:window_ms]) do
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

  # Behind Nginx every request comes from the proxy, so the real client address
  # is taken from X-Real-IP. The public Nginx overwrites this header and the
  # backend port is bound to loopback on the server, so clients cannot spoof it.
  defp client_ip(conn) do
    case get_req_header(conn, "x-real-ip") do
      [ip | _] -> ip
      [] -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end
end
