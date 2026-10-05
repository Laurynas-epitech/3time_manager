defmodule TimeManagerWeb.RoleController do
  @moduledoc "Roles are predefined: read-only."
  use TimeManagerWeb, :controller

  alias TimeManager.Accounts

  def index(conn, _params) do
    roles = for r <- Accounts.list_roles(), do: %{id: r.id, name: r.name}
    json(conn, %{data: roles})
  end
end
