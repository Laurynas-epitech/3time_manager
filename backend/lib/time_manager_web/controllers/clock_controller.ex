defmodule TimeManagerWeb.ClockController do
  use TimeManagerWeb, :controller

  import Ecto.Query

  alias TimeManager.Repo
  alias TimeManager.TimeTracking
  alias TimeManager.TimeTracking.Clock

  action_fallback TimeManagerWeb.FallbackController

  def show(conn, %{"userID" => user_id}) do
    clocks =
      from(c in Clock,
        where: c.user_id == ^user_id,
        order_by: [asc: c.time]
      )
      |> Repo.all()

    render(conn, :index, clocks: clocks)
  end

  def create(conn, %{"userID" => user_id, "clock" => clock_params}) do
    clock_params =
      Map.put(clock_params, "user_id", user_id)

    with {:ok, %Clock{} = clock} <-
           TimeTracking.create_clock(clock_params) do
      conn
      |> put_status(:created)
      |> render(:show, clock: clock)
    end
  end
end
