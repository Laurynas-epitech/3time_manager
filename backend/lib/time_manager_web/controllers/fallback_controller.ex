defmodule TimeManagerWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use TimeManagerWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: TimeManagerWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :invalid_credentials}) do
    error(conn, :unauthorized, "Invalid email or password")
  end

  def call(conn, {:error, :unauthorized}) do
    error(conn, :unauthorized, "Unauthorized")
  end

  def call(conn, {:error, :forbidden}) do
    error(conn, :forbidden, "Forbidden")
  end

  def call(conn, {:error, :invalid_role}) do
    error(conn, :unprocessable_entity, "Unknown role")
  end

  def call(conn, {:error, :bad_request}) do
    error(conn, :bad_request, "Bad request")
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: TimeManagerWeb.ErrorHTML, json: TimeManagerWeb.ErrorJSON)
    |> render(:"404")
  end

  defp error(conn, status, detail) do
    conn
    |> put_status(status)
    |> json(%{errors: %{detail: detail}})
  end
end
