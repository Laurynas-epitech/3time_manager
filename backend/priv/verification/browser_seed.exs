unless System.get_env("REMEDIATION_LOCAL") == "true" and TimeManager.Repo.config()[:database] == "time_manager_dev" and TimeManager.Repo.config()[:hostname] == "db", do: raise("Use the isolated local verification container only")
alias TimeManager.{Accounts, Teams, TimeTracking}
password = :crypto.strong_rand_bytes(20) |> Base.encode16()
users = for {label, role} <- [{"admin", "admin"}, {"manager", "manager"}, {"one", "employee"}, {"two", "employee"}, {"zero", "employee"}, {"outsider", "employee"}], into: %{} do
  {:ok, user} = Accounts.create_user(%{username: "Fixture #{label}", email: "remediation-#{label}@example.invalid", password: password}, role)
  {label, %{id: user.id, email: user.email}}
end
{:ok, team} = Teams.create_team(%{name: "Fixed report team", manager_id: users["manager"].id})
for label <- ["one", "two", "zero"], do: Teams.add_member(team, Accounts.get_user(users[label].id))
{:ok, empty} = Teams.create_team(%{name: "Empty report team", manager_id: users["manager"].id})
records = for {label, first, last} <- [
  {"one", ~U[2026-10-12 08:00:00Z], ~U[2026-10-12 16:00:00Z]},
  {"two", ~U[2026-10-12 08:00:00Z], ~U[2026-10-12 12:00:00Z]},
  {"one", ~U[2026-10-13 08:00:00Z], ~U[2026-10-13 14:00:00Z]}
] do
  {:ok, record} = TimeTracking.create_working_time(%{user_id: users[label].id, start: first, end: last})
  record.id
end
File.write!("/tmp/remediation-fixtures.json", Jason.encode!(%{users: users, password: password, team_id: team.id, empty_team_id: empty.id, record_id: hd(records)}))
IO.puts("Disposable report/browser fixtures created; credentials not logged")
