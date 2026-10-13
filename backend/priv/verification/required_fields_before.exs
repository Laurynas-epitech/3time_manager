alias TimeManager.Repo
unless Repo.config()[:database] == "time_manager_test_remediation", do: raise("Disposable migration verification database only")
alias TimeManager.Accounts
{:ok, user} = Accounts.create_user(%{username: "Legacy valid", email: "legacy-remediation@example.invalid", password: "Verification-only-123"})
{:ok, _} = TimeManager.TimeTracking.create_working_time(%{user_id: user.id, start: ~U[2026-10-12 23:00:00Z], end: ~U[2026-10-13 01:00:00Z]})
{:ok, _} = TimeManager.TimeTracking.create_clock(%{user_id: user.id, time: ~U[2026-10-12 23:00:00Z], status: true})
snapshot = Enum.map(["users", "clocks", "workingtime"], fn table -> {table, Repo.query!("SELECT * FROM #{table} ORDER BY id").rows} end)
File.write!("/tmp/required-fields-snapshot", :erlang.term_to_binary(snapshot))
Repo.query!("INSERT INTO users (email, inserted_at, updated_at) VALUES ('invalid-legacy@example.invalid', NOW(), NOW())")
IO.puts("PASS: valid legacy fixtures retained; intentionally invalid legacy NULL username inserted")
