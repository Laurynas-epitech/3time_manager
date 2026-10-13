# Disposable fixture only. Never use the application's deployment database.
alias TimeManager.{Accounts, Repo}
alias TimeManager.Accounts.User
alias TimeManager.Teams.Team
alias TimeManager.TimeTracking.{Clock, WorkingTime}

unless System.get_env("SECURITY_ASSESSMENT_LOCAL") == "true" and
         Repo.config()[:database] == "time_manager_security_assessment" do
  raise "Assessment fixtures require an explicitly opted-in disposable assessment database"
end

unless Repo.aggregate(User, :count) == 0, do: raise("Assessment database must be empty")
password = :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)
samples = for _ <- 1..3 do
  {microseconds, hash} = :timer.tc(fn -> Bcrypt.hash_pwd_salt(password) end)
  {microseconds / 1000, hash}
end
hash = samples |> hd() |> elem(1)
now = DateTime.utc_now() |> DateTime.truncate(:second)
actors = for role <- ["admin", "manager", "employee", "outsider"], into: %{} do
  role_name = if role == "outsider", do: "employee", else: role
  {:ok, user} = Accounts.create_user(%{
    "username" => "Assessment #{role}", "email" => "#{role}@assessment.invalid", "password" => password
  }, role_name)
  {role, %{id: user.id, email: user.email}}
end
employee = actors["employee"].id
manager = actors["manager"].id
employee_role = Accounts.get_role_by_name("employee").id
users = for n <- 1..501 do
  %{username: "Fixture #{n}", email: "fixture-#{n}@assessment.invalid", password_hash: hash,
    role_id: employee_role, inserted_at: now, updated_at: now}
end
{_, inserted} = Repo.insert_all(User, users, returning: [:id])
teams = for n <- 1..201, do: %{name: "Assessment team #{n}", manager_id: manager, inserted_at: now, updated_at: now}
{_, inserted_teams} = Repo.insert_all(Team, teams, returning: [:id])
team_id = hd(inserted_teams).id
members = [%{team_id: team_id, user_id: employee}] ++
  Enum.map(Enum.take(inserted, 150), &%{team_id: team_id, user_id: &1.id})
Repo.insert_all("team_users", members)
base = ~U[2025-01-01 08:00:00Z]
sessions = for n <- 1..2001 do
  start = DateTime.add(base, n * 120)
  %{user_id: employee, start: start, end: DateTime.add(start, 60), inserted_at: now, updated_at: now}
end
Repo.insert_all(WorkingTime, sessions)
clocks = for n <- 1..2001 do
  %{user_id: employee, time: DateTime.add(base, n * 60), status: rem(n, 2) == 1,
    inserted_at: now, updated_at: now}
end
Repo.insert_all(Clock, clocks)
output = System.fetch_env!("SECURITY_ASSESSMENT_OUTPUT")
File.write!(Path.join(output, "fixtures.json"), Jason.encode!(%{
  password: password, actors: actors, team_id: team_id,
  bcrypt_cost: String.split(hash, "$") |> Enum.at(2),
  hash_ms: Enum.map(samples, &elem(&1, 0)),
  counts: %{users: 505, teams: 201, members: 151, sessions: 2001, clocks: 2001}
}))
IO.puts("Seeded isolated assessment fixtures; credentials written only to private output file.")
