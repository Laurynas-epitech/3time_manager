alias TimeManager.Repo
unless Repo.config()[:database] == "time_manager_test_remediation", do: raise("Disposable migration verification database only")
snapshot = File.read!("/tmp/required-fields-snapshot") |> :erlang.binary_to_term()
for {table, expected} <- snapshot do
  actual = Repo.query!("SELECT * FROM #{table} ORDER BY id").rows
  if actual != expected, do: raise("Legacy rows changed: #{table}")
end
fields = [{"users", "username"}, {"users", "email"}, {"clocks", "time"}, {"clocks", "status"}, {"clocks", "user_id"}, {"workingtime", "start"}, {"workingtime", "end"}, {"workingtime", "user_id"}]
for {table, field} <- fields do
  [["NO"]] = Repo.query!("SELECT is_nullable FROM information_schema.columns WHERE table_schema='public' AND table_name=$1 AND column_name=$2", [table, field]).rows
  {:error, :expected_null_rejection} = Repo.transaction(fn ->
    {:error, %Postgrex.Error{postgres: %{code: :not_null_violation}}} = Repo.query("UPDATE #{table} SET \"#{field}\"=NULL")
    Repo.rollback(:expected_null_rejection)
  end)
  {:error, :expected_null_rejection} = Repo.transaction(fn ->
    [[user_id]] = Repo.query!("SELECT id FROM users ORDER BY id LIMIT 1").rows
    row = case table do
      "users" -> [{"username", "Null probe"}, {"email", "null-probe@example.invalid"}]
      "clocks" -> [{"time", ~N[2026-10-12 08:00:00]}, {"status", true}, {"user_id", user_id}]
      "workingtime" -> [{"start", ~N[2026-10-12 08:00:00]}, {"end", ~N[2026-10-12 09:00:00]}, {"user_id", user_id}]
    end
    columns = Enum.map_join(row, ",", fn {name, _} -> "\"#{name}\"" end)
    placeholders = Enum.map_join(1..length(row), ",", &"$#{&1}")
    values = Enum.map(row, fn {name, value} -> if name == field, do: nil, else: value end)
    {:error, %Postgrex.Error{postgres: %{code: :not_null_violation}}} = Repo.query("INSERT INTO #{table} (#{columns},inserted_at,updated_at) VALUES (#{placeholders},NOW(),NOW())", values)
    Repo.rollback(:expected_null_rejection)
  end)
end
IO.puts("PASS: legacy values/counts unchanged; eight catalog NOT NULL constraints; eight direct NULL inserts and updates rejected")
