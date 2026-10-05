defmodule TimeManagerWeb.Plugs.RequireRole do
  @moduledoc """
  Restricts a pipeline/route to some roles:

      plug TimeManagerWeb.Plugs.RequireRole, ["admin"]
  """
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias TimeManager.Accounts

  def init(roles) when is_list(roles), do: roles

  def call(conn, roles) do
    if Accounts.role_name(conn.assigns[:current_user]) in roles do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(%{errors: %{detail: "Forbidden"}})
      |> halt()
    end
  end
end
