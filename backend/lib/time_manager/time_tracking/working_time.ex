defmodule TimeManager.TimeTracking.WorkingTime do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workingtime" do
    field :start, :utc_datetime
    field :end, :utc_datetime

    belongs_to :user, TimeManager.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(working_time, attrs, opts \\ []) do
    working_time
    |> cast(attrs, [:start, :end, :user_id])
    |> validate_required([:start, :end, :user_id])
    |> validate_interval(Keyword.get(opts, :allow_zero, false))
  end

  defp validate_interval(changeset, allow_zero) do
    start = get_field(changeset, :start)
    finish = get_field(changeset, :end)

    if start && finish &&
         (DateTime.compare(finish, start) == :lt or
            (not allow_zero and DateTime.compare(finish, start) == :eq)) do
      add_error(changeset, :end, "must be later than start")
    else
      changeset
    end
  end
end
