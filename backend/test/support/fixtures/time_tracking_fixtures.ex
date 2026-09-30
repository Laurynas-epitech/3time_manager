defmodule TimeManager.TimeTrackingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TimeManager.TimeTracking` context.
  """

  @doc """
  Generate a working_time.
  """
  def working_time_fixture(attrs \\ %{}) do
    {:ok, working_time} =
      attrs
      |> Enum.into(%{
        end: ~U[2026-09-21 16:44:00Z],
        start: ~U[2026-09-21 16:44:00Z]
      })
      |> TimeManager.TimeTracking.create_working_time()

    working_time
  end

  @doc """
  Generate a clock.
  """
  def clock_fixture(attrs \\ %{}) do
    {:ok, clock} =
      attrs
      |> Enum.into(%{
        status: true,
        time: ~U[2026-09-21 16:45:00Z]
      })
      |> TimeManager.TimeTracking.create_clock()

    clock
  end
end
