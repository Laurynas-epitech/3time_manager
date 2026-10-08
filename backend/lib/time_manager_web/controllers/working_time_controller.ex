defmodule TimeManagerWeb.WorkingTimeController do
  use TimeManagerWeb, :controller

  import Ecto.Query

  alias TimeManager.Repo
  alias TimeManager.TimeTracking
  alias TimeManager.TimeTracking.WorkingTime
  alias TimeManagerWeb.Authorization

  action_fallback TimeManagerWeb.FallbackController

  def index(conn, %{"userID" => user_id} = params) do
    if Authorization.can_view_user?(conn.assigns.current_user, user_id) do
      do_index(conn, user_id, params)
    else
      {:error, :forbidden}
    end
  end

  defp do_index(conn, user_id, params) do
    query =
      from w in WorkingTime,
        where: w.user_id == ^user_id

    query =
      case params do
        %{"start" => start_time, "end" => end_time} ->
          with {:ok, start_dt} <- parse_datetime(start_time),
               {:ok, end_dt} <- parse_datetime(end_time) do
            from w in query,
              where: w.start >= ^start_dt and w.end <= ^end_dt
          else
            _ -> query
          end

        _ ->
          query
      end

    workingtime = Repo.all(query)

    render(conn, :index, workingtime: workingtime)
  end

  def create(conn, %{"userID" => user_id, "working_time" => working_time_params}) do
    working_time_params =
      Map.put(working_time_params, "user_id", user_id)

    with :ok <-
           authorize(Authorization.can_manage_working_times?(conn.assigns.current_user, user_id)),
         {:ok, %WorkingTime{} = working_time} <-
           TimeTracking.create_working_time(working_time_params) do
      conn
      |> put_status(:created)
      |> render(:show, working_time: working_time)
    end
  end

  def show(conn, %{"userID" => user_id, "id" => id}) do
    with :ok <- authorize(Authorization.can_view_user?(conn.assigns.current_user, user_id)) do
      working_time =
        Repo.get_by!(WorkingTime,
          id: id,
          user_id: user_id
        )

      render(conn, :show, working_time: working_time)
    end
  end

  def update(conn, %{"id" => id, "working_time" => working_time_params}) do
    working_time = TimeTracking.get_working_time!(id)
    # The owner can't be changed through the body.
    working_time_params = Map.delete(working_time_params, "user_id")

    with :ok <- authorize_record(conn, working_time),
         {:ok, %WorkingTime{} = working_time} <-
           TimeTracking.update_working_time(working_time, working_time_params) do
      render(conn, :show, working_time: working_time)
    end
  end

  def delete(conn, %{"id" => id}) do
    working_time = TimeTracking.get_working_time!(id)

    with :ok <- authorize_record(conn, working_time),
         {:ok, %WorkingTime{}} <-
           TimeTracking.delete_working_time(working_time) do
      send_resp(conn, :no_content, "")
    end
  end

  defp authorize_record(conn, %WorkingTime{user_id: owner_id}) do
    authorize(Authorization.can_manage_working_times?(conn.assigns.current_user, owner_id))
  end

  defp authorize(true), do: :ok
  defp authorize(_), do: {:error, :forbidden}

  defp parse_datetime(value) do
    value
    |> String.replace(" ", "T")
    |> NaiveDateTime.from_iso8601()
  end
end
