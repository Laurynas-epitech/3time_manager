defmodule TimeManager.TeamReport do
  @moduledoc "Completed recorded hours, summed (including overlaps), per current distinct member."
  alias TimeManager.Repo

  def build(team_id, params) do
    with {:ok, first} <- date(params["start"]),
         {:ok, last} <- date(params["end"]),
         days when days in 1..366 <- Date.diff(last, first) + 1,
         zone when is_binary(zone) and byte_size(zone) <= 100 <- params["timezone"] || "UTC",
         %{rows: [[true]]} <- Repo.query!("SELECT EXISTS(SELECT 1 FROM pg_timezone_names WHERE name = $1)", [zone]) do
      result = Repo.query!("""
      WITH members AS (SELECT DISTINCT user_id FROM team_users WHERE team_id = $1),
      days AS (SELECT $2::date + n AS day FROM generate_series(0, $3::date - $2::date) n),
      bounds AS (SELECT day, day::timestamp AT TIME ZONE $4 AS first,
                 (day + 1)::timestamp AT TIME ZONE $4 AS last FROM days)
      SELECT b.day, (SELECT count(*) FROM members),
             COALESCE(sum(EXTRACT(epoch FROM
               LEAST(w."end" AT TIME ZONE 'UTC', b.last) -
               GREATEST(w.start AT TIME ZONE 'UTC', b.first)) / 3600.0), 0)::float8
      FROM bounds b LEFT JOIN workingtime w ON
        w.user_id IN (SELECT user_id FROM members) AND
        w.start AT TIME ZONE 'UTC' < b.last AND w."end" AT TIME ZONE 'UTC' > b.first
        AND w."end" > w.start
      GROUP BY b.day ORDER BY b.day
      """, [team_id, first, last, zone])

      daily = Enum.map(result.rows, fn [day, count, total] ->
        %{date: Date.to_iso8601(day), total_hours: total, average_hours: average(total, count)}
      end)

      [[_, count, _] | _] = result.rows
      weekly = result.rows
      |> Enum.chunk_by(fn [day, _, _] -> Date.beginning_of_week(day) end)
      |> Enum.map(fn rows ->
        [begin_date, _, _] = hd(rows)
        [end_date, _, _] = List.last(rows)
        total = Enum.reduce(rows, 0.0, fn [_, _, hours], sum -> sum + hours end)
        %{start: Date.to_iso8601(begin_date), end: Date.to_iso8601(end_date),
          partial: length(rows) != 7, total_hours: total, average_hours: average(total, count)}
      end)

      {:ok, %{team_id: team_id, member_count: count, timezone: zone,
              start: first, end: last, daily: daily, weekly: weekly}}
    else
      _ -> {:error, :bad_request}
    end
  end

  defp date(value) when is_binary(value), do: Date.from_iso8601(value)
  defp date(_), do: {:error, :invalid_date}
  defp average(_, 0), do: nil
  defp average(total, count), do: total / count
end
