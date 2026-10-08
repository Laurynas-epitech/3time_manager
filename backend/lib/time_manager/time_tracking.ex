defmodule TimeManager.TimeTracking do
  @moduledoc """
  The TimeTracking context.
  """

  import Ecto.Query, warn: false
  alias TimeManager.Repo

  alias TimeManager.TimeTracking.WorkingTime

  @doc """
  Returns the list of workingtime.

  ## Examples

      iex> list_workingtime()
      [%WorkingTime{}, ...]

  """
  def list_workingtime do
    Repo.all(WorkingTime)
  end

  @doc """
  Gets a single working_time.

  Raises `Ecto.NoResultsError` if the Working time does not exist.

  ## Examples

      iex> get_working_time!(123)
      %WorkingTime{}

      iex> get_working_time!(456)
      ** (Ecto.NoResultsError)

  """
  def get_working_time!(id), do: Repo.get!(WorkingTime, id)

  @doc """
  Creates a working_time.

  ## Examples

      iex> create_working_time(%{field: value})
      {:ok, %WorkingTime{}}

      iex> create_working_time(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_working_time(attrs) do
    %WorkingTime{}
    |> WorkingTime.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a working_time.

  ## Examples

      iex> update_working_time(working_time, %{field: new_value})
      {:ok, %WorkingTime{}}

      iex> update_working_time(working_time, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_working_time(%WorkingTime{} = working_time, attrs) do
    working_time
    |> WorkingTime.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a working_time.

  ## Examples

      iex> delete_working_time(working_time)
      {:ok, %WorkingTime{}}

      iex> delete_working_time(working_time)
      {:error, %Ecto.Changeset{}}

  """
  def delete_working_time(%WorkingTime{} = working_time) do
    Repo.delete(working_time)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking working_time changes.

  ## Examples

      iex> change_working_time(working_time)
      %Ecto.Changeset{data: %WorkingTime{}}

  """
  def change_working_time(%WorkingTime{} = working_time, attrs \\ %{}) do
    WorkingTime.changeset(working_time, attrs)
  end

  alias TimeManager.TimeTracking.Clock

  @doc "Records an attendance transition and saves a completed session atomically."
  def record_clock(user_id, attrs) do
    Repo.transaction(fn ->
      # Serialize transitions even when there is no previous clock to lock.
      user =
        Repo.one!(
          from(u in TimeManager.Accounts.User, where: u.id == ^user_id, lock: "FOR UPDATE")
        )

      latest =
        Repo.one(
          from(c in Clock,
            where: c.user_id == ^user.id,
            order_by: [desc: c.time, desc: c.id],
            limit: 1
          )
        )

      changeset = Clock.changeset(%Clock{user_id: user.id}, Map.drop(attrs, ["user_id"]))
      status = Ecto.Changeset.get_field(changeset, :status)
      time = Ecto.Changeset.get_field(changeset, :time)

      changeset =
        if status == (latest && latest.status) or (is_nil(latest) and status == false) do
          Ecto.Changeset.add_error(
            changeset,
            :status,
            "does not change the current attendance status"
          )
        else
          changeset
        end

      changeset =
        if latest && time && DateTime.compare(time, latest.time) == :lt do
          Ecto.Changeset.add_error(changeset, :time, "cannot precede the previous clock")
        else
          changeset
        end

      clock =
        case Repo.insert(changeset) do
          {:ok, clock} -> clock
          {:error, changeset} -> Repo.rollback(changeset)
        end

      if not clock.status do
        %WorkingTime{user_id: user.id}
        |> WorkingTime.changeset(%{start: latest.time, end: clock.time})
        |> Repo.insert()
        |> case do
          {:ok, _working_time} -> :ok
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end

      clock
    end)
  end

  @doc """
  Returns the list of clocks.

  ## Examples

      iex> list_clocks()
      [%Clock{}, ...]

  """
  def list_clocks do
    Repo.all(Clock)
  end

  @doc """
  Gets a single clock.

  Raises `Ecto.NoResultsError` if the Clock does not exist.

  ## Examples

      iex> get_clock!(123)
      %Clock{}

      iex> get_clock!(456)
      ** (Ecto.NoResultsError)

  """
  def get_clock!(id), do: Repo.get!(Clock, id)

  @doc """
  Creates a clock.

  ## Examples

      iex> create_clock(%{field: value})
      {:ok, %Clock{}}

      iex> create_clock(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_clock(attrs) do
    %Clock{}
    |> Clock.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a clock.

  ## Examples

      iex> update_clock(clock, %{field: new_value})
      {:ok, %Clock{}}

      iex> update_clock(clock, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_clock(%Clock{} = clock, attrs) do
    clock
    |> Clock.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a clock.

  ## Examples

      iex> delete_clock(clock)
      {:ok, %Clock{}}

      iex> delete_clock(clock)
      {:error, %Ecto.Changeset{}}

  """
  def delete_clock(%Clock{} = clock) do
    Repo.delete(clock)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking clock changes.

  ## Examples

      iex> change_clock(clock)
      %Ecto.Changeset{data: %Clock{}}

  """
  def change_clock(%Clock{} = clock, attrs \\ %{}) do
    Clock.changeset(clock, attrs)
  end
end
