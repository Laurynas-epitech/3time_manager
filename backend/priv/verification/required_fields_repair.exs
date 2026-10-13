alias TimeManager.Repo
unless Repo.config()[:database] == "time_manager_test_remediation", do: raise("Disposable migration verification database only")
[[nil]] = Repo.query!("SELECT username FROM users WHERE email='invalid-legacy@example.invalid'").rows
# Delete only the explicitly manufactured invalid test fixture, never application data.
Repo.query!("DELETE FROM users WHERE email='invalid-legacy@example.invalid'")
IO.puts("PASS: failed preflight preserved invalid fixture; removed only manufactured fixture for upgrade retest")
