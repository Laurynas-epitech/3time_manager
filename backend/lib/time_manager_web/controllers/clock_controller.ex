defmodule TimeManagerWeb.ClockController do
  use TimeManagerWeb, :controller

  import Ecto.Query

  alias TimeManager.Repo
  alias TimeManager.TimeTracking
  alias TimeManager.TimeTracking.Clock
  alias TimeManagerWeb.Authorization

  action_fallback TimeManagerWeb.FallbackController

  def show(conn, %{"userID" => user_id}) do
    with :ok <- authorize(Authorization.can_view_user?(conn.assigns.current_user, user_id)) do
      clocks =
        from(c in Clock,
          where: c.user_id == ^user_id,
          order_by: [asc: c.time, asc: c.id]
        )
        |> Repo.all()

      render(conn, :index, clocks: clocks)
    end
  end

  def create(conn, %{"userID" => user_id, "clock" => clock_params}) do
    with :ok <- authorize(Authorization.can_clock?(conn.assigns.current_user, user_id)),
         :ok <- authorize(matches_owner?(conn.assigns.current_user, clock_params)),
         {:ok, %Clock{} = clock} <- TimeTracking.record_clock(user_id, clock_params) do
      conn
      |> put_status(:created)
      |> render(:show, clock: clock)
    end
  end

  defp authorize(true), do: :ok
  defp authorize(_), do: {:error, :forbidden}

  defp matches_owner?(user, params) do
    case Map.fetch(params, "client_owner_id") do
      :error -> true
      {:ok, owner_id} -> owner_id == user.id or owner_id == Integer.to_string(user.id)
    end
  end
end
