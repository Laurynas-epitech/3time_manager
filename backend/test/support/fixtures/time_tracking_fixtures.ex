defmodule TimeManager.TimeTrackingFixtures do
  @moduledoc "Test helpers for working times and clocks."

  import TimeManager.AccountsFixtures

  def working_time_fixture(attrs \\ %{}) do
    {:ok, working_time} =
      attrs
      |> Enum.into(%{
        start: ~U[2026-09-21 08:00:00Z],
        end: ~U[2026-09-21 16:00:00Z]
      })
      |> Map.put_new_lazy(:user_id, fn -> user_fixture().id end)
      |> TimeManager.TimeTracking.create_working_time()

    working_time
  end

  def clock_fixture(attrs \\ %{}) do
    {:ok, clock} =
      attrs
      |> Enum.into(%{status: true, time: ~U[2026-09-21 16:45:00Z]})
      |> Map.put_new_lazy(:user_id, fn -> user_fixture().id end)
      |> TimeManager.TimeTracking.create_clock()

    clock
  end
end
