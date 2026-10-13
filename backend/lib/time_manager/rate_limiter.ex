defmodule TimeManager.RateLimiter do
  @moduledoc """
  Small in-memory fixed-window rate limiter (no extra dependency).

  Hits are counted per `{key, window}` in an ETS table owned by this process.
  A periodic sweep removes finished windows. Counters live in memory only,
  so they reset when the backend restarts.
  """
  use GenServer

  @table __MODULE__
  @sweep_interval :timer.minutes(5)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc """
  Records one hit for `key`.

  Returns `:ok` while the key made at most `limit` hits in the current window,
  otherwise `{:error, retry_after_seconds}`.
  """
  def hit(key, limit, window_ms) do
    now = System.system_time(:millisecond)
    window = div(now, window_ms)
    window_end = (window + 1) * window_ms

    count = :ets.update_counter(@table, {key, window}, {2, 1}, {{key, window}, 0, window_end})

    if count <= limit do
      :ok
    else
      {:error, max(div(window_end - now + 999, 1000), 1)}
    end
  end

  @impl true
  def init(nil) do
    :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
    schedule_sweep()
    {:ok, nil}
  end

  @impl true
  def handle_info(:sweep, state) do
    now = System.system_time(:millisecond)
    # Rows are {{key, window}, count, window_end}; drop the finished windows.
    :ets.select_delete(@table, [{{:_, :_, :"$1"}, [{:<, :"$1", now}], [true]}])
    schedule_sweep()
    {:noreply, state}
  end

  defp schedule_sweep, do: Process.send_after(self(), :sweep, @sweep_interval)
end
