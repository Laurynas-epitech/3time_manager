defmodule TimeManagerWeb.WorkingTimeController do
  use TimeManagerWeb, :controller

  import Ecto.Query

  alias TimeManager.{Pagination, Repo}
  alias TimeManager.TimeTracking
  alias TimeManager.TimeTracking.WorkingTime
  alias TimeManagerWeb.Authorization

  action_fallback TimeManagerWeb.FallbackController

  @max_working_times 2000

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

    with {:ok, query} <- filter_period(query, params) do
      # Page from the newest working time, then return the page oldest first.
      workingtime =
        from(w in query, order_by: [desc: w.start, desc: w.id])
        |> Pagination.paginate(params, @max_working_times)
        |> Repo.all()
        |> Enum.reverse()

      render(conn, :index, workingtime: workingtime)
    end
  end

  defp filter_period(query, %{"start" => start_time, "end" => end_time}) do
    with {:ok, start_dt} <- parse_datetime(start_time),
         {:ok, end_dt} <- parse_datetime(end_time),
         true <- NaiveDateTime.compare(start_dt, end_dt) in [:lt, :eq] do
      {:ok, from(w in query, where: w.start >= ^start_dt and w.end <= ^end_dt)}
    else
      _ -> {:error, :bad_request}
    end
  end

  defp filter_period(query, params) do
    if Map.has_key?(params, "start") or Map.has_key?(params, "end"),
      do: {:error, :bad_request},
      else: {:ok, query}
  end

  def create(conn, %{"userID" => user_id, "working_time" => working_time_params})
      when is_map(working_time_params) do
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

  def create(_conn, _params), do: {:error, :bad_request}

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

  def update(conn, %{"id" => id, "working_time" => working_time_params})
      when is_map(working_time_params) do
    working_time = TimeTracking.get_working_time!(id)
    # The owner can't be changed through the body.
    working_time_params = Map.delete(working_time_params, "user_id")

    with :ok <- authorize_record(conn, working_time),
         {:ok, %WorkingTime{} = working_time} <-
           TimeTracking.update_working_time(working_time, working_time_params) do
      render(conn, :show, working_time: working_time)
    end
  end

  def update(_conn, _params), do: {:error, :bad_request}

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

  defp parse_datetime(value) when is_binary(value) do
    value
    |> String.replace(" ", "T")
    |> NaiveDateTime.from_iso8601()
  end

  defp parse_datetime(_), do: {:error, :invalid_datetime}
end
